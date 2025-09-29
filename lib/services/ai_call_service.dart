import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/services/api_service.dart';
import '../core/services/call_management_api_service.dart';
import '../core/models/api_models.dart';

/// AI 통화 상태
enum AICallState {
  idle,           // 대기 중
  initializing,   // 초기화 중
  connecting,     // 연결 중
  connected,      // 연결됨
  speaking,       // AI가 말하는 중
  listening,      // 사용자 음성 듣는 중
  processing,     // 응답 처리 중
  ending,         // 통화 종료 중
  ended,          // 통화 종료됨
  error,          // 오류 발생
}

/// AI 통화 이벤트
class AICallEvent {
  final AICallState state;
  final String? message;
  final dynamic data;

  AICallEvent({
    required this.state,
    this.message,
    this.data,
  });
}

/// AI 통화 서비스
/// 서버 기반 AI 음성 통화 기능 제공 (realtime API와 WebRTC는 서버에서 처리)
class AICallService {
  static final AICallService _instance = AICallService._internal();
  factory AICallService() => _instance;
  AICallService._internal();

  // 상태 관리
  AICallState _currentState = AICallState.idle;
  final StreamController<AICallEvent> _eventController = StreamController.broadcast();
  final StreamController<String> _transcriptController = StreamController.broadcast();

  // 통화 설정
  String _currentAlarmTitle = '';
  bool _isMuted = false;
  bool _isSpeakerOn = true;
  String _currentTranscript = '';

  // WebRTC 관련
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  // OpenAI Realtime API 관련
  WebSocketChannel? _realtimeChannel;
  SessionResponse? _currentSession;

  // 서버 통화 관리 관련
  int? _currentCallId;
  DateTime? _callStartTime;
  int _snoozeCount = 0;
  static const int _maxSnoozeCount = 3;

  // 이벤트 스트림
  Stream<AICallEvent> get eventStream => _eventController.stream;
  Stream<String> get transcriptStream => _transcriptController.stream;

  /// 현재 통화 상태
  AICallState get currentState => _currentState;

  /// 현재 알람 제목
  String get currentAlarmTitle => _currentAlarmTitle;

  /// 음소거 상태
  bool get isMuted => _isMuted;

  /// 스피커 상태
  bool get isSpeakerOn => _isSpeakerOn;

  /// 현재 대화 내용
  String get currentTranscript => _currentTranscript;

  /// 현재 스누즈 횟수
  int get snoozeCount => _snoozeCount;

