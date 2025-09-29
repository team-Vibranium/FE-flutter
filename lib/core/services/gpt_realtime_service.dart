import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';

/// 알람 타입 enum
enum AlarmType {
  phoneCall,    // 전화 알람 (GPT Realtime API 사용)
  regular,      // 일반 알람 (기본 알람)
}

/// SessionResponse 모델 (Swagger API 스펙)
class SessionResponse {
  final String ephemeralKey;
  final String sessionId;
  final int expiresInSeconds;

  SessionResponse({
    required this.ephemeralKey,
    required this.sessionId,
    required this.expiresInSeconds,
  });

  factory SessionResponse.fromJson(Map<String, dynamic> json) {
    return SessionResponse(
      ephemeralKey: json['ephemeralKey'] as String,
      sessionId: json['sessionId'] as String,
      expiresInSeconds: json['expiresInSeconds'] as int,
    );
  }
}

/// GPT Realtime API를 활용한 양방향 음성 대화 서비스
class GPTRealtimeService {
  static final GPTRealtimeService _instance = GPTRealtimeService._internal();
  factory GPTRealtimeService() => _instance;
  GPTRealtimeService._internal();

  // WebRTC 관련
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  
  
  // 상태
  bool _isConnected = false;
  bool _isCallActive = false;
  String? _sessionId;
  String? _ephemeralKey;
  AlarmType? _currentAlarmType;
  int? _currentAlarmId;
  int? _currentCallId;
  int _snoozeCount = 0;
  int _maxSnoozeCount = 3;
  String? _originalInstructions; // 원래 알람 지시사항 저장
  
  
  // 콜백
  Function(String)? onError;
  Function()? onCallStarted;
  Function()? onCallEnded;
  Function(MediaStream)? onRemoteStream;
  Function(int, int)? onSnoozeRequested; // alarmId, snoozeMinutes

  // Dio (백엔드 통신)
  late Dio _dio;

  /// 서비스 초기화
  Future<void> initialize(String apiKey) async {
    _dio = Dio();
    _dio.options.baseUrl = 'https://prod.proproject.my';
    _dio.options.headers = {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    };

    // 마이크 권한 요청
    final mic = await Permission.microphone.request();
    if (mic != PermissionStatus.granted) {
      throw Exception('마이크 권한이 필요합니다');
    }
    print('✅ 마이크 권한 승인됨');
  }



  /// 전화 알람 시작 (alarmId 기반)
  Future<void> startMorningCall({required int alarmId}) async {
    try {
      print('🌅 전화 알람 시작 (alarmId=$alarmId)');

      // 전화 알람으로 설정
      _currentAlarmType = AlarmType.phoneCall;
      _currentAlarmId = alarmId;
      _snoozeCount = 0;

      // 1. 원래 알람 정보 조회 및 저장
      await _loadOriginalAlarmInfo(alarmId);

      // 2. WebRTC 초기화
      await _initializeWebRTC();

      // 2. 백엔드에서 ephemeral key 요청
      final session = await _getEphemeralKey(alarmId: alarmId);
      _ephemeralKey = session.ephemeralKey;
      _sessionId = session.sessionId;

      // 3. Offer/Answer 교환
      await _connectToGPTViaWebRTC(_ephemeralKey!);

      // 4. 통화 시작 API 호출
      await _startCall();

      _isConnected = true;
      _isCallActive = true;
      onCallStarted?.call();

      print('✅ 전화 알람 연결 성공: $_sessionId');
    } catch (e, st) {
      print('❌ 전화 알람 시작 오류: $e');
      onError?.call('전화 알람 시작 실패: $e');
      debugPrintStack(label: 'startMorningCall', stackTrace: st);
    }
  }

  /// 일반 알람 시작 (스누즈 불가)
  Future<void> startRegularAlarm({required int alarmId}) async {
    try {
      print('🔔 일반 알람 시작 (alarmId=$alarmId)');

      // 일반 알람으로 설정
      _currentAlarmType = AlarmType.regular;

      // 일반 알람은 WebRTC 없이 단순 알림만
      _isCallActive = true;
      onCallStarted?.call();

      print('✅ 일반 알람 시작 성공');
    } catch (e, st) {
      print('❌ 일반 알람 시작 오류: $e');
      onError?.call('일반 알람 시작 실패: $e');
      debugPrintStack(label: 'startRegularAlarm', stackTrace: st);
    }
  }



