import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import 'base_api_service.dart';
import '../../main.dart' show navigateToAlarmScreen;
import '../models/api_models.dart' show Utterance, TranscriptRequest, CallStartRequest, CallEndRequest;
import 'call_management_api_service.dart';
import 'call_log_api_service.dart';

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
  RTCDataChannel? _dataChannel;
  bool _remoteStreamHandled = false; // 원격 스트림 중복 처리 방지

  // HTTP 클라이언트
  late Dio _dio;
  
  
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
  bool _userHasSpokenInSession = false; // 현재 세션에서 사용자가 발화했는지 여부
  Timer? _ephemeralRefreshTimer;
  
  
  // 콜백
  Function(String)? onError;
  Function()? onCallStarted;
  Function()? onCallEnded;
  Function(MediaStream)? onRemoteStream;
  Function(int, int)? onSnoozeRequested; // alarmId, snoozeMinutes
  Function()? onUserSpeechDetected; // 사용자 발화 감지
  Function()? onGPTResponseCompleted; // GPT 응답 완료 (사용자 발화 후)
  // 확정된 발화 단위 콜백 (speaker: user/assistant)
  Function(String speaker, String text)? onTranscript;

  // 재연결 제어
  bool _isReconnecting = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 3;

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

      // Dio 초기화 (인증 토큰 포함)
      _dio = Dio();
      _dio.options.baseUrl = 'https://prod.proproject.my';
      
      // 인증 토큰 가져오기
      final token = _getAuthToken();
      _dio.options.headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      print('✅ Dio 초기화 완료 (토큰: ${token != null ? "있음 (${token.substring(0, 20)}...)" : "없음"})');

      // 전화 알람으로 설정
      _currentAlarmType = AlarmType.phoneCall;
      _currentAlarmId = alarmId;
      _snoozeCount = 0;

      // 1. 원래 알람 정보 조회 및 저장 (없으면 생성하고 실제 ID 반환)
      final actualAlarmId = await _loadOriginalAlarmInfo(alarmId);
      _currentAlarmId = actualAlarmId; // 실제 알람 ID로 업데이트

      // 2. WebRTC 초기화
      await _initializeWebRTC();

      // 3. 백엔드에서 ephemeral key 요청 (실제 알람 ID 사용)
      final session = await _getEphemeralKey(alarmId: actualAlarmId);
      _ephemeralKey = session.ephemeralKey;
      _sessionId = session.sessionId;
      _scheduleEphemeralRefresh(session.expiresInSeconds);

      // 4. 통화 시작 API(서버 CallLog 생성)를 먼저 호출해 callId 확보
      await _startCall();

      // 5. Offer/Answer 교환 (GPT 연결)
      await _connectToGPTViaWebRTC(_ephemeralKey!);

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
      print('📞 통화 시작 API 호출(DTO): $_sessionId');
      final api = CallManagementApiService();
      final res = await api.startCall(CallStartRequest(sessionId: _sessionId!));
      if (res.success && res.data != null) {
        _currentCallId = res.data!.callId;
        print('✅ 통화 시작 성공: Call ID $_currentCallId');
      } else {
        throw Exception('통화 시작 실패: ${res.message ?? 'unknown'}');
      }
    } catch (e) {
      // 409 등으로 실패 시 최근 통화 로그에서 callId 복구 시도
      print('❌ 통화 시작 오류: $e');
      final resolved = await _resolveCallIdFromRecentLogs();
      if (resolved) {
        print('✅ 최근 통화 로그에서 Call ID 복구: $_currentCallId');
        return;
      }
      rethrow;
    }
  }

  /// 최근 통화 로그에서 진행 중(또는 최신) callId를 복구
  Future<bool> _resolveCallIdFromRecentLogs() async {
    try {
      final logsApi = CallLogApiService();
      final resp = await logsApi.getCallLogs(limit: 5, offset: 0);
      if (resp.success && resp.data != null && resp.data!.isNotEmpty) {
        // 우선 callEnd == null인 항목 우선
        final active = resp.data!.where((c) => c.callEnd == null).toList();
        if (active.isNotEmpty) {
          _currentCallId = active.first.id;
          return true;
        }
        // 아니면 가장 최근 항목 선택(응급 복구)
        _currentCallId = resp.data!.first.id;
        return true;
      }
      return false;
    } catch (e) {
      print('⚠️ 최근 통화 로그 조회 실패: $e');
      return false;
    }
  }

  /// 통화 종료 API 호출
  Future<void> _endCall(String result, int snoozeCount) async {
    try {
      if (_currentCallId == null) {
        print('⚠️ Call ID가 없어서 통화 종료 API 호출 건너뜀');
        return;
      }
      print('📞 통화 종료 API 호출(DTO): Call ID $_currentCallId, Result: $result');
      final api = CallManagementApiService();
      final req = CallEndRequest(
        callEnd: DateTime.now(),
        result: result,
        snoozeCount: snoozeCount,
      );
      final res = await api.endCall(_currentCallId!, req);
      if (res.success) {
        print('✅ 통화 종료 성공');
      } else {
        print('⚠️ 통화 종료 실패: ${res.message ?? res.statusCode}');
      }
    } catch (e) {
      print('❌ 통화 종료 오류: $e');
    }
  }

  /// 전화 알람 종료 (성공)
  Future<void> endMorningCall() async {
    try {
      print('📞 전화 알람 종료 (성공)');
      // 종료 직전 callId 확보 보강: 누락 시 세션으로 통화 시작 호출
      if (_currentCallId == null && _sessionId != null) {
        print('⚠️ callId 없음 - 종료 전 startCall 시도');
        try { await _startCall(); } catch (e) { print('⚠️ startCall 보강 실패: $e'); }
      }
      // 대화 내용 저장 시도 (한 번에) - 종료 전에 저장
      try {
        print('💬 대화 저장 체크: callId=$_currentCallId, 항목 수=${_conversation.length}');
        if (_currentCallId != null && _conversation.isNotEmpty) {
          print('💬 대화 내용: $_conversation');
          await saveConversation(_conversation);
        } else {
          print('⚠️ 대화 저장 건너뜀: callId=${_currentCallId == null ? "null" : "있음"}, 비어있음=${_conversation.isEmpty}');
        }
      } catch (e) {
        print('⚠️ 대화 내용 저장 스킵/오류: $e');
      }
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
      try { _ephemeralRefreshTimer?.cancel(); } catch (_) {}
      _ephemeralRefreshTimer = null;

      onCallEnded?.call();
    } catch (e) {
      print('❌ 전화 알람 종료 오류: $e');
    }
  }

  /// 전화 알람 실패 종료 (스누즈 한계 도달)
  Future<void> endMorningCallWithFailure() async {
    try {
      print('📞 전화 알람 종료 (실패)');
      if (_currentCallId == null && _sessionId != null) {
        print('⚠️ callId 없음 - 종료 전 startCall 시도');
        try { await _startCall(); } catch (e) { print('⚠️ startCall 보강 실패: $e'); }
      }
      // 종료 전에 대화 저장
      try {
        if (_currentCallId != null && _conversation.isNotEmpty) {
          await saveConversation(_conversation);
        }
      } catch (e) {
        print('⚠️ 대화 내용 저장 스킵/오류: $e');
      }
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

  /// 전화 알람 실패 종료 (무발화 등)
  Future<void> endMorningCallNoTalk() async {
    try {
      print('📞 전화 알람 종료 (무발화)');
      // 통화 종료 API 호출 - 무발화 사유
      if (_currentCallId == null && _sessionId != null) {
        print('⚠️ callId 없음 - 종료 전 startCall 시도');
        try { await _startCall(); } catch (e) { print('⚠️ startCall 보강 실패: $e'); }
      }
      // 종료 전에 대화 저장
      try {
        if (_currentCallId != null && _conversation.isNotEmpty) {
          await saveConversation(_conversation);
        }
      } catch (e) {
        print('⚠️ 대화 내용 저장 스킵/오류: $e');
      }
      await _endCall('FAIL_NO_TALK', _snoozeCount);
      await _cleanupWebRTC();
      _originalInstructions = null;
      onCallEnded?.call();
    } catch (e) {
      print('❌ 전화 알람 무발화 종료 오류: $e');
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

    // 데이터 채널 생성 (Realtime API 메시지용)
    final dataChannelDict = RTCDataChannelInit();
    dataChannelDict.ordered = true;
    _dataChannel = await _peerConnection!.createDataChannel('oai-events', dataChannelDict);

    _dataChannel!.onMessage = (RTCDataChannelMessage message) {
      unawaited(_handleRealtimeMessage(message.text));
    };

    _dataChannel!.onDataChannelState = (state) {
      print('📡 데이터 채널 상태: $state');
      if (state == RTCDataChannelState.RTCDataChannelOpen) {
        // 데이터 채널이 열리면 세션 설정
        _setupRealtimeMessageHandling();
        _reconnectAttempts = 0;
        _isReconnecting = false;
      } else if (state == RTCDataChannelState.RTCDataChannelClosed && _isCallActive) {
        // 닫힘 감지 시 자동 복구 시도
        _handleDisconnectAndReconnect();
      }
    };

    // 로컬 오디오 트랙 (마이크)
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

    // 로컬 마이크 트랙을 추가하되, 로컬에서는 재생하지 않도록 설정
    _localStream!.getTracks().forEach((t) {
      _peerConnection!.addTrack(t, _localStream!);
    });

    // 연결 상태 변경 리스너
    _peerConnection!.onConnectionState = (state) {
      print('🔗 WebRTC 연결 상태: $state');
      if ((state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
           state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) && _isCallActive) {
        _handleDisconnectAndReconnect();
      }
    };

    // 원격 스트림
    _peerConnection!.onAddStream = (stream) async {
      // 중복 호출 방지
      if (_remoteStreamHandled) {
        print('⚠️ 원격 스트림 이미 처리됨 - 중복 호출 무시');
        return;
      }
      _remoteStreamHandled = true;

      _remoteStream = stream;

      // 오디오 트랙 활성화
      final audioTracks = stream.getAudioTracks();
      for (var track in audioTracks) {
        track.enabled = true;
      }

      print('🔊 원격 오디오 스트림 수신 (트랙: ${audioTracks.length})');

      // 콜백이 설정될 때까지 대기 (최대 2초)
      int retries = 20;
      while (onRemoteStream == null && retries > 0) {
        await Future.delayed(const Duration(milliseconds: 100));
        retries--;
      }

      if (onRemoteStream != null) {
        onRemoteStream!(stream);
        print('✅ 원격 스트림 콜백 호출 완료');
      } else {
        print('❌ 원격 스트림 콜백이 설정되지 않음');
      }
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

    if (res.statusCode == 200 || res.statusCode == 201) {
      final answer = RTCSessionDescription(res.data, 'answer');
      await _peerConnection!.setRemoteDescription(answer);
      print('✅ Answer 적용 완료 (상태 코드: ${res.statusCode})');

      // 데이터 채널이 열리면 onDataChannelState 콜백에서 _setupRealtimeMessageHandling() 호출됨
    } else {
      throw Exception('Offer 전송 실패: ${res.statusCode}');
    }
  }

  /// 실시간 메시지 처리 설정
  void _setupRealtimeMessageHandling() {
    print('📡 실시간 메시지 처리 설정 완료');

    // 세션 설정 메시지 전송
    final String baseInstructions = _originalInstructions ?? '부드럽게 깨워주세요';
    final String guardrails =
        '규칙:\n'
        '1) 사용자의 응답이 문제와 관련 있고 충분히 구체적일 때만 정답으로 인정하세요.\n'
        '2) "응", "음", "어" 등 짧은 감탄/잠꼬대는 정답으로 인정하지 마세요.\n'
        '3) 수학/객관식은 정확한 값을 요구하고, 불명확하면 다시 물어보세요.\n'
        '4) 오답/불명확 시 정답을 유도하는 힌트를 제공하고, 정답 확인 후에만 "잘하셨어요"라고 말하세요.';

    _sendRealtimeMessage({
      'type': 'session.update',
      'session': {
        'modalities': ['text', 'audio'],
        'instructions': '$baseInstructions\n\n$guardrails',
        'voice': 'alloy',
        'input_audio_format': 'pcm16',
        'output_audio_format': 'pcm16',
        'input_audio_transcription': {
          'model': 'whisper-1',
        },
        'turn_detection': {
          'type': 'server_vad',
          'threshold': 0.5,
          'prefix_padding_ms': 300,
          'silence_duration_ms': 500,
        },
      },
    });

    // 대화 시작 메시지 전송
    _sendRealtimeMessage({
      'type': 'response.create',
    });
  }

  /// Realtime API 메시지 전송
  void _sendRealtimeMessage(Map<String, dynamic> message) {
    if (_dataChannel?.state == RTCDataChannelState.RTCDataChannelOpen) {
      final messageStr = jsonEncode(message);
      _dataChannel!.send(RTCDataChannelMessage(messageStr));
      print('📤 메시지 전송: ${message['type']}');
    } else {
      print('❌ 데이터 채널이 열려있지 않습니다: ${_dataChannel?.state}');
      if (_isCallActive) {
        _handleDisconnectAndReconnect();
      }
    }
  }

  /// Realtime API 메시지 수신 처리
  Future<void> _handleRealtimeMessage(String messageStr) async {
    try {
      final message = jsonDecode(messageStr) as Map<String, dynamic>;
      final type = message['type'] as String;

      print('📥 메시지 수신: $type');

      switch (type) {
        case 'session.created':
        case 'session.updated':
          print('✅ 세션 설정 완료');
          break;
        case 'error':
          final err = message['error'];
          print('⚠️ Realtime 오류 수신: $err');
          if (_isCallActive) {
            _handleDisconnectAndReconnect();
          }
          break;

        case 'response.audio.delta':
          // 오디오 청크 수신 (자동으로 재생됨)
          break;

        case 'response.audio_transcript.delta':
          final transcript = message['delta'] as String?;
          if (transcript != null && transcript.isNotEmpty) {
            print('🗣️ GPT: $transcript');
            _assistantBuffer.write(transcript);
          }
          break;

        case 'input_audio_buffer.speech_started':
          print('🎤 사용자 말하기 시작');
          onUserSpeechDetected?.call(); // 타이머 리셋
          break;

        case 'input_audio_buffer.speech_stopped':
          print('🎤 사용자 말하기 종료');
          break;

        case 'conversation.item.input_audio_transcription.completed':
          final transcript = message['transcript'] as String?;
          if (transcript != null) {
            print('👤 사용자: $transcript');
            final meaningful = _isMeaningfulSpeech(transcript);
            if (meaningful) {
              _userHasSpokenInSession = true; // 사용자 발화 기록 (성공 인정)
            } else {
              print('⚠️ 무의미 발화 감지 - 성공으로 간주하지 않음: "$transcript"');
            }
            onUserSpeechDetected?.call(); // 타이머 리셋
            // 스누즈 키워드 감지는 의미있는 발화에만 적용
            if (meaningful) {
              _handleVoiceSnooze(transcript);
            }
            // 대화 내역 저장 (사용자) - 빈 문자열 제외
            if (transcript.trim().isNotEmpty) {
              _conversation.add({
                'speaker': 'user',
                'text': transcript,
                'timestamp': _formatTimestamp(DateTime.now()),
              });
            }
            onTranscript?.call('user', transcript);
            // 단일 발화 즉시 전송
            // 발화는 종료 시 한 번에 저장합니다.
          }
          break;

        case 'response.audio_transcript.done':
          // 어시스턴트 발화 확정
          final text = _assistantBuffer.toString().trim();
          if (text.isNotEmpty) {
            _conversation.add({
              'speaker': 'assistant',
              'text': text,
              'timestamp': _formatTimestamp(DateTime.now()),
            });
            onTranscript?.call('assistant', text);
            // 단일 발화 즉시 전송
            // 발화는 종료 시 한 번에 저장합니다.
          }
          _assistantBuffer.clear();
          break;

        case 'response.done':
          print('✅ 응답 완료');
          print('🔍 _userHasSpokenInSession = $_userHasSpokenInSession');
          // 사용자가 발화한 후 GPT 응답이 완료되면 알람 1차 성공으로 간주
          if (_userHasSpokenInSession) {
            print('🎉 사용자 발화 후 GPT 응답 완료 - 알람 1차 성공! MissionScreen으로 이동');
            onGPTResponseCompleted?.call();
          } else {
            print('⚠️ 사용자가 아직 의미있는 발화를 하지 않아서 MissionScreen으로 이동하지 않음');
          }
          break;


        default:
          print('📨 기타 메시지: $type');
      }
    } catch (e) {
      print('❌ 메시지 처리 오류: $e');
    }
  }

  bool _isMeaningfulSpeech(String text) {
    var s = text.trim();
    if (s.isEmpty) return false;
    // 공백 제거 후 길이 체크
    final compact = s.replaceAll(RegExp(r'\s+'), '');
    if (compact.length <= 2) return false; // 1~2글자 반응은 제외 (예: 응, 음, 어)
    // 전형적 감탄/잠꼬대 리스트 제외
    const fillers = [
      '응','으응','음','어','아','에','예','어어','음음','응응','흠','허','헉','오','아아','으아'
    ];
    if (fillers.contains(compact)) return false;
    // 자음 반복 같은 패턴 제외(예: ㅎㅎ, ㅋㅋ)
    if (RegExp(r'^[ㅎㅋㄷㅂㅈㄱ]+$').hasMatch(compact)) return false;
    return true;
  }

  /// 음성에서 스누즈 키워드 감지 및 처리
  Future<void> _handleVoiceSnooze(String voiceText) async {
    if (_currentAlarmId == null || _snoozeCount >= _maxSnoozeCount) {
      return;
    }

    // 스누즈 관련 키워드 감지
    // 원래의 넓은 키워드 목록 (롤백)
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

  // (롤백) 음성 스누즈 감지 토글 제거

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

  /// 원래 알람 정보 로드 (없으면 생성)
  Future<int> _loadOriginalAlarmInfo(int alarmId) async {
    try {
      // 먼저 기존 알람 조회 시도
      final response = await _dio.get('/api/alarms/$alarmId');
      if (response.statusCode == 200) {
        final alarmData = response.data['data'] as Map<String, dynamic>;
        _originalInstructions = alarmData['instructions'] as String? ?? '부드럽게 깨워주세요';
        print('✅ 기존 알람 정보 로드: $_originalInstructions');
        return alarmId; // 기존 알람 ID 반환
      } else {
        print('⚠️ 알람 조회 실패, 새로 생성 시도: ${response.statusCode}');
        throw Exception('알람을 찾을 수 없습니다');
      }
    } catch (e) {
      print('⚠️ 알람 조회 실패, 새로 생성 시도: $e');
      
      // 알람이 없으면 새로 생성
      try {
        print('🆕 새 알람 생성 중...');
        final now = DateTime.now();
        final alarmTime = DateTime(now.year, now.month, now.day, now.hour, now.minute + 1);
        
        final createResponse = await _dio.post('/api/alarms', data: {
          'alarmTime': alarmTime.toIso8601String(),
          'instructions': '부드럽게 깨워주세요',
          'voice': 'ALLOY',
        });
        
        if (createResponse.statusCode == 201) {
          final alarmData = createResponse.data['data'] as Map<String, dynamic>?;
          if (alarmData == null || alarmData['alarmId'] == null) {
            print('❌ 알람 생성 실패: 응답 데이터가 null입니다');
            throw Exception('알람 생성 실패: 응답 데이터가 null입니다');
          }
          final newAlarmId = alarmData['alarmId'] as int;
          _originalInstructions = alarmData['instructions'] as String? ?? '부드럽게 깨워주세요';
          print('✅ 새 알람 생성 완료: $_originalInstructions (ID: $newAlarmId)');
          return newAlarmId; // 새로 생성된 알람 ID 반환
        } else {
          print('❌ 알람 생성 실패: ${createResponse.statusCode}');
          throw Exception('알람 생성 실패: ${createResponse.statusCode}');
        }
      } catch (createError) {
        print('❌ 알람 생성 오류: $createError');
        rethrow;
      }
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
    // 스누즈 시간 경과 후, 알람 화면으로 네비게이션(수락 시에만 통화 연결)
    Timer(Duration(minutes: snoozeMinutes), () {
      try {
        print('⏰ 스누즈 시간 완료 - 알람 화면으로 네비게이션');
        final payload = '{"alarmId": $alarmId, "alarmType": "전화알람", "title": "전화 알람(스누즈)"}';
        navigateToAlarmScreen(payload);
      } catch (e) {
        print('❌ 스누즈 네비게이션 실패: $e');
      }
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
    _remoteStreamHandled = false; // 플래그 리셋
    _userHasSpokenInSession = false; // 플래그 리셋
    try { _ephemeralRefreshTimer?.cancel(); } catch (_) {}
    _ephemeralRefreshTimer = null;
    _assistantBuffer.clear();
    _conversation.clear();
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

      print('💬 대화 내용 저장: Call ID $_currentCallId, 항목 수: ${conversation.length}');

      // DTO에 맞는 Utterance 리스트로 변환
      final utterances = conversation.map((e) {
        final speaker = (e['speaker'] ?? '').toString();
        final text = (e['text'] ?? '').toString();
        final tsStr = (e['timestamp'] ?? '').toString();
        DateTime ts;
        try {
          ts = DateTime.parse(tsStr);
        } catch (_) {
          ts = DateTime.now();
        }
        return Utterance(speaker: speaker, text: text, timestamp: ts);
      }).toList();

      final req = TranscriptRequest(conversation: utterances);
      final api = CallManagementApiService();
      final res = await api.saveTranscript(_currentCallId!, req);

      if (res.success) {
        print('✅ 대화 내용 저장 성공');
      } else {
        print('⚠️ 대화 내용 저장 실패: ${res.message ?? res.statusCode}');
      }

    } catch (e) {
      print('❌ 대화 내용 저장 오류: $e');
    }
  }

  // 대화 누적 버퍼/리스트
  final StringBuffer _assistantBuffer = StringBuffer();
  final List<Map<String, dynamic>> _conversation = [];

  String _formatTimestamp(DateTime dt) {
    // 서버 DTO 예시와 동일한 형태: yyyy-MM-ddTHH:mm:ss
    final local = dt.toLocal();
    final iso = local.toIso8601String();
    final noMillis = iso.split('.').first; // 밀리초 제거
    return noMillis;
  }

  // 단일 발화 즉시 저장은 사용하지 않음(요청사항: 종료 시 한 번에 저장)

  /// 인증 토큰 가져오기
  String? _getAuthToken() {
    try {
      final baseApi = BaseApiService();
      return baseApi.accessToken;
    } catch (e) {
      print('❌ 토큰 로드 오류: $e');
      return null;
    }
  }

  /// 서비스 정리

  /// 연결 끊김 처리 및 자동 재연결
  Future<void> _handleDisconnectAndReconnect() async {
    if (_isReconnecting || !_isCallActive) return;
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      print('❌ 재연결 최대 시도 횟수 초과');
      onError?.call('연결이 끊겼습니다. 다시 시도해주세요.');
      return;
    }

    _isReconnecting = true;
    _reconnectAttempts += 1;
    print('🔁 재연결 시도 ${_reconnectAttempts}/$_maxReconnectAttempts');

    try {
      await _cleanupWebRTC();
      await _initializeWebRTC();

      final session = await _getEphemeralKey(
        alarmId: _currentAlarmId,
        snoozeCount: _snoozeCount,
      );
      _ephemeralKey = session.ephemeralKey;
      _sessionId = session.sessionId;
      _scheduleEphemeralRefresh(session.expiresInSeconds);

      await _connectToGPTViaWebRTC(_ephemeralKey!);

      _isConnected = true;
      _isReconnecting = false;
      print('✅ 재연결 성공');
    } catch (e) {
      print('❌ 재연결 실패: $e');
      _isReconnecting = false;
      if (_reconnectAttempts < _maxReconnectAttempts) {
        await Future.delayed(Duration(seconds: 1 * _reconnectAttempts));
        await _handleDisconnectAndReconnect();
      } else {
        onError?.call('연결 복구 실패: $e');
      }
    }
  }

  void _scheduleEphemeralRefresh(int expiresInSeconds) {
    try {
      _ephemeralRefreshTimer?.cancel();
    } catch (_) {}
    // 만료 10초 전에 재연결 시도
    final seconds = expiresInSeconds > 15 ? expiresInSeconds - 10 : (expiresInSeconds > 5 ? expiresInSeconds - 3 : expiresInSeconds);
    _ephemeralRefreshTimer = Timer(Duration(seconds: seconds), () {
      if (_isCallActive) {
        print('⏳ Ephemeral key 만료 임박 - 선제 재연결 시도');
        _handleDisconnectAndReconnect();
      }
    });
  }

  void dispose() {
    endMorningCall();
  }
}
