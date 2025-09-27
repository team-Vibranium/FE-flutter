/// API 관련 상수 정의 (OpenAI 관련 설정 제거됨)
class ApiConstants {
  // API 설정들 (현재 비활성화)
  
  // WebRTC STUN/TURN 서버 설정
  static const List<String> stunServers = [
    'stun:stun1.l.google.com:19302',
    'stun:stun2.l.google.com:19302',
  ];
  
  // 오디오 설정
  static const int audioSampleRate = 24000;
  static const int audioChannels = 1; // 모노
  static const int audioBitDepth = 16; // 16-bit PCM
  static const String audioFormat = 'pcm16';
  
  // 통화 설정
  static const Duration maxCallDuration = Duration(minutes: 10);
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration responseTimeout = Duration(seconds: 10);
  
  /// WebRTC 설정 반환
  static Map<String, dynamic> get webrtcConfiguration => {
    'iceServers': [
      {
        'urls': stunServers,
      }
    ],
    'sdpSemantics': 'unified-plan',
  };
  
  /// 미디어 제약 조건 반환
  static Map<String, dynamic> get mediaConstraints => {
    'audio': {
      'echoCancellation': true,
      'noiseSuppression': true,
      'autoGainControl': true,
      'sampleRate': audioSampleRate,
    },
    'video': false, // 음성 통화만
  };
}