  /// 통화 시작 API 호출
  Future<void> _startCall() async {
    try {
      if (_sessionId == null) {
        throw Exception('세션 ID가 없습니다');
      }
      
      print('📞 통화 시작 API 호출: $_sessionId');
      
      final response = await _dio.post(
        '/api/calls/start',
        data: {
          'sessionId': _sessionId,
        },
      );
      
      if (response.statusCode == 201) {
        final callData = response.data['data'] as Map<String, dynamic>;
        _currentCallId = callData['callId'] as int;
        print('✅ 통화 시작 성공: Call ID $_currentCallId');
      } else {
        throw Exception('통화 시작 실패: ${response.statusCode}');
      }
      
    } catch (e) {
      print('❌ 통화 시작 API 오류: $e');
      throw Exception('통화 시작 실패: $e');
    }
  }

  /// 통화 종료 API 호출
  Future<void> _endCall(String result, int snoozeCount) async {
    try {
      if (_currentCallId == null) {
        print('⚠️ Call ID가 없어서 통화 종료 API 호출 건너뜀');
        return;
      }
      
      print('📞 통화 종료 API 호출: Call ID $_currentCallId, Result: $result');
      
      final response = await _dio.post(
        '/api/calls/$_currentCallId/end',
        data: {
          'callEnd': DateTime.now().toIso8601String(),
          'result': result,
          'snoozeCount': snoozeCount,
        },
      );
      
      if (response.statusCode == 200) {
        print('✅ 통화 종료 성공');
      } else {
        print('⚠️ 통화 종료 API 실패: ${response.statusCode}');
      }
      
    } catch (e) {
      print('❌ 통화 종료 API 오류: $e');
    }
  }

  /// 전화 알람 종료 (성공)
  Future<void> endMorningCall() async {
    try {
      print('📞 전화 알람 종료 (성공)');
      
      // 통화 종료 API 호출
      await _endCall('SUCCESS', _snoozeCount);
      
      // 원래 알람 지시사항으로 복구
      if (_currentAlarmId != null) {
        await _restoreOriginalInstructions(_currentAlarmId!);
      }
      
      _isCallActive = false;

      await _peerConnection?.close();
      _peerConnection = null;

      await _localStream?.dispose();
      _localStream = null;

      await _remoteStream?.dispose();
      _remoteStream = null;

      _isConnected = false;
      _sessionId = null;
      _ephemeralKey = null;
      _currentAlarmType = null;
      _currentCallId = null;
      _originalInstructions = null;

      onCallEnded?.call();
    } catch (e) {
      print('❌ 전화 알람 종료 오류: $e');
    }
  }

  /// 전화 알람 실패 종료 (스누즈 한계 도달)
  Future<void> endMorningCallWithFailure() async {
    try {
      print('📞 전화 알람 종료 (실패)');
      
      // 통화 종료 API 호출
      await _endCall('FAIL_SNOOZE', _snoozeCount);
      
      // 원래 알람 지시사항으로 복구
      if (_currentAlarmId != null) {
        await _restoreOriginalInstructions(_currentAlarmId!);
      }
      
      _isCallActive = false;

      await _cleanupWebRTC();
      _originalInstructions = null;

      onCallEnded?.call();
    } catch (e) {
      print('❌ 전화 알람 실패 종료 오류: $e');
    }
  }

  /// 일반 알람 종료
  Future<void> endRegularAlarm() async {
    try {
      print('🔔 일반 알람 종료');
      _isCallActive = false;
      _currentAlarmType = null;

      onCallEnded?.call();
    } catch (e) {
      print('❌ 일반 알람 종료 오류: $e');
    }
  }

