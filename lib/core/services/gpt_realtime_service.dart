import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:permission_handler/permission_handler.dart';

/// GPT Realtime API를 활용한 양방향 음성 대화 서비스
class GPTRealtimeService {
  static final GPTRealtimeService _instance = GPTRealtimeService._internal();
  factory GPTRealtimeService() => _instance;
  GPTRealtimeService._internal();

  // WebSocket 연결
  WebSocketChannel? _channel;
  
  // WebRTC 관련
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  
  // 상태 관리
  bool _isConnected = false;
  bool _isCallActive = false;
  String? _sessionId;
  
  // 콜백
  Function(String)? onMessageReceived;
  Function(String)? onError;
  Function()? onCallStarted;
  Function()? onCallEnded;
  Function(MediaStream)? onRemoteStream;

  // GPT Realtime API 설정
  static const String _gptRealtimeUrl = 'wss://api.openai.com/v1/realtime';
  String? _apiKey;

  /// 서비스 초기화
  Future<void> initialize(String apiKey) async {
    _apiKey = apiKey;
    
    // 권한 요청
    await _requestPermissions();
    
    print('🎤 GPT Realtime Service 초기화 완료');
  }

  /// 권한 요청
  Future<void> _requestPermissions() async {
    final microphoneStatus = await Permission.microphone.request();
    
    if (microphoneStatus != PermissionStatus.granted) {
      throw Exception('마이크 권한이 필요합니다');
    }
    
    print('✅ 마이크 권한 승인됨');
  }

  /// 모닝콜 시작
  Future<void> startMorningCall({
    required String alarmTitle,
    required String userName,
  }) async {
    try {
      if (_apiKey == null) {
        throw Exception('API 키가 설정되지 않았습니다');
      }

      print('🌅 모닝콜 시작: $alarmTitle');
      
      // 1. WebRTC 초기화
      await _initializeWebRTC();
      
      // 2. GPT Realtime API 연결
      await _connectToGPT();
      
      // 3. 세션 설정
      await _setupSession(alarmTitle, userName);
      
      // 4. 대화 시작
      await _startConversation(alarmTitle, userName);
      
      _isCallActive = true;
      onCallStarted?.call();
      
    } catch (e) {
      print('❌ 모닝콜 시작 오류: $e');
      onError?.call('모닝콜 시작 실패: $e');
      rethrow;
    }
  }

  /// WebRTC 초기화
  Future<void> _initializeWebRTC() async {
    // WebRTC 설정
    final configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    };

    // PeerConnection 생성
    _peerConnection = await createPeerConnection(configuration);
    
    // 로컬 미디어 스트림 획득 (Flutter WebRTC 방식)
    Map<String, dynamic> mediaConstraints = {
      'audio': {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
        'sampleRate': 24000, // GPT Realtime API 요구사항
        'channelCount': 1,
      },
      'video': false,
    };
    
    _localStream = await MediaDevices.getUserMedia(mediaConstraints);