  /// AI 통화 시작 (실제 API 연동)
  Future<bool> startCall(String alarmTitle, {int? alarmId}) async {
    if (_currentState != AICallState.idle) {
      debugPrint('AICallService: Call already in progress');
      return false;
    }

    _currentAlarmTitle = alarmTitle;
    _updateState(AICallState.initializing, 'AI 통화를 초기화하는 중...');

    try {
      // 1. 백엔드에서 OpenAI ephemeral key 가져오기
      _updateState(AICallState.connecting, '서버와 연결 중...');

      final apiService = ApiService();
      // 우선 전달받은 alarmId로 시도하고, 실패 시 서버 알람을 생성해 재시도
      int? targetAlarmId = alarmId;
      Future<ApiResponse<SessionResponse>> _tryCreateSession(int id) {
        return apiService.realtime.createSession(alarmId: id, snoozeCount: _snoozeCount);
      }

      ApiResponse<SessionResponse> sessionResponse;
      if (targetAlarmId != null) {
        sessionResponse = await _tryCreateSession(targetAlarmId);
      } else {
        // 전달된 알람 ID가 없으면 실패로 간주하여 아래 생성 경로로 진행
        sessionResponse = ApiResponse.error('alarmId not provided');
      }

      if (!sessionResponse.success || sessionResponse.data == null) {
        debugPrint('AICallService: 기존 alarmId로 세션 생성 실패: ${sessionResponse.message ?? sessionResponse.error}');
        // 서버 알람을 생성하고 해당 ID로 다시 시도
        try {
          final createReq = CreateAlarmRequest(
            alarmTime: DateTime.now().add(const Duration(minutes: 1)),
            instructions: '알람 제목: $alarmTitle\n부드럽고 상냥하게 깨워주세요.',
            voice: 'ALLOY',
          );
          final createRes = await apiService.alarm.createAlarm(createReq);
          if (createRes.success && createRes.data != null) {
            targetAlarmId = createRes.data!.alarmId;
            debugPrint('AICallService: 서버 알람 생성 성공 alarmId=$targetAlarmId, 세션 재시도');
            sessionResponse = await _tryCreateSession(targetAlarmId!);
          } else {
            throw Exception('서버 알람 생성 실패: ${createRes.message ?? createRes.error}');
          }
        } catch (e) {
          throw Exception('세션 생성 실패(서버 알람 생성 경유): $e');
        }
      }

      // 2. 서버에 통화 시작 기록 생성 (스웨거: POST /api/calls/start)
      try {
        final startResponse = await apiService.callManagement.startCall(
          CallStartRequest(sessionId: sessionResponse.data!.sessionId),
        );
        if (startResponse.success && startResponse.data != null) {
          _currentCallId = startResponse.data!.callId;
          _callStartTime = startResponse.data!.callStart;
          debugPrint('AICallService: 서버 통화 시작 기록 생성됨 - callId=$_currentCallId');
        } else {
          debugPrint('AICallService: 서버 통화 시작 기록 생성 실패: ${startResponse.message}');
        }
      } catch (e) {
        debugPrint('AICallService: 서버 통화 시작 API 호출 오류: $e');
      }

      // 3. WebRTC + OpenAI Realtime API 연결
      final success = await _initializeRealtimeConnection(sessionResponse.data!);

      if (success) {
        _updateState(AICallState.connected, 'AI와 연결되었습니다');
        debugPrint('AICallService: Call started successfully with real API');
        return true;
      } else {
        throw Exception('Realtime API 연결 실패');
      }

    } catch (e) {
      debugPrint('AICallService: Failed to start call: $e');
      _updateState(AICallState.error, 'AI 통화 시작 실패: $e');
      await _cleanup();
      return false;
    }
  }

  /// 음소거 토글
  void toggleMute() {
    _isMuted = !_isMuted;

    // 로컬 오디오 트랙 음소거 처리
    if (_localStream != null) {
      final audioTracks = _localStream!.getAudioTracks();
      for (final track in audioTracks) {
        track.enabled = !_isMuted;
      }
    }

    final message = _isMuted ? '음소거됨' : '음소거 해제됨';
    _updateState(_currentState, message);

    debugPrint('AICallService: Mute toggled: $_isMuted');
  }

  /// 스피커 토글
  void toggleSpeaker() {
    _isSpeakerOn = !_isSpeakerOn;
    
    final message = _isSpeakerOn ? '스피커 켜짐' : '스피커 꺼짐';
    _updateState(_currentState, message);
    
    debugPrint('AICallService: Speaker toggled: $_isSpeakerOn');
  }

  /// 텍스트 메시지 전송
  void sendTextMessage(String message) {
    if (_currentState != AICallState.connected && 
        _currentState != AICallState.listening) {
      debugPrint('AICallService: Cannot send text message - not connected');
      return;
    }

    // 서버에 텍스트 메시지 전송 구현 필요
    debugPrint('AICallService: Text message would be sent: $message');
  }

  /// 알람 해제 요청
  Future<bool> requestAlarmDismissal() async {
    if (_currentState != AICallState.connected) {
      debugPrint('AICallService: Cannot request alarm dismissal - not connected');
      return false;
    }

    // 서버에 알람 해제 조건 확인 요청
    sendTextMessage('사용자가 완전히 깨어있는 것 같나요? 알람을 해제해도 될까요?');

    // 서버 응답 대기
    await Future.delayed(const Duration(seconds: 2));
    return true;
  }

  /// 음성에서 스누즈 키워드 감지 및 API 호출
  Future<void> _handleVoiceSnooze(String voiceText) async {
    if (_currentCallId == null || _snoozeCount >= _maxSnoozeCount) {
      return;
    }

    // 스누즈 관련 키워드 감지
    final snoozeKeywords = [
      '스누즈', '다시', '깨워', '5분', '나중에', '잠깐', '조금 더',
      '있다가', '더 자', '더 잘래', '10분', '15분', '몇 분',
      '잠시만', '좀 더', '아직', '피곤해', '졸려', '더 쉴게'
    ];

    final lowerText = voiceText.toLowerCase().replaceAll(' ', '');
    final hasSnoozeKeyword = snoozeKeywords.any((keyword) =>
      lowerText.contains(keyword.toLowerCase().replaceAll(' ', '')));

    if (!hasSnoozeKeyword) {
      return;
    }

    debugPrint('AICallService: 스누즈 키워드 감지됨: "$voiceText"');

    try {
      final callManagement = CallManagementApiService();
      final snoozeResponse = await callManagement.snoozeCall(_currentCallId!);

      if (snoozeResponse.success && snoozeResponse.data != null) {
        _snoozeCount = snoozeResponse.data!.currentSnoozeCount;

        debugPrint('AICallService: 스누즈 성공, count=$_snoozeCount, shouldFail=${snoozeResponse.data!.shouldFail}');

        if (snoozeResponse.data!.shouldFail) {
          // 스누즈 한계 도달 - 알람 실패 처리
          _updateState(AICallState.error, '스누즈 한계에 도달했습니다. 알람이 실패로 처리됩니다.');
          await endCall();
        } else {
          // 스누즈 성공 - 사용자에게 알리기
          final message = '스누즈가 적용되었습니다 (${_snoozeCount}/${_maxSnoozeCount})';
          _updateState(_currentState, message);

          // AI에게 스누즈 상황 알리기
          _sendSnoozeNotificationToAI();
        }
      } else {
        debugPrint('AICallService: 스누즈 API 실패: ${snoozeResponse.message ?? snoozeResponse.error}');
      }
    } catch (e) {
      debugPrint('AICallService: 스누즈 처리 중 오류: $e');
    }
  }

  /// AI에게 스누즈 상황 알림
  void _sendSnoozeNotificationToAI() {
    if (_realtimeChannel != null) {
      final snoozeMessage = {
        'type': 'conversation.item.create',
        'item': {
          'type': 'message',
          'role': 'user',
          'content': [
            {
              'type': 'input_text',
              'text': '사용자가 스누즈를 요청했습니다. ${5 * _snoozeCount}분 후에 다시 깨워달라고 했습니다. 잠시 후 통화가 재시작될 예정입니다.'
            }
          ]
        }
      };

      _realtimeChannel!.sink.add(jsonEncode(snoozeMessage));
      debugPrint('AICallService: AI에게 스누즈 알림 전송됨');
    }
  }

  /// 통화 종료
  Future<void> endCall() async {
    if (_currentState == AICallState.idle || _currentState == AICallState.ended) {
      debugPrint('AICallService: Call already ended');
      return;
    }

    _updateState(AICallState.ending, '통화를 종료하는 중...');

    try {
      // 서버에 통화 종료 및 트랜스크립트 저장 연동
      final apiService = ApiService();

      // 1) transcript 저장 (선택)
      if (_currentCallId != null && _currentTranscript.isNotEmpty) {
        try {
          final transcriptReq = TranscriptRequest(
            conversation: [
              Utterance(
                speaker: 'assistant',
                text: _currentTranscript,
                timestamp: DateTime.now(),
              ),
            ],
          );
          final tr = await apiService.callManagement.saveTranscript(
            _currentCallId!,
            transcriptReq,
          );
          debugPrint('AICallService: transcript 저장 결과: ${tr.success}');
        } catch (e) {
          debugPrint('AICallService: transcript 저장 실패: $e');
        }
      }

      // 2) 통화 종료 기록
      if (_currentCallId != null) {
        try {
          final result = _determineResult();
          final endReq = CallEndRequest(
            callEnd: DateTime.now(),
            result: result,
            snoozeCount: _snoozeCount,
          );
          final er = await apiService.callManagement.endCall(
            _currentCallId!,
            endReq,
          );
          debugPrint('AICallService: endCall 결과: ${er.success}');
        } catch (e) {
          debugPrint('AICallService: endCall 실패: $e');
        }
      }

      await _cleanup();
      _updateState(AICallState.ended, '통화가 종료되었습니다');
      
      // 잠시 후 idle 상태로 변경
      Future.delayed(const Duration(seconds: 2), () {
        if (_currentState == AICallState.ended) {
          _updateState(AICallState.idle);
        }
      });

      debugPrint('AICallService: Call ended successfully');
    } catch (e) {
      debugPrint('AICallService: Error ending call: $e');
      _updateState(AICallState.error, '통화 종료 중 오류 발생');
    }
  }

  /// 통화 결과 문자열 매핑 (스웨거: SUCCESS | FAIL_NO_TALK | FAIL_SNOOZE)
  String _determineResult() {
    switch (_currentState) {
      case AICallState.connected:
      case AICallState.speaking:
      case AICallState.listening:
      case AICallState.processing:
        return 'SUCCESS';
      default:
        return 'FAIL_NO_TALK';
    }
  }

  /// WebRTC + OpenAI Realtime API 초기화
  Future<bool> _initializeRealtimeConnection(SessionResponse session) async {
    try {
      _currentSession = session;

      // 1. 권한 확인
      final micPermission = await Permission.microphone.request();
      if (!micPermission.isGranted) {
        throw Exception('마이크 권한이 필요합니다');
      }

      // 2. WebRTC 초기화
      await _initializeWebRTC();

      // 3. OpenAI Realtime API WebSocket 연결
      await _connectToOpenAI();

      return true;
    } catch (e) {
      debugPrint('AICallService: Failed to initialize realtime connection: $e');
      return false;
    }
  }

  /// WebRTC 초기화
  Future<void> _initializeWebRTC() async {
    debugPrint('AICallService: Initializing WebRTC...');

    // WebRTC 설정
    final configuration = <String, dynamic>{
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ]
    };

    // PeerConnection 생성
    _peerConnection = await createPeerConnection(configuration);

