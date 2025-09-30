import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/api_models.dart';
import '../services/api_service.dart';

final authServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authServiceProvider));
});

class AuthState {
  final User? user;
  final String? token;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.token,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => user != null && token != null;
  bool get isLoggedOut => user == null && token == null;

  AuthState copyWith({
    User? user,
    String? token,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      token: token ?? this.token,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService;

  AuthNotifier(this._apiService) : super(const AuthState()) {
    _loadStoredAuth();
  }

  Future<void> _loadStoredAuth() async {
    state = state.copyWith(isLoading: true);
    
    try {
      if (_apiService.isAuthenticated) {
        // JWT 토큰 만료 시간 확인
        final authToken = _apiService.getStoredAuthToken();
        if (authToken != null && authToken.isExpired) {
          // 토큰이 만료된 경우 갱신 시도
          try {
            final refreshResponse = await _apiService.refreshAccessToken();
            if (refreshResponse.success && refreshResponse.data != null) {
              // 토큰 갱신 성공
              final newAuthToken = refreshResponse.data!;
              await _apiService.setAuthTokens(newAuthToken);
            } else {
              // 토큰 갱신 실패 - 로그아웃
              await logout();
              return;
            }
          } catch (e) {
            // 토큰 갱신 중 오류 - 로그아웃
            await logout();
            return;
          }
        }
        
        // 사용자 정보 조회
        final response = await _apiService.user.getMyInfo();
        if (response.success && response.data != null) {
          state = state.copyWith(
            user: response.data,
            token: _apiService.auth.accessToken,
            isLoading: false,
          );
        } else {
          await logout();
        }
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<bool> login(String email, String password) async {
    print('🔐 로그인 시작: $email');
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final loginRequest = LoginRequest(email: email, password: password);
      final response = await _apiService.auth.login(loginRequest);
      
      print('📡 로그인 응답 상태: ${response.success}');
      print('📄 로그인 응답 데이터: ${response.data}');
      print('💬 로그인 응답 메시지: ${response.message}');
      
      if (response.success && response.data != null) {
        // 로그인 응답에서 사용자 정보를 직접 사용
        final loginResponse = response.data!;
        
        print('✅ 로그인 성공!');
        print('👤 사용자 정보: ${loginResponse.user}');
        print('🔑 토큰: ${loginResponse.token.substring(0, 20)}...');
        
        print('🔄 상태 업데이트 전: isAuthenticated = ${state.isAuthenticated}');
        print('🔄 업데이트 전 user: ${state.user}');
        print('🔄 업데이트 전 token: ${state.token != null ? '있음' : '없음'}');
        
        final newState = state.copyWith(
          user: loginResponse.user,
          token: loginResponse.token,
          isLoading: false,
        );
        
        print('🔄 새 상태: isAuthenticated = ${newState.isAuthenticated}');
        print('🔄 새 상태 user: ${newState.user}');
        print('🔄 새 상태 token: ${newState.token != null ? '있음' : '없음'}');
        
        state = newState;
        
        print('🎉 인증 상태 업데이트 완료 - 최종 isAuthenticated: ${state.isAuthenticated}');
        return true;
      }
      
      print('❌ 로그인 실패: ${response.message}');
      state = state.copyWith(
        isLoading: false,
        error: response.message ?? '로그인에 실패했습니다.',
      );
      return false;
    } catch (e) {
      print('💥 로그인 예외 발생: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> signup(String email, String password, String nickname) async {
    print('📝 회원가입 시작: $email, $nickname');
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final registerRequest = RegisterRequest(
        email: email,
        password: password,
        nickname: nickname,
      );
      final response = await _apiService.auth.register(registerRequest);
      
      print('📡 회원가입 응답 상태: ${response.success}');
      print('📄 회원가입 응답 데이터: ${response.data}');
      print('💬 회원가입 응답 메시지: ${response.message}');
      
      if (response.success && response.data != null) {
        // 회원가입 응답에서 사용자 정보를 직접 사용
        final loginResponse = response.data!;
        
        print('✅ 회원가입 성공!');
        print('👤 사용자 정보: ${loginResponse.user}');
        print('🔑 토큰: ${loginResponse.token.substring(0, 20)}...');
        
        state = state.copyWith(
          user: loginResponse.user,
          token: loginResponse.token,
          isLoading: false,
        );
        
        print('🎉 인증 상태 업데이트 완료 - isAuthenticated: ${state.isAuthenticated}');
        return true;
      }
      
      print('❌ 회원가입 실패: ${response.message}');
      state = state.copyWith(
        isLoading: false,
        error: response.message ?? '회원가입에 실패했습니다.',
      );
      return false;
    } catch (e) {
      print('💥 회원가입 예외 발생: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _apiService.auth.logout();
    } catch (e) {
      // 로그아웃 실패해도 로컬 상태는 초기화
      print('로그아웃 API 호출 실패: $e');
    }
    
    state = const AuthState();
  }
}