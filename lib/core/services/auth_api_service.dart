import '../models/api_models.dart';
import 'base_api_service.dart';

/// 인증 관련 API 서비스
/// 회원가입, 로그인, 로그아웃 관련 API 호출 담당
class AuthApiService {
  static final AuthApiService _instance = AuthApiService._internal();
  factory AuthApiService() => _instance;
  AuthApiService._internal();

  final BaseApiService _baseApi = BaseApiService();

  /// 회원가입
  /// POST /api/auth/register
  Future<ApiResponse<LoginResponse>> register(RegisterRequest request) async {
    try {
      final response = await _baseApi.post<LoginResponse>(
        '/api/auth/register',
        body: request.toJson(),
        fromJson: (json) => LoginResponse.fromJson(json),
      );

      // 회원가입 성공 시 토큰 저장
      if (response.success && response.data != null) {
        // 토큰만 저장 (임시로 AuthToken 형태로 변환)
        final authToken = AuthToken(
          accessToken: response.data!.token,
          refreshToken: response.data!.token, // 임시로 같은 토큰 사용
          expiresAt: DateTime.now().add(const Duration(days: 1)), // 임시 만료시간
        );
        _baseApi.setAuthTokens(authToken);
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// 로그인
  /// POST /api/auth/login
  Future<ApiResponse<LoginResponse>> login(LoginRequest request) async {
    try {
      final response = await _baseApi.post<LoginResponse>(
        '/api/auth/login',
        body: request.toJson(),
        fromJson: (json) => LoginResponse.fromJson(json),
      );

      // 로그인 성공 시 토큰 저장
      if (response.success && response.data != null) {
        // 토큰만 저장 (임시로 AuthToken 형태로 변환)
        final authToken = AuthToken(
          accessToken: response.data!.token,
          refreshToken: response.data!.token, // 임시로 같은 토큰 사용
          expiresAt: DateTime.now().add(const Duration(days: 1)), // 임시 만료시간
        );
        _baseApi.setAuthTokens(authToken);
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// 로그아웃
  /// POST /api/auth/logout
  Future<ApiResponse<void>> logout() async {
    try {
      final response = await _baseApi.post<void>('/api/auth/logout');
      
      // 로그아웃 성공 시 토큰 제거
      if (response.success) {
        _baseApi.clearAuthTokens();
      }

      return response;
    } catch (e) {
      // 로그아웃 실패해도 로컬 토큰은 제거
      _baseApi.clearAuthTokens();
      rethrow;
    }
  }

  /// 토큰 갱신
  /// POST /api/auth/refresh (BaseApiService에서 구현)
  Future<ApiResponse<AuthToken>> refreshAuthToken() async {
    try {
      final response = await _baseApi.refreshAccessToken();
      if (response.success) {
        return ApiResponse.success(
          AuthToken(
            accessToken: _baseApi.accessToken!,
            refreshToken: _baseApi.refreshToken!,
            expiresAt: DateTime.now().add(const Duration(hours: 1)), // 임시
          ),
        );
      } else {
        return ApiResponse.error('토큰 갱신 실패');
      }
    } catch (e) {
      return ApiResponse.error('토큰 갱신 오류: $e');
    }
  }

  /// 현재 인증 상태 확인
  bool get isAuthenticated => _baseApi.accessToken != null;

  /// 현재 액세스 토큰
  String? get accessToken => _baseApi.accessToken;

  /// 현재 리프레시 토큰
  String? get refreshToken => _baseApi.refreshToken;
}
