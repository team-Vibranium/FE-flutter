import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
// import 'package:flutter_webrtc/flutter_webrtc.dart';  // 임시 비활성화
// import 'webrtc_service.dart';  // 임시 비활성화
// import 'audio_processor.dart';  // 임시 비활성화

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
/// WebRTC, OpenAI Realtime API, AudioProcessor를 통합하여 AI 음성 통화 기능 제공
class AICallService {
  static final AICallService _instance = AICallService._internal();
  factory AICallService() => _instance;
  AICallService._internal();

  // 서비스 인스턴스 (현재 비활성화)
  
  // Mock WebRTC Service (임시)
  late final _MockWebRTCService _webrtcService;
  
  // Mock Audio Processor (임시)
  late final _MockAudioProcessor _audioProcessor;

  // 상태 관리
  AICallState _currentState = AICallState.idle;
  final StreamController<AICallEvent> _eventController = StreamController.broadcast();
  final StreamController<String> _transcriptController = StreamController.broadcast();

  // 구독 관리
  StreamSubscription? _webrtcStateSubscription;
  StreamSubscription? _audioDataSubscription;
  StreamSubscription? _processedAudioSubscription;

  // 통화 설정
  String _currentAlarmTitle = '';
  bool _isMuted = false;
  bool _isSpeakerOn = true;
  String _currentTranscript = '';

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

  /// AI 통화 시작
  Future<bool> startCall(String alarmTitle) async {
    if (_currentState != AICallState.idle) {
      debugPrint('AICallService: Call already in progress');
      return false;
    }

    _currentAlarmTitle = alarmTitle;
    _updateState(AICallState.initializing, 'AI 통화를 초기화하는 중...');

    try {
      // 0. Mock 서비스 초기화
      _webrtcService = _MockWebRTCService();
      _audioProcessor = _MockAudioProcessor();
      
      // 1. 이벤트 리스너 설정
      _setupEventListeners();

      // 2. WebRTC 초기화
      _updateState(AICallState.connecting, 'WebRTC 연결 중...');
      final webrtcSuccess = await _webrtcService.initialize();
      if (!webrtcSuccess) {
        throw Exception('WebRTC initialization failed');
      }

      // 3. AI 서비스 연결 (현재 비활성화)
      _updateState(AICallState.connecting, 'AI 서비스 연결 중...');
      // OpenAI 연결 로직은 현재 비활성화됨

      // 4. 오디오 처리 시작
      final localStream = _webrtcService.localStream;
      if (localStream != null) {
        final audioTracks = localStream.getAudioTracks();
        if (audioTracks.isNotEmpty) {
          _audioProcessor.startProcessing(audioTracks.first);
        }
      }

      // 5. 연결 완료 및 대화 시작
      _updateState(AICallState.connected, 'AI와 연결되었습니다');
      
      // AI 대화 시작 (현재 비활성화)
      await Future.delayed(const Duration(milliseconds: 500));
      // _openaiService.startConversation(); // 현재 비활성화

      debugPrint('AICallService: Call started successfully');
      return true;

    } catch (e) {
      debugPrint('AICallService: Failed to start call: $e');
      _updateState(AICallState.error, 'AI 통화 시작 실패: $e');
      await _cleanup();
      return false;
    }
  }

  /// 이벤트 리스너 설정
  void _setupEventListeners() {
    // WebRTC 상태 변경 리스너
    _webrtcStateSubscription = _webrtcService.connectionStateStream.listen(
      (state) {
        debugPrint('AICallService: WebRTC state changed: $state');
        if (state == WebRTCConnectionState.failed) {
          _updateState(AICallState.error, 'WebRTC 연결 실패');
        } else if (state == WebRTCConnectionState.disconnected && 
                  _currentState != AICallState.ending) {
          _updateState(AICallState.error, 'WebRTC 연결 끊어짐');
        }
      },
    );

    // OpenAI 관련 리스너들 (현재 비활성화)
    // _openaiStateSubscription = _openaiService.connectionStateStream.listen(...);
    // _openaiResponseSubscription = _openaiService.responseStream.listen(...);

    // WebRTC 오디오 데이터 리스너
    _audioDataSubscription = _webrtcService.audioDataStream.listen(
      (audioData) {
        if (_currentState == AICallState.connected || 
            _currentState == AICallState.listening) {
          // 마이크 입력 처리 (AI 전송 현재 비활성화)
          final processedAudio = _audioProcessor.prepareForTransmission(audioData);
          // _openaiService.sendAudio(processedAudio); // 현재 비활성화
        }
      },
    );

    // 처리된 오디오 데이터 리스너
    _processedAudioSubscription = _audioProcessor.processedAudioStream.listen(
      (audioData) {
        // 처리된 오디오 데이터 로깅
        debugPrint('AICallService: Processed audio frame (${audioData.length} bytes)');
      },
    );
  }

  // OpenAI 응답 처리 메서드들 (현재 비활성화)
  // void _handleOpenAIResponse(OpenAIResponse response) { ... }
  // void _handleAIAudioResponse(Uint8List audioData) { ... }
  // void _handleAITextResponse(String text) { ... }

  /// 음소거 토글
  void toggleMute() {
    _isMuted = !_isMuted;
    _webrtcService.toggleMute();
    
    final message = _isMuted ? '음소거됨' : '음소거 해제됨';
    _updateState(_currentState, message);
    
    debugPrint('AICallService: Mute toggled: $_isMuted');
  }

  /// 스피커 토글
  void toggleSpeaker() {
    _isSpeakerOn = !_isSpeakerOn;
    
    // 실제 구현에서는 오디오 출력 장치 변경 로직 필요
    final message = _isSpeakerOn ? '스피커 켜짐' : '스피커 꺼짐';
    _updateState(_currentState, message);
    
    debugPrint('AICallService: Speaker toggled: $_isSpeakerOn');
  }

  /// 텍스트 메시지 전송 (현재 비활성화)
  void sendTextMessage(String message) {
    if (_currentState != AICallState.connected && 
        _currentState != AICallState.listening) {
      debugPrint('AICallService: Cannot send text message - not connected');
      return;
    }

    // _openaiService.sendTextMessage(message); // 현재 비활성화
    debugPrint('AICallService: Text message would be sent: $message');
  }

  /// 알람 해제 요청
  Future<bool> requestAlarmDismissal() async {
    if (_currentState != AICallState.connected) {
      debugPrint('AICallService: Cannot request alarm dismissal - not connected');
      return false;
    }

    // AI에게 알람 해제 조건 확인 요청
    sendTextMessage('사용자가 완전히 깨어있는 것 같나요? 알람을 해제해도 될까요?');
    
    // 실제 구현에서는 AI 응답을 분석하여 알람 해제 여부 결정
    // 현재는 간단히 true 반환
    await Future.delayed(const Duration(seconds: 2));
    return true;
  }

  /// 통화 종료
  Future<void> endCall() async {
    if (_currentState == AICallState.idle || _currentState == AICallState.ended) {
      debugPrint('AICallService: Call already ended');
      return;
    }

    _updateState(AICallState.ending, '통화를 종료하는 중...');

    try {
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

  /// 리소스 정리
  Future<void> _cleanup() async {
    // 구독 취소
    await _webrtcStateSubscription?.cancel();
    await _audioDataSubscription?.cancel();
    await _processedAudioSubscription?.cancel();

    _webrtcStateSubscription = null;
    _audioDataSubscription = null;
    _processedAudioSubscription = null;

    // 서비스 정리
    _audioProcessor.stopProcessing();
    // await _openaiService.disconnect(); // 현재 비활성화
    await _webrtcService.disconnect();

    // 상태 초기화
    _currentAlarmTitle = '';
    _isMuted = false;
    _isSpeakerOn = true;
    _currentTranscript = '';
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
      'webrtcState': _webrtcService.connectionState.toString(),
      // 'openaiState': _openaiService.connectionState.toString(), // 현재 비활성화
      'isAudioProcessing': _audioProcessor.isProcessing,
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

/// Mock WebRTC Service (임시 구현)
class _MockWebRTCService {
  final StreamController<dynamic> _connectionStateController = StreamController.broadcast();
  final StreamController<Uint8List> _audioDataController = StreamController.broadcast();
  
  Stream<dynamic> get connectionStateStream => _connectionStateController.stream;
  Stream<Uint8List> get audioDataStream => _audioDataController.stream;
  
  dynamic get localStream => null;
  String get connectionState => 'connected';
  
  Future<bool> initialize() async {
    return true;
  }
  
  void toggleMute() {}
  
  Future<void> disconnect() async {}
  
  void dispose() {
    _connectionStateController.close();
    _audioDataController.close();
  }
}

/// Mock Audio Processor (임시 구현)
class _MockAudioProcessor {
  final StreamController<Uint8List> _processedAudioController = StreamController.broadcast();
  
  Stream<Uint8List> get processedAudioStream => _processedAudioController.stream;
  bool get isProcessing => false;
  
  void startProcessing(dynamic audioTrack) {}
  
  Uint8List prepareForTransmission(Uint8List audioData) {
    return audioData;
  }
  
  Uint8List prepareForPlayback(Uint8List audioData) {
    return audioData;
  }
  
  void stopProcessing() {}
  
  void dispose() {
    _processedAudioController.close();
  }
}

/// Mock WebRTC Connection State (임시)
class WebRTCConnectionState {
  static const String failed = 'failed';
  static const String disconnected = 'disconnected';
  static const String connected = 'connected';
}
