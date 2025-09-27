import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/constants/api_constants.dart';

/// WebRTC 연결 상태
enum WebRTCConnectionState {
  disconnected,
  connecting,
  connected,
  failed,
}

/// WebRTC 서비스 클래스
/// OpenAI Realtime API와의 실시간 오디오 통신을 위한 WebRTC 관리
class WebRTCService {
  static final WebRTCService _instance = WebRTCService._internal();
  factory WebRTCService() => _instance;
  WebRTCService._internal();

  // WebRTC 관련 객체
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  
  // 상태 관리
  WebRTCConnectionState _connectionState = WebRTCConnectionState.disconnected;
  final StreamController<WebRTCConnectionState> _stateController = StreamController.broadcast();
  final StreamController<MediaStream> _remoteStreamController = StreamController.broadcast();
  final StreamController<Uint8List> _audioDataController = StreamController.broadcast();
  
  // 이벤트 스트림
  Stream<WebRTCConnectionState> get connectionStateStream => _stateController.stream;
  Stream<MediaStream> get remoteStreamStream => _remoteStreamController.stream;
  Stream<Uint8List> get audioDataStream => _audioDataController.stream;
  
  // 설정은 ApiConstants에서 가져옴

  /// 권한 요청
  Future<bool> requestPermissions() async {
    try {
      // 현재 권한 상태 확인
      var micStatus = await Permission.microphone.status;
      debugPrint('WebRTC: Current microphone permission status: $micStatus');
      
      // 권한이 거부된 경우 재요청
      if (micStatus.isDenied) {
        debugPrint('WebRTC: Requesting microphone permission...');
        micStatus = await Permission.microphone.request();
      }
      
      // 권한이 영구적으로 거부된 경우 설정으로 안내
      if (micStatus.isPermanentlyDenied) {
        debugPrint('WebRTC: Microphone permission permanently denied, opening settings');
        await openAppSettings();
        return false;
      }
      
      if (micStatus == PermissionStatus.granted) {
        debugPrint('WebRTC: Microphone permission granted');
        return true;
      } else {
        debugPrint('WebRTC: Microphone permission denied: $micStatus');
        return false;
      }
    } catch (e) {
      debugPrint('WebRTC: Permission request failed: $e');
      return false;
    }
  }

  /// WebRTC 초기화
  Future<bool> initialize() async {
    try {
      _updateConnectionState(WebRTCConnectionState.connecting);
      
      // 권한 확인
      final hasPermission = await requestPermissions();
      if (!hasPermission) {
        _updateConnectionState(WebRTCConnectionState.failed);
        return false;
      }

      // PeerConnection 생성
      await _createPeerConnection();
      
      // 로컬 미디어 스트림 획득
      await _getUserMedia();
      
      _updateConnectionState(WebRTCConnectionState.connected);
      debugPrint('WebRTC: Initialization completed successfully');
      return true;
      
    } catch (e) {
      debugPrint('WebRTC: Initialization failed: $e');
      _updateConnectionState(WebRTCConnectionState.failed);
      return false;
    }
  }

  /// PeerConnection 생성 및 설정
  Future<void> _createPeerConnection() async {
    _peerConnection = await createPeerConnection(ApiConstants.webrtcConfiguration);
    
    // 이벤트 리스너 설정
    _peerConnection!.onIceCandidate = _onIceCandidate;
    _peerConnection!.onAddStream = _onAddStream;
    _peerConnection!.onRemoveStream = _onRemoveStream;
    _peerConnection!.onConnectionState = _onConnectionStateChange;
    _peerConnection!.onIceConnectionState = _onIceConnectionStateChange;
    
    debugPrint('WebRTC: PeerConnection created');
  }

  /// 로컬 미디어 스트림 획득
  Future<void> _getUserMedia() async {
    try {
      _localStream = await navigator.mediaDevices.getUserMedia(ApiConstants.mediaConstraints);
      
      // PeerConnection에 스트림 추가
      if (_peerConnection != null && _localStream != null) {
        _localStream!.getTracks().forEach((track) {
          _peerConnection!.addTrack(track, _localStream!);
        });
      }
      
      debugPrint('WebRTC: Local media stream acquired');
      
      // 오디오 데이터 스트림 시작
      _startAudioDataStream();
      
    } catch (e) {
      debugPrint('WebRTC: Failed to get user media: $e');
      throw e;
    }
  }

  /// 오디오 데이터 스트림 시작
  void _startAudioDataStream() {
    if (_localStream == null) return;
    
    final audioTracks = _localStream!.getAudioTracks();
    if (audioTracks.isEmpty) return;
    
    final audioTrack = audioTracks.first;
    
    // 실제 구현에서는 플랫폼별 오디오 데이터 추출이 필요
    // 현재는 더미 데이터로 구현
    Timer.periodic(const Duration(milliseconds: 20), (timer) {
      if (_connectionState != WebRTCConnectionState.connected) {
        timer.cancel();
        return;
      }
      
      // 20ms = 480 samples at 24kHz
      final dummyAudioData = Uint8List(960); // 480 samples * 2 bytes
      _audioDataController.add(dummyAudioData);
    });
  }