    // 로컬 스트림을 PeerConnection에 추가
    _localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });

    // 원격 스트림 처리
    _peerConnection!.onAddStream = (stream) {
      _remoteStream = stream;
      onRemoteStream?.call(stream);
      print('🔊 원격 오디오 스트림 수신됨');
    };

    print('🎧 WebRTC 초기화 완료');
  }

  /// GPT Realtime API 연결
  Future<void> _connectToGPT() async {
    final headers = {
      'Authorization': 'Bearer $_apiKey',
      'OpenAI-Beta': 'realtime=v1',
    };

    try {
      _channel = IOWebSocketChannel.connect(
        Uri.parse('$_gptRealtimeUrl?model=gpt-4o-realtime-preview-2024-12-17'),
        headers: headers,
      );

      // WebSocket 메시지 처리
      _channel!.stream.listen(
        _handleWebSocketMessage,
        onError: (error) {
          print('❌ WebSocket 오류: $error');
          onError?.call('GPT 연결 오류: $error');
        },
        onDone: () {
          print('🔌 GPT 연결 종료됨');
          _isConnected = false;
        },
      );

      _isConnected = true;
      print('🤖 GPT Realtime API 연결됨');
      
    } catch (e) {
      throw Exception('GPT API 연결 실패: $e');
    }
  }

  /// WebSocket 메시지 처리
  void _handleWebSocketMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      final type = data['type'] as String?;
      
      print('📨 GPT 메시지: $type');
      
      switch (type) {
        case 'session.created':
          _sessionId = data['session']['id'];
          print('✅ GPT 세션 생성됨: $_sessionId');
          break;
          
        case 'response.audio.delta':
          // 오디오 데이터 처리
          _handleAudioResponse(data);
          break;
          
        case 'response.text.delta':
          // 텍스트 응답 처리
          final text = data['delta'] as String?;
          if (text != null) {
            onMessageReceived?.call(text);
          }
          break;
          
        case 'error':
          final error = data['error']['message'];
          print('❌ GPT 오류: $error');
          onError?.call('GPT 오류: $error');
          break;
          
        default:
          print('🔍 처리되지 않은 메시지 타입: $type');
      }
    } catch (e) {
      print('❌ 메시지 파싱 오류: $e');
    }
  }

  /// 오디오 응답 처리
  void _handleAudioResponse(Map<String, dynamic> data) {
    try {
      final audioData = data['delta'] as String?;
      if (audioData != null && _remoteStream != null) {
        // Base64 오디오 데이터를 디코딩하여 재생
        final audioBytes = base64Decode(audioData);
        _playAudioData(audioBytes);
      }
    } catch (e) {
      print('❌ 오디오 처리 오류: $e');
    }
  }

  /// 오디오 데이터 재생
  void _playAudioData(Uint8List audioBytes) {
    // WebRTC를 통해 오디오 재생
    // 실제 구현에서는 오디오 트랙에 직접 데이터를 주입해야 함
    print('🔊 오디오 재생: ${audioBytes.length} bytes');
  }

  /// 세션 설정
  Future<void> _setupSession(String alarmTitle, String userName) async {
    final sessionConfig = {
      'type': 'session.update',
      'session': {
        'modalities': ['text', 'audio'],
        'instructions': '''
당신은 친근하고 에너지 넘치는 AI 모닝콜 도우미입니다.
사용자 이름: $userName
오늘의 알람: $alarmTitle

역할:
1. $userName을 상냥하고 활기차게 깨워주세요
2. 알람 제목 "$alarmTitle"과 관련된 동기부여 멘트를 해주세요
3. 오늘 하루를 긍정적으로 시작할 수 있도록 격려해주세요
4. 사용자가 완전히 깨어날 때까지 대화를 이어가세요
5. 간단한 스트레칭이나 기상 루틴을 제안해주세요

말투: 친근하고 밝은 톤으로, 마치 친한 친구가 깨워주는 것처럼
''',
        'voice': 'alloy', // 또는 'echo', 'fable', 'onyx', 'nova', 'shimmer'
        'input_audio_format': 'pcm16',
        'output_audio_format': 'pcm16',
        'input_audio_transcription': {
          'model': 'whisper-1'
        },
        'turn_detection': {
          'type': 'server_vad',
          'threshold': 0.5,
          'prefix_padding_ms': 300,
          'silence_duration_ms': 500,
        },
        'tools': [],
        'tool_choice': 'auto',
        'temperature': 0.8,
      }
    };

    _sendMessage(sessionConfig);
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// 대화 시작
  Future<void> _startConversation(String alarmTitle, String userName) async {
    final startMessage = {
      'type': 'conversation.item.create',
      'item': {
        'type': 'message',
        'role': 'user',
        'content': [
          {
            'type': 'input_text',
            'text': '안녕! 알람 제목은 "$alarmTitle"이야. 이걸 기반으로 $userName을 깨워줘!'
          }
        ]
      }
    };

    _sendMessage(startMessage);

    // 응답 생성 요청
    final responseRequest = {
      'type': 'response.create',
      'response': {
        'modalities': ['text', 'audio'],
        'instructions': '사용자를 활기차게 깨워주세요!'
      }
    };

    _sendMessage(responseRequest);
  }

  /// 메시지 전송
  void _sendMessage(Map<String, dynamic> message) {
    if (_channel != null && _isConnected) {
      _channel!.sink.add(jsonEncode(message));
      print('📤 GPT로 메시지 전송: ${message['type']}');
    } else {
      print('❌ GPT 연결이 없습니다');
    }
  }

  /// 사용자 음성 입력 전송
  void sendAudioInput(Uint8List audioData) {
    if (!_isConnected) return;

    final audioMessage = {
      'type': 'input_audio_buffer.append',
      'audio': base64Encode(audioData),
    };

    _sendMessage(audioMessage);
  }

  /// 음성 입력 완료 신호
  void commitAudioInput() {
    if (!_isConnected) return;

    _sendMessage({'type': 'input_audio_buffer.commit'});
    _sendMessage({'type': 'response.create'});
  }

  /// 모닝콜 종료
  Future<void> endMorningCall() async {
    try {
      print('🛑 모닝콜 종료');
      
      // WebSocket 연결 종료
      await _channel?.sink.close();
      _channel = null;
      _isConnected = false;
      
      // WebRTC 정리
      await _localStream?.dispose();
      await _remoteStream?.dispose();
      await _peerConnection?.close();
      
      _localStream = null;
      _remoteStream = null;
      _peerConnection = null;
      
      _isCallActive = false;
      _sessionId = null;
      
      onCallEnded?.call();
      
    } catch (e) {
      print('❌ 모닝콜 종료 오류: $e');
    }
  }

  /// 현재 통화 상태
  bool get isCallActive => _isCallActive;
  
  /// 현재 연결 상태
  bool get isConnected => _isConnected;
  
  /// 세션 ID
  String? get sessionId => _sessionId;

  /// 서비스 정리
  void dispose() {
    endMorningCall();
  }
}
