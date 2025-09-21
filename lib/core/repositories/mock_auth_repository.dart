import '../models/user.dart';

class MockAuthRepository {
  Future<Map<String, dynamic>> login(String email, String password) async {
    // Mock 데이터 - 실제로는 SharedPreferences에서 확인
    await Future.delayed(const Duration(seconds: 1));
    
    if (email == 'test@example.com' && password == '123456') {
      return {
        'success': true,
        'data': 'mock-jwt-token-12345',
      };
    } else {
      return {
        'success': false,
        'code': 'AUTH_401',
        'message': '이메일 또는 비밀번호가 올바르지 않습니다.',
      };
    }
  }

  Future<Map<String, dynamic>> signup(String email, String password, String nickname) async {
    await Future.delayed(const Duration(seconds: 1));
    
    // Mock 사용자 생성
    final user = User(
      id: 1,
      email: email,
      nickname: nickname,
      points: 0,
      createdAt: DateTime.now(),
    );

    return {
      'success': true,
      'data': user,
    };
  }

  Future<Map<String, dynamic>> getCurrentUser(String token) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Mock 사용자 데이터
    final user = User(
      id: 1,
      email: 'test@example.com',
      nickname: '테스트유저',
      points: 150,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    );

    return {
      'success': true,
      'data': user,
    };
  }
}