  /// ICE Candidate 이벤트 처리
  void _onIceCandidate(RTCIceCandidate candidate) {
    debugPrint('WebRTC: ICE Candidate: ${candidate.candidate}');
    // 실제 구현에서는 시그널링 서버로 전송
  }

  /// 원격 스트림 추가 이벤트 처리
  void _onAddStream(MediaStream stream) {
    debugPrint('WebRTC: Remote stream added');
    _remoteStream = stream;
    _remoteStreamController.add(stream);
  }

  /// 원격 스트림 제거 이벤트 처리
  void _onRemoveStream(MediaStream stream) {
    debugPrint('WebRTC: Remote stream removed');
    _remoteStream = null;
  }

  /// 연결 상태 변경 이벤트 처리
  void _onConnectionStateChange(RTCPeerConnectionState state) {
    debugPrint('WebRTC: Connection state changed: $state');
    
    switch (state) {
      case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
        _updateConnectionState(WebRTCConnectionState.connected);
        break;
      case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
      case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
        _updateConnectionState(WebRTCConnectionState.disconnected);
        break;
      case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
        _updateConnectionState(WebRTCConnectionState.failed);
        break;
      default:
        break;
    }
  }

  /// ICE 연결 상태 변경 이벤트 처리
  void _onIceConnectionStateChange(RTCIceConnectionState state) {
    debugPrint('WebRTC: ICE connection state changed: $state');
  }

  /// Offer 생성
  Future<RTCSessionDescription?> createOffer() async {
    if (_peerConnection == null) return null;
    
    try {
      final offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);
      debugPrint('WebRTC: Offer created');
      return offer;
    } catch (e) {
      debugPrint('WebRTC: Failed to create offer: $e');
      return null;
    }
  }

  /// Answer 생성
  Future<RTCSessionDescription?> createAnswer() async {
    if (_peerConnection == null) return null;
    
    try {
      final answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);
      debugPrint('WebRTC: Answer created');
      return answer;
    } catch (e) {
      debugPrint('WebRTC: Failed to create answer: $e');
      return null;
    }
  }

  /// 원격 설명 설정
  Future<void> setRemoteDescription(RTCSessionDescription description) async {
    if (_peerConnection == null) return;
    
    try {
      await _peerConnection!.setRemoteDescription(description);
      debugPrint('WebRTC: Remote description set');
    } catch (e) {
      debugPrint('WebRTC: Failed to set remote description: $e');
    }
  }

  /// ICE Candidate 추가
  Future<void> addIceCandidate(RTCIceCandidate candidate) async {
    if (_peerConnection == null) return;
    
    try {
      await _peerConnection!.addCandidate(candidate);
      debugPrint('WebRTC: ICE candidate added');
    } catch (e) {
      debugPrint('WebRTC: Failed to add ICE candidate: $e');
    }
  }

  /// 오디오 음소거 토글
  void toggleMute() {
    if (_localStream == null) return;
    
    final audioTracks = _localStream!.getAudioTracks();
    if (audioTracks.isNotEmpty) {
      final currentState = audioTracks.first.enabled;
      audioTracks.first.enabled = !currentState;
      debugPrint('WebRTC: Audio muted: ${!audioTracks.first.enabled}');
    }
  }

  /// 현재 음소거 상태 확인
  bool get isMuted {
    if (_localStream == null) return true;
    
    final audioTracks = _localStream!.getAudioTracks();
    if (audioTracks.isEmpty) return true;
    
    return !audioTracks.first.enabled;
  }

  /// 연결 상태 업데이트
  void _updateConnectionState(WebRTCConnectionState newState) {
    if (_connectionState != newState) {
      _connectionState = newState;
      _stateController.add(newState);
    }
  }

  /// 현재 연결 상태 반환
  WebRTCConnectionState get connectionState => _connectionState;

  /// 로컬 스트림 반환
  MediaStream? get localStream => _localStream;

  /// 원격 스트림 반환
  MediaStream? get remoteStream => _remoteStream;

  /// WebRTC 연결 종료
  Future<void> disconnect() async {
    try {
      // 스트림 정리
      if (_localStream != null) {
        _localStream!.getTracks().forEach((track) {
          track.stop();
        });
        await _localStream!.dispose();
        _localStream = null;
      }

      if (_remoteStream != null) {
        await _remoteStream!.dispose();
        _remoteStream = null;
      }

      // PeerConnection 정리
      if (_peerConnection != null) {
        await _peerConnection!.close();
        _peerConnection = null;
      }

      _updateConnectionState(WebRTCConnectionState.disconnected);
      debugPrint('WebRTC: Disconnected successfully');
      
    } catch (e) {
      debugPrint('WebRTC: Disconnect error: $e');
    }
  }

  /// 리소스 정리
  void dispose() {
    disconnect();
    _stateController.close();
    _remoteStreamController.close();
    _audioDataController.close();
  }
}
