import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../models/user.dart';
import '../repositories/auth_repository.dart';
import '../repositories/mock_auth_repository.dart';
import '../environment/environment.dart';
import '../constants/app_constants.dart';

final authRepositoryProvider = Provider<dynamic>((ref) {
  if (EnvironmentConfig.isDevelopment) {
    return MockAuthRepository();
  } else {
    // 실제 API Repository 사용
    return AuthRepository(dio: Dio());
  }
});

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
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
  final dynamic _authRepository;

  AuthNotifier(this._authRepository) : super(const AuthState()) {
    _loadStoredAuth();
  }

  Future<void> _loadStoredAuth() async {
    state = state.copyWith(isLoading: true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.tokenKey);
      
      if (token != null) {
        final response = await _authRepository.getCurrentUser(token);
        if (response['success'] && response['data'] != null) {
          state = state.copyWith(
            user: response['data'],
            token: token,
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
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _authRepository.login(email, password);
      
      if (response['success'] && response['data'] != null) {
        final token = response['data'];
        final userResponse = await _authRepository.getCurrentUser(token);
        
        if (userResponse['success'] && userResponse['data'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(AppConstants.tokenKey, token);
          await prefs.setInt(AppConstants.userIdKey, userResponse['data'].id);
          await prefs.setString(AppConstants.userNicknameKey, userResponse['data'].nickname);
          await prefs.setInt(AppConstants.userPointsKey, userResponse['data'].points);
          
          state = state.copyWith(
            user: userResponse['data'],
            token: token,
            isLoading: false,
          );
          return true;
        }
      }
      
      state = state.copyWith(
        isLoading: false,
        error: response['message'] ?? '로그인에 실패했습니다.',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> signup(String email, String password, String nickname) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _authRepository.signup(email, password, nickname);
      
      if (response['success'] && response['data'] != null) {
        state = state.copyWith(
          user: response['data'],
          isLoading: false,
        );
        return true;
      }
      
      state = state.copyWith(
        isLoading: false,
        error: response['message'] ?? '회원가입에 실패했습니다.',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userIdKey);
    await prefs.remove(AppConstants.userNicknameKey);
    await prefs.remove(AppConstants.userPointsKey);
    
    state = const AuthState();
  }
}