import 'dart:async';
import 'package:flutter/foundation.dart';

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

  /// AI 통화 시작 (서버 기반)
  Future<bool> startCall(String alarmTitle) async {
    if (_currentState != AICallState.idle) {
      debugPrint('AICallService: Call already in progress');
      return false;
    }

    _currentAlarmTitle = alarmTitle;
    _updateState(AICallState.initializing, 'AI 통화를 초기화하는 중...');

    try {
      // TODO: 서버 API를 통한 AI 통화 세션 시작 요청
      _updateState(AICallState.connecting, '서버와 연결 중...');
      
      // 임시 연결 시뮬레이션
      await Future.delayed(const Duration(seconds: 1));
      
      _updateState(AICallState.connected, 'AI와 연결되었습니다');
      
      debugPrint('AICallService: Call started successfully (server-based)');
      return true;

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
    
    final message = _isMuted ? '음소거됨' : '음소거 해제됨';
    _updateState(_currentState, message);
    
    // TODO: 서버에 음소거 상태 전송
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

    // TODO: 서버에 텍스트 메시지 전송
    debugPrint('AICallService: Text message would be sent: $message');
  }

  /// 알람 해제 요청
  Future<bool> requestAlarmDismissal() async {
    if (_currentState != AICallState.connected) {
      debugPrint('AICallService: Cannot request alarm dismissal - not connected');
      return false;
    }

    // TODO: 서버에 알람 해제 조건 확인 요청
    sendTextMessage('사용자가 완전히 깨어있는 것 같나요? 알람을 해제해도 될까요?');
    
    // 임시 응답 시뮬레이션
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
    // TODO: 서버와의 연결 종료
    
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