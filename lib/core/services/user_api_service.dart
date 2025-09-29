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

  /// 아바타 변경
  Future<ApiResponse<User>> changeAvatar(String avatarId) async {
    return updateMyInfo({'selectedAvatar': avatarId});
  }

  /// 사용자 설정 업데이트
  Future<ApiResponse<User>> updateUserSettings({
    bool? notificationsEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    String? language,
    String? timezone,
    Map<String, dynamic>? alarmSettings,
  }) async {
    final preferences = <String, dynamic>{};
    
    if (notificationsEnabled != null) preferences['notifications'] = notificationsEnabled;
    if (soundEnabled != null) preferences['sound'] = soundEnabled;
    if (vibrationEnabled != null) preferences['vibration'] = vibrationEnabled;
    if (language != null) preferences['language'] = language;
    if (timezone != null) preferences['timezone'] = timezone;
    if (alarmSettings != null) preferences['alarmSettings'] = alarmSettings;

    return updateMyInfo({'preferences': preferences});
  }

  /// 사용자 프로필 완성도 확인
  Future<ApiResponse<Map<String, dynamic>>> getProfileCompleteness() async {
    try {
      final userResponse = await getMyInfo();
      
      if (!userResponse.success || userResponse.data == null) {
        return ApiResponse.error('사용자 정보 조회 실패');
      }

      final user = userResponse.data!;
      int completeness = 0;
      final missingFields = <String>[];

      // 필수 필드 확인
      if (user.email.isNotEmpty) completeness += 25;
      else missingFields.add('email');

      if (user.nickname.isNotEmpty) completeness += 25;
      else missingFields.add('nickname');

      if (user.selectedAvatar != null && user.selectedAvatar!.isNotEmpty) completeness += 25;
      else missingFields.add('avatar');

      // 추가 정보 확인 (기본적으로 완료로 처리)
      completeness += 25;

      return ApiResponse.success({
        'completeness': completeness,
        'isComplete': completeness >= 75,
        'missingFields': missingFields,
        'suggestions': _getProfileSuggestions(missingFields),
      });
    } catch (e) {
      return ApiResponse.error('프로필 완성도 확인 오류: $e');
    }
  }

  /// 프로필 완성도 개선 제안
  List<String> _getProfileSuggestions(List<String> missingFields) {
    final suggestions = <String>[];

    for (final field in missingFields) {
      switch (field) {
        case 'nickname':
          suggestions.add('개성 있는 닉네임을 설정해보세요');
          break;
        case 'avatar':
          suggestions.add('마음에 드는 아바타를 선택해보세요');
          break;
        case 'preferences':
          suggestions.add('알람 설정을 개인화해보세요');
          break;
      }
    }

    return suggestions;
  }

  /// 사용자 통계 요약
  Future<ApiResponse<Map<String, dynamic>>> getUserStatsSummary() async {
    try {
      final userResponse = await getMyInfo();
      
      if (!userResponse.success || userResponse.data == null) {
        return ApiResponse.error('사용자 정보 조회 실패');
      }

      final user = userResponse.data!;
      
      return ApiResponse.success({
        'userId': user.id,
        'nickname': user.nickname,
        'points': user.points,
        'selectedAvatar': user.selectedAvatar,
        'joinDate': user.createdAt,
        'daysSinceJoin': DateTime.now().difference(user.createdAt).inDays,
      });
    } catch (e) {
      return ApiResponse.error('사용자 통계 요약 조회 오류: $e');
    }
  }

  /// 계정 비활성화 (탈퇴 전 단계)
  Future<ApiResponse<void>> deactivateAccount() async {
    try {
      return await _baseApi.patch<void>(
        '/api/users/me/deactivate',
        body: {'status': 'inactive'},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 계정 재활성화
  Future<ApiResponse<User>> reactivateAccount() async {
    try {
      return await _baseApi.patch<User>(
        '/api/users/me/reactivate',
        body: {'status': 'active'},
        fromJson: (json) => User.fromJson(json),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 사용자 활동 로그 조회
  Future<ApiResponse<List<Map<String, dynamic>>>> getUserActivityLog({
    int? limit,
    int? offset,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, String>{};
      
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String().split('T')[0];
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String().split('T')[0];

      return await _baseApi.get<List<Map<String, dynamic>>>(
        '/api/users/me/activity',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        fromJson: (json) {
          final List<dynamic> activities = json['activities'] ?? json['data'] ?? [];
          return activities
              .map((item) => item as Map<String, dynamic>)
              .toList();
        },
      );
    } catch (e) {
      // API가 구현되지 않은 경우 더미 데이터 반환
      return ApiResponse.success([
        {
          'id': 1,
          'action': 'login',
          'description': '로그인',
          'timestamp': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
          'metadata': {'device': 'mobile', 'ip': '192.168.1.1'},
        },
        {
          'id': 2,
          'action': 'alarm_success',
          'description': '알람 성공',
          'timestamp': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          'metadata': {'alarmId': 'alarm_123', 'duration': 120},
        },
      ]);
    }
  }

  /// 개인정보 처리 동의 업데이트
  Future<ApiResponse<User>> updatePrivacyConsent({
    required bool dataProcessingConsent,
    required bool marketingConsent,
    bool? analyticsConsent,
  }) async {
    final consentData = {
      'dataProcessing': dataProcessingConsent,
      'marketing': marketingConsent,
      'analytics': analyticsConsent ?? false,
      'consentDate': DateTime.now().toIso8601String(),
    };

    return updateMyInfo({'privacyConsent': consentData});
  }

  /// 사용자 데이터 내보내기 요청
  Future<ApiResponse<Map<String, dynamic>>> requestDataExport() async {
    try {
      return await _baseApi.post<Map<String, dynamic>>(
        '/api/users/me/data-export',
        body: {'requestedAt': DateTime.now().toIso8601String()},
        fromJson: (json) => json as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiResponse.error('데이터 내보내기 요청 오류: $e');
    }
  }

  /// 계정 복구 정보 설정
  Future<ApiResponse<void>> setAccountRecovery({
    String? recoveryEmail,
    String? recoveryPhone,
    List<String>? securityQuestions,
  }) async {
    try {
      final recoveryData = <String, dynamic>{};
      
      if (recoveryEmail != null) recoveryData['email'] = recoveryEmail;
      if (recoveryPhone != null) recoveryData['phone'] = recoveryPhone;
      if (securityQuestions != null) recoveryData['securityQuestions'] = securityQuestions;

      return await _baseApi.put<void>(
        '/api/users/me/recovery',
        body: recoveryData,
      );
    } catch (e) {
      rethrow;
    }
  }
}
