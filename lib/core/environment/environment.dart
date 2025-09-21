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
    switch (_environment) {
      case Environment.development:
        return 'http://localhost:8080';
      case Environment.production:
        return 'https://api.aningcall.com';
    }
  }
}
