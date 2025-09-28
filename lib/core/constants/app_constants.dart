class AppConstants {
  // API 관련 상수는 이제 EnvironmentConfig에서 관리됩니다
  // static const String baseUrl = 'https://api.aningcall.com'; // 삭제됨 - EnvironmentConfig.baseUrl 사용
  // static const String devBaseUrl = 'http://localhost:8080'; // 삭제됨 - EnvironmentConfig.baseUrl 사용
  
  // 로컬 저장소 키
  static const String tokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String userNicknameKey = 'user_nickname';
  static const String userPointsKey = 'user_points';
  
  // 알람 관련 상수
  static const int maxSnoozeCount = 3;
  static const int snoozeDelayMinutes = 5;
  static const int totalSnoozeTimeMinutes = 15;
  
  // 포인트 관련 상수
  static const int successPoints = 10;
  static const int failPoints = 0;
  
  // 미션 타입
  static const String puzzleMissionType = 'PUZZLE';
}
