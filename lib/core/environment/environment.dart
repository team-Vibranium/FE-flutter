import 'package:flutter_dotenv/flutter_dotenv.dart';

enum Environment {
  development,
  production,
}

class EnvironmentConfig {
  static Environment _environment = Environment.development;
  
  static Environment get current => _environment;
  
  static void setEnvironment(Environment env) {
    _environment = env;
  }
  
  static bool get isDevelopment => _environment == Environment.development;
  static bool get isProduction => _environment == Environment.production;
  
  static String get baseUrl {
    // .env 파일에서 BASE_URL 읽기, 없으면 환경에 따른 기본값 사용
    final envUrl = dotenv.env['BASE_URL'];
    if (envUrl != null && envUrl.isNotEmpty) {
      return envUrl;
    }
    
    // 기본값 fallback
    switch (_environment) {
      case Environment.development:
        return 'http://localhost:8080';
      case Environment.production:
        return 'https://api.aningcall.com';
    }
  }
  
  /// API 연결 상태 확인용 헬퍼 메서드
  static String get healthCheckUrl => '$baseUrl/health';
  static String get apiVersion => dotenv.env['API_VERSION'] ?? 'v1';
  static int get timeout => int.tryParse(dotenv.env['API_TIMEOUT'] ?? '30') ?? 30;
}
