import '../models/api_models.dart';
import 'base_api_service.dart';

/// 사용자 관리 관련 API 서비스
/// 사용자 정보 조회, 수정, 삭제 관련 API 호출 담당
class UserApiService {
  static final UserApiService _instance = UserApiService._internal();
  factory UserApiService() => _instance;
  UserApiService._internal();

  final BaseApiService _baseApi = BaseApiService();

  /// 내 정보 조회
  /// GET /api/users/me
  Future<ApiResponse<User>> getMyInfo() async {
    try {
      return await _baseApi.get<User>(
        '/api/users/me',
        fromJson: (json) => User.fromJson(json),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 내 정보 수정
  /// PUT /api/users/me
  Future<ApiResponse<User>> updateMyInfo(Map<String, dynamic> updates) async {
    try {
      return await _baseApi.put<User>(
        '/api/users/me',
        body: updates,
        fromJson: (json) => User.fromJson(json),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 비밀번호 수정
  /// PATCH /api/users/me/password
  Future<ApiResponse<void>> changePassword(PasswordChangeRequest request) async {
    try {
      return await _baseApi.patch<void>(
        '/api/users/me/password',
        body: request.toJson(),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 닉네임 수정
  /// PATCH /api/users/me/nickname
  Future<ApiResponse<User>> changeNickname(NicknameChangeRequest request) async {
    try {
      return await _baseApi.patch<User>(
        '/api/users/me/nickname',
        body: request.toJson(),
        fromJson: (json) => User.fromJson(json),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 회원 탈퇴
  /// DELETE /api/users/me
  Future<ApiResponse<void>> deleteAccount() async {
    try {
      final response = await _baseApi.delete<void>('/api/users/me');
      
      // 탈퇴 성공 시 토큰 제거
      if (response.success) {
        _baseApi.clearAuthTokens();
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }
}