  /// WebRTC 초기화
  Future<void> _initializeWebRTC() async {
    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'}
      ]
    };

    _peerConnection = await createPeerConnection(config);

    // 로컬 오디오 트랙
    final constraints = {
      'audio': {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
        'sampleRate': 24000,
        'channelCount': 1,
      },
      'video': false,
    };
    _localStream = await navigator.mediaDevices.getUserMedia(constraints);
    _localStream!.getTracks().forEach((t) {
      _peerConnection!.addTrack(t, _localStream!);
    });

    // 원격 스트림
    _peerConnection!.onAddStream = (stream) {
      _remoteStream = stream;
      onRemoteStream?.call(stream);
      print('🔊 원격 오디오 스트림 수신');
    };

    print('🎧 WebRTC 초기화 완료');
  }


  /// WebRTC를 통한 GPT 연결
  Future<void> _connectToGPTViaWebRTC(String ephemeralKey) async {
    if (_peerConnection == null) return;

    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    final dio = Dio();
    dio.options.headers = {
      'Authorization': 'Bearer $ephemeralKey',
      'Content-Type': 'application/sdp',
    };

    final res = await dio.post(
      'https://api.openai.com/v1/realtime?model=gpt-4o-realtime-preview-2024-10-01',
      data: offer.sdp,
    );

    if (res.statusCode == 200) {
      final answer = RTCSessionDescription(res.data, 'answer');
      await _peerConnection!.setRemoteDescription(answer);
      print('✅ Answer 적용 완료');
      
      // WebRTC 데이터 채널을 통한 실시간 메시지 처리 시작
      _setupRealtimeMessageHandling();
    } else {
      throw Exception('Offer 전송 실패: ${res.statusCode}');
    }
  }

  /// 실시간 메시지 처리 설정
  void _setupRealtimeMessageHandling() {
    // WebRTC 데이터 채널을 통한 실시간 메시지 처리
    // 실제 구현에서는 WebRTC 데이터 채널을 통해 GPT Realtime API 메시지를 받아야 함
    print('📡 실시간 메시지 처리 설정 완료');
  }

  /// 음성에서 스누즈 키워드 감지 및 처리
  Future<void> _handleVoiceSnooze(String voiceText) async {
    if (_currentAlarmId == null || _snoozeCount >= _maxSnoozeCount) {
      return;
    }

    // 스누즈 관련 키워드 감지
    final snoozeKeywords = [
      '스누즈', '다시', '깨워', '5분', '나중에', '잠깐', '조금 더',
      '있다가', '더 자', '더 잘래', '10분', '15분', '몇 분',
      '잠시만', '좀 더', '아직', '피곤해', '졸려', '더 쉴게',
      '있다 일어날래', '있다 일어날게', '잠깐만', '조금만 더'
    ];

    final lowerText = voiceText.toLowerCase().replaceAll(' ', '');
    final hasSnoozeKeyword = snoozeKeywords.any((keyword) =>
      lowerText.contains(keyword.toLowerCase().replaceAll(' ', '')));

    if (!hasSnoozeKeyword) {
      return;
    }

    print('🎤 스누즈 키워드 감지됨: "$voiceText"');

    try {
      // 스누즈 시간 추출 (기본 5분)
      int snoozeMinutes = _extractSnoozeMinutes(voiceText);
      
      // 스누즈 처리
      await handlePhoneCallSnooze(
        alarmId: _currentAlarmId!,
        snoozeMinutes: snoozeMinutes,
      );

      _snoozeCount++;
      print('✅ 음성 스누즈 처리 완료: ${_snoozeCount}/${_maxSnoozeCount}');

    } catch (e) {
      print('❌ 음성 스누즈 처리 오류: $e');
      onError?.call('스누즈 처리 실패: $e');
    }
  }

  /// 음성에서 스누즈 시간 추출
  int _extractSnoozeMinutes(String voiceText) {
    final lowerText = voiceText.toLowerCase();
    
    // 숫자 패턴 매칭
    final numberPattern = RegExp(r'(\d+)\s*분');
    final match = numberPattern.firstMatch(lowerText);
    
    if (match != null) {
      final minutes = int.tryParse(match.group(1) ?? '');
      if (minutes != null && minutes > 0 && minutes <= 60) {
        return minutes;
      }
    }
    
    // 키워드 기반 추정
    if (lowerText.contains('10분') || lowerText.contains('십분')) return 10;
    if (lowerText.contains('15분') || lowerText.contains('십오분')) return 15;
    if (lowerText.contains('20분') || lowerText.contains('이십분')) return 20;
    if (lowerText.contains('30분') || lowerText.contains('삼십분')) return 30;
    
    // 기본값 5분
    return 5;
  }

  /// 서버에서 ephemeral key 받기
  Future<SessionResponse> _getEphemeralKey({int? alarmId, int snoozeCount = 0}) async {
    final res = await _dio.post(
      '/api/realtime/session',
      queryParameters: {
        if (alarmId != null) 'alarmId': alarmId,
        'snoozeCount': snoozeCount,
      },
    );

    if (res.statusCode == 201) {
      final data = res.data['data'] as Map<String, dynamic>;
      return SessionResponse.fromJson(data);
    } else {
      throw Exception('Ephemeral key 요청 실패: ${res.statusCode}');
    }
  }











  /// 전화 알람 스누즈 처리 (임시로 더 자기)
  Future<void> handlePhoneCallSnooze({
    required int alarmId,
    int snoozeMinutes = 5,
  }) async {
    try {
      // 전화 알람인지 확인
      if (_currentAlarmType != AlarmType.phoneCall) {
        throw Exception('전화 알람에서만 전화 알람 스누즈가 가능합니다');
      }

      // 스누즈 한계 확인
      if (_snoozeCount >= _maxSnoozeCount) {
        print('❌ 스누즈 한계 도달: ${_snoozeCount}/${_maxSnoozeCount}');
        onError?.call('스누즈 한계에 도달했습니다. 알람이 실패로 처리됩니다.');
        await endMorningCallWithFailure();
        return;
      }

      print('😴 전화 알람 스누즈 요청: ${snoozeMinutes}분 (${_snoozeCount + 1}/${_maxSnoozeCount})');
      
      // 1. 현재 통화를 FAIL_SNOOZE로 종료
      await _endCall('FAIL_SNOOZE', _snoozeCount + 1);
      
      // 2. WebRTC 연결 종료
      await _cleanupWebRTC();
      
      // 3. 스누즈 카운트 증가
      _snoozeCount++;
      
      // 4. 알람 지시사항에 스누즈 정보 추가
      final snoozeInstructions = '${_originalInstructions ?? "부드럽게 깨워주세요"} (스누즈 ${_snoozeCount}회)';
      await _updateAlarmInstructions(alarmId, snoozeInstructions);
      
      // 5. 스누즈 시간만큼 대기 후 다시 알람 시작
      _scheduleSnoozeRestart(alarmId, snoozeMinutes);

      print('✅ 전화 알람 스누즈 처리 완료 - ${snoozeMinutes}분 후 다시 시작');
      onSnoozeRequested?.call(alarmId, snoozeMinutes);
      
    } catch (e) {
      print('❌ 전화 알람 스누즈 처리 오류: $e');
      onError?.call('전화 알람 스누즈 실패: $e');
    }
  }

  /// 원래 알람 정보 로드
  Future<void> _loadOriginalAlarmInfo(int alarmId) async {
    try {
      final response = await _dio.get('/api/alarms/$alarmId');
      if (response.statusCode == 200) {
        final alarmData = response.data['data'] as Map<String, dynamic>;
        _originalInstructions = alarmData['instructions'] as String;
        print('✅ 원래 알람 정보 로드: $_originalInstructions');
      } else {
        print('⚠️ 알람 정보 로드 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 알람 정보 로드 오류: $e');
    }
  }

  /// 알람 지시사항 업데이트 (스누즈 정보 포함)
  Future<void> _updateAlarmInstructions(int alarmId, String instructions) async {
    try {
      // 먼저 현재 알람 정보를 가져와서 기존 값들 유지
      final getResponse = await _dio.get('/api/alarms/$alarmId');
      if (getResponse.statusCode != 200) {
        print('⚠️ 알람 정보 조회 실패: ${getResponse.statusCode}');
        return;
      }
      
      final alarmData = getResponse.data['data'] as Map<String, dynamic>;
      
      final response = await _dio.put(
        '/api/alarms/$alarmId',
        data: {
          'alarmTime': alarmData['alarmTime'], // 기존 시간 유지
          'instructions': instructions, // 지시사항만 변경
          'voice': alarmData['voice'], // 기존 음성 유지
        },
      );
      
      if (response.statusCode == 200) {
        print('✅ 알람 지시사항 업데이트: $instructions');
      } else {
        print('⚠️ 알람 지시사항 업데이트 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 알람 지시사항 업데이트 오류: $e');
    }
  }

  /// 원래 알람 지시사항으로 복구
  Future<void> _restoreOriginalInstructions(int alarmId) async {
    if (_originalInstructions != null) {
      await _updateAlarmInstructions(alarmId, _originalInstructions!);
      print('✅ 원래 알람 지시사항으로 복구');
    }
  }

  /// 스누즈 후 알람 재시작 스케줄링
  void _scheduleSnoozeRestart(int alarmId, int snoozeMinutes) {
    Timer(Duration(minutes: snoozeMinutes), () {
      print('⏰ 스누즈 시간 완료 - 알람 재시작');
      startMorningCall(alarmId: alarmId);
    });
  }

  /// WebRTC 연결 정리
  Future<void> _cleanupWebRTC() async {
    await _peerConnection?.close();
    _peerConnection = null;

    await _localStream?.dispose();
    _localStream = null;

    await _remoteStream?.dispose();
    _remoteStream = null;

    _isConnected = false;
    _sessionId = null;
    _ephemeralKey = null;
    _currentCallId = null;
  }


  /// 일반 알람 스누즈 처리 (임시로 더 자기)
  Future<void> handleRegularAlarmSnooze({
    required int alarmId,
    int snoozeMinutes = 5,
  }) async {
    try {
      // 일반 알람인지 확인
      if (_currentAlarmType != AlarmType.regular) {
        throw Exception('일반 알람에서만 일반 알람 스누즈가 가능합니다');
      }

      print('😴 일반 알람 스누즈 요청: ${snoozeMinutes}분');
      await endRegularAlarm();

      // 스누즈 시간만큼 대기 후 다시 알람 시작
      _scheduleSnoozeRestart(alarmId, snoozeMinutes);

      print('✅ 일반 알람 스누즈 처리 완료 - ${snoozeMinutes}분 후 다시 시작');
      onSnoozeRequested?.call(alarmId, snoozeMinutes);
      
    } catch (e) {
      print('❌ 일반 알람 스누즈 처리 오류: $e');
      onError?.call('일반 알람 스누즈 실패: $e');
    }
  }


  /// 현재 통화 상태
  bool get isCallActive => _isCallActive;
  
  /// 현재 연결 상태
  bool get isConnected => _isConnected;
  
  /// 세션 ID
  String? get sessionId => _sessionId;
  
  /// 현재 알람 타입
  AlarmType? get currentAlarmType => _currentAlarmType;
  
  /// 전화 알람 스누즈 가능 여부
  bool get canPhoneCallSnooze => _currentAlarmType == AlarmType.phoneCall;
  
  /// 일반 알람 스누즈 가능 여부
  bool get canRegularAlarmSnooze => _currentAlarmType == AlarmType.regular;

  /// 음성 텍스트 처리 (외부에서 호출)
  Future<void> processVoiceText(String voiceText) async {
    if (_currentAlarmType == AlarmType.phoneCall) {
      await _handleVoiceSnooze(voiceText);
    }
  }

  /// 대화 내용 저장
  Future<void> saveConversation(List<Map<String, dynamic>> conversation) async {
    try {
      if (_currentCallId == null) {
        print('⚠️ Call ID가 없어서 대화 내용 저장 건너뜀');
        return;
      }

      print('💬 대화 내용 저장: Call ID $_currentCallId');
      
      final response = await _dio.post(
        '/api/calls/$_currentCallId/transcript',
        data: {
          'conversation': conversation,
        },
      );
      
      if (response.statusCode == 200) {
        print('✅ 대화 내용 저장 성공');
      } else {
        print('⚠️ 대화 내용 저장 실패: ${response.statusCode}');
      }
      
    } catch (e) {
      print('❌ 대화 내용 저장 오류: $e');
    }
  }

  /// 서비스 정리
  void dispose() {
    endMorningCall();
  }
}