    // 로컬 미디어 스트림 가져오기
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
        'sampleRate': 24000, // OpenAI Realtime API 요구사항
        'channelCount': 1,
      },
      'video': false,
    });

    // 로컬 스트림을 PeerConnection에 추가
    _localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });

    // 원격 스트림 이벤트 처리
    _peerConnection!.onAddStream = (MediaStream stream) {
      debugPrint('AICallService: Remote stream received');
      _remoteStream = stream;
    };

    debugPrint('AICallService: WebRTC initialized successfully');
  }

  /// OpenAI Realtime API WebSocket 연결
  Future<void> _connectToOpenAI() async {
    debugPrint('AICallService: Connecting to OpenAI Realtime API...');

    try {
      // OpenAI Realtime API 연결 (헤더로 인증 전달)
      final uri = Uri.parse(
        'wss://api.openai.com/v1/realtime'
        '?model=gpt-4o-realtime-preview-2024-12-17'
      );

      _realtimeChannel = IOWebSocketChannel.connect(
        uri,
        headers: {
          'Authorization': 'Bearer ${_currentSession!.ephemeralKey}',
          'OpenAI-Beta': 'realtime=v1',
        },
        protocols: ['realtime'],
      );

      // WebSocket 메시지 처리
      _realtimeChannel!.stream.listen(
        (message) => _handleRealtimeMessage(message),
        onError: (error) => debugPrint('AICallService: WebSocket error: $error'),
        onDone: () => debugPrint('AICallService: WebSocket connection closed'),
      );

      // 인증 정보 및 초기 설정 전송
      await _sendAuthAndSessionConfiguration();

      debugPrint('AICallService: OpenAI Realtime API connected successfully');
    } catch (e) {
      debugPrint('AICallService: Failed to connect to OpenAI: $e');
      rethrow;
    }
  }

  /// OpenAI Realtime API 메시지 처리
  Future<void> _handleRealtimeMessage(dynamic message) async {
    try {
      final data = jsonDecode(message);
      final type = data['type'] as String?;

      switch (type) {
        case 'session.created':
          debugPrint('AICallService: OpenAI session created');
          _updateState(AICallState.connected, 'AI와 연결되었습니다');
          break;
        case 'conversation.item.created':
          debugPrint('AICallService: AI is speaking');
          _updateState(AICallState.speaking, 'AI가 말하고 있습니다');
          break;
        case 'input_audio_buffer.speech_started':
          debugPrint('AICallService: User speech detected');
          _updateState(AICallState.listening, '사용자 음성을 듣고 있습니다');
          break;
        case 'input_audio_buffer.speech_stopped':
          debugPrint('AICallService: User speech stopped');
          _updateState(AICallState.processing, 'AI가 응답을 처리하고 있습니다');
          break;
        case 'response.audio.transcript.done':
          final transcript = data['transcript'] as String?;
          if (transcript != null) {
            _currentTranscript += 'AI: $transcript\n';
            _transcriptController.add(_currentTranscript);
          }
          break;
        case 'input_audio_buffer.transcript.completed':
          final userTranscript = data['transcript'] as String?;
          if (userTranscript != null) {
            _currentTranscript += 'User: $userTranscript\n';
            _transcriptController.add(_currentTranscript);

            // 사용자 음성에서 스누즈 키워드 감지
            await _handleVoiceSnooze(userTranscript);
          }
          break;
        case 'conversation.item.input_audio_transcription.completed':
          final userTranscript = data['transcript'] as String?;
          if (userTranscript != null) {
            _currentTranscript += 'User: $userTranscript\n';
            _transcriptController.add(_currentTranscript);

            // 사용자 음성에서 스누즈 키워드 감지
            await _handleVoiceSnooze(userTranscript);
          }
          break;
        case 'error':
          debugPrint('AICallService: OpenAI error: ${data['error']}');
          break;
      }
    } catch (e) {
      debugPrint('AICallService: Failed to process realtime message: $e');
    }
  }

  /// 인증 및 세션 설정 전송
  Future<void> _sendAuthAndSessionConfiguration() async {
    // OpenAI Realtime API는 일반적으로 URL에 ephemeral key를 포함하거나
    // 특별한 인증 방식을 사용합니다.
    // 실제 구현은 OpenAI의 최신 문서에 따라 조정이 필요할 수 있습니다.

    final sessionConfig = {
      'type': 'session.update',
      'session': {
        'modalities': ['text', 'audio'],
        'instructions': '''당신은 친근하고 도움이 되는 AI 알람 어시스턴트입니다.
사용자를 깨우고 오늘 하루를 시작할 수 있도록 도와주세요.
간단한 대화를 통해 사용자가 완전히 깨어날 수 있도록 유도하세요.
대화는 3-5분 정도로 적당히 진행해주세요.''',
        'voice': 'alloy',
        'input_audio_format': 'pcm16',
        'output_audio_format': 'pcm16',
        'input_audio_transcription': {
          'model': 'whisper-1'
        },
        'turn_detection': {
          'type': 'server_vad',
          'threshold': 0.5,
          'prefix_padding_ms': 300,
          'silence_duration_ms': 200
        }
      }
    };

    _realtimeChannel!.sink.add(jsonEncode(sessionConfig));
    debugPrint('AICallService: Session configuration sent');
  }

  /// 리소스 정리
  Future<void> _cleanup() async {
    // WebSocket 연결 종료
    _realtimeChannel?.sink.close();
    _realtimeChannel = null;

    // WebRTC 정리
    _localStream?.dispose();
    _localStream = null;

    _remoteStream?.dispose();
    _remoteStream = null;

    _peerConnection?.close();
    _peerConnection = null;

    // 세션 정보 정리
    _currentSession = null;

    // 상태 초기화
    _currentAlarmTitle = '';
    _isMuted = false;
    _isSpeakerOn = true;
    _currentTranscript = '';
    _snoozeCount = 0;
    _currentCallId = null;
    _callStartTime = null;

    debugPrint('AICallService: Cleanup completed');
  }

  /// 상태 업데이트
  void _updateState(AICallState newState, [String? message]) {
    if (_currentState != newState) {
      _currentState = newState;
      
      final event = AICallEvent(
        state: newState,
        message: message,
      );
      
      _eventController.add(event);
      debugPrint('AICallService: State changed to $newState${message != null ? ' - $message' : ''}');
    }
  }

  /// 통화 통계 정보
  Map<String, dynamic> getCallStats() {
    return {
      'state': _currentState.toString(),
      'alarmTitle': _currentAlarmTitle,
      'isMuted': _isMuted,
      'isSpeakerOn': _isSpeakerOn,
      'transcriptLength': _currentTranscript.length,
    };
  }

  /// 리소스 해제
  void dispose() {
    _cleanup();
    _eventController.close();
    _transcriptController.close();
  }
}
