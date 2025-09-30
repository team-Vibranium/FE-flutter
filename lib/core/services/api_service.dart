import '../models/api_models.dart' as models;
import '../environment/environment.dart';
import 'base_api_service.dart';
import 'auth_api_service.dart';
import 'user_api_service.dart';
import 'alarm_api_service.dart';
import 'call_log_api_service.dart';
import 'call_management_api_service.dart';
import 'realtime_api_service.dart';
import 'points_api_service.dart';
import 'mission_api_service.dart';
import 'mission_results_api_service.dart';
import 'statistics_api_service.dart';

/// 메인 API 서비스 클래스
/// 모든 API 서비스를 통합하여 제공하는 싱글톤 클래스
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // 기본 API 서비스
  final BaseApiService _baseApi = BaseApiService();

  // 각 도메인별 API 서비스
  late final AuthApiService auth;
  late final UserApiService user;
  late final AlarmApiService alarm;
  late final CallLogApiService callLog;
  late final CallManagementApiService callManagement;
  late final RealtimeApiService realtime;
  late final PointsApiService points;
  late final MissionApiService mission;
  late final MissionResultsApiService missionResults;
  late final StatisticsApiService statistics;

  bool _isInitialized = false;

  // BaseApiService 메서드들을 노출하는 getter들
  bool get isAuthenticated => _baseApi.accessToken != null;
  String? get accessToken => _baseApi.accessToken;
  String? get refreshToken => _baseApi.refreshToken;
  
  // BaseApiService 메서드들을 노출하는 메서드들
  models.AuthToken? getStoredAuthToken() => _baseApi.getStoredAuthToken();
  Future<void> setAuthTokens(models.AuthToken authToken) => _baseApi.setAuthTokens(authToken);
  Future<void> clearAuthTokens() => _baseApi.clearAuthTokens();
  Future<models.ApiResponse<models.AuthToken>> refreshAccessToken() => _baseApi.refreshAccessToken();

  /// API 서비스 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;

    print('🚀 API 서비스 초기화 시작...');

    // 기본 HTTP 클라이언트 초기화
    await _baseApi.initialize();
    print('✅ BaseApiService 초기화 완료');

    // 각 도메인 서비스 초기화
    auth = AuthApiService();
    print('✅ AuthApiService 초기화 완료');
    
    user = UserApiService();
    print('✅ UserApiService 초기화 완료');

    alarm = AlarmApiService();
    print('✅ AlarmApiService 초기화 완료');

    callLog = CallLogApiService();
    print('✅ CallLogApiService 초기화 완료');

    callManagement = CallManagementApiService();
    print('✅ CallManagementApiService 초기화 완료');

    realtime = RealtimeApiService();
    print('✅ RealtimeApiService 초기화 완료');

    points = PointsApiService();
    print('✅ PointsApiService 초기화 완료');
    
    mission = MissionApiService();
    print('✅ MissionApiService 초기화 완료');
    
    missionResults = MissionResultsApiService();
    print('✅ MissionResultsApiService 초기화 완료');
    
    statistics = StatisticsApiService();
    print('✅ StatisticsApiService 초기화 완료');

    _isInitialized = true;
    print('🎉 모든 API 서비스 초기화 완료!');
  }

  /// 초기화 상태 확인
  bool get isInitialized => _isInitialized;

  /// 인증 토큰 설정 (모든 서비스에서 공통 사용)
  void setAuthToken(String accessToken, String refreshToken) {
    _baseApi.setAccessToken(accessToken);
    _baseApi.setRefreshToken(refreshToken);
  }


  /// 리소스 정리
  void dispose() {
    _baseApi.dispose();
    _isInitialized = false;
  }

  /// 헬퍼 메서드들

  /// 완전한 사용자 대시보드 데이터 조회
  Future<Map<String, dynamic>> getDashboardData() async {
    try {
      final results = await Future.wait([
        user.getMyInfo(),
        points.getPointSummary(),
        statistics.getOverview(),
        statistics.getTodayStatistics(),
        callLog.getRecentCallLogs(limit: 5),
        missionResults.getRecentMissionResults(limit: 5),
      ]);

      return {
        'user': results[0].data,
        'pointSummary': results[1].data,
        'overview': results[2].data,
        'todayStats': results[3].data,
        'recentCallLogs': results[4].data,
        'recentMissions': results[5].data,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw Exception('대시보드 데이터 로드 실패: $e');
    }
  }

  /// 주간 요약 데이터 조회
  Future<Map<String, dynamic>> getWeeklySummary() async {
    try {
      final results = await Future.wait([
        statistics.getWeeklyStatistics(),
        statistics.getWeeklyComparison(),
        points.getPointTransactionByDateRange(
          DateTime.now().subtract(const Duration(days: 7)),
          DateTime.now(),
        ),
      ]);

      return {
        'weeklyStats': results[0].data,
        'comparison': results[1].data,
        'pointTransaction': results[2].data,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw Exception('주간 요약 데이터 로드 실패: $e');
    }
  }

  /// 월간 요약 데이터 조회
  Future<Map<String, dynamic>> getMonthlySummary() async {
    try {
      final results = await Future.wait([
        statistics.getMonthlyStatistics(),
        statistics.getMonthlyComparison(),
        statistics.getThisMonthCalendar(),
        points.getPointTransactionByDateRange(
          DateTime.now().subtract(const Duration(days: 30)),
          DateTime.now(),
        ),
      ]);

      return {
        'monthlyStats': results[0].data,
        'comparison': results[1].data,
        'calendar': results[2].data,
        'pointHistory': results[3].data,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw Exception('월간 요약 데이터 로드 실패: $e');
    }
  }

  /// 알람 완료 후 전체 처리
  Future<Map<String, dynamic>> completeAlarmSession({
    required String alarmId,
    required String alarmTitle,
    required DateTime startTime,
    required DateTime endTime,
    required bool isSuccessful,
    String? transcript,
    Map<String, dynamic>? missionResults,
  }) async {
    try {
      // 1. 통화 기록 저장 (Swagger 스키마 적용)
      final callLogResult = await callLog.createCallLog(
        callStart: startTime,
        callEnd: endTime,
        result: isSuccessful ? 'SUCCESS' : 'FAIL_NO_TALK',
        snoozeCount: 0,
      );

      // 2. 성공 시 포인트 획득
      final pointResults = <dynamic>[];
      if (isSuccessful) {
        final pointResult = await points.earnPointsForAlarmSuccess(
          alarmId: alarmId,
        );
        pointResults.add(pointResult.data);
      }

      // 3. 미션 결과 저장 (있는 경우)
      final missionResultData = <dynamic>[];
      if (missionResults != null) {
        for (final entry in missionResults.entries) {
          final missionType = entry.key;
          final result = entry.value as Map<String, dynamic>;
          
          final missionResult = await this.missionResults.createMissionResult(
            callLogId: callLogResult.data!.id,
            missionType: missionType,
            success: result['isCompleted'] ?? false,
            score: result['score'] ?? 0,
            metadata: result,
          );
          
          missionResultData.add(missionResult.data);
          
          // 미션 완료 시 추가 포인트
          if (result['isCompleted'] == true) {
            final missionPointResult = await points.earnPointsForMissionComplete(
              missionId: missionResult.data!['id'].toString(),
              missionType: models.MissionType.values.firstWhere(
                (e) => e.name == missionType,
                orElse: () => models.MissionType.MATH,
              ),
              score: result['score'] ?? 0,
            );
            pointResults.add(missionPointResult.data);
          }
        }
      }

      return {
        'callLog': callLogResult.data,
        'pointsEarned': pointResults,
        'missionResults': missionResultData,
        'totalPointsEarned': pointResults.fold<int>(
          0,
          (sum, point) => sum + ((point?.amount ?? 0) as int),
        ),
        'success': true,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw Exception('알람 세션 완료 처리 실패: $e');
    }
  }

  /// 사용자 프로필 완전 업데이트
  Future<Map<String, dynamic>> updateUserProfile({
    String? nickname,
    String? currentPassword,
    String? newPassword,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final results = <String, dynamic>{};

      // 닉네임 변경
      if (nickname != null) {
        final nicknameResult = await user.changeNickname(
          models.NicknameChangeRequest(newNickname: nickname),
        );
        results['nickname'] = nicknameResult.data;
      }

      // 비밀번호 변경
      if (currentPassword != null && newPassword != null) {
        final passwordResult = await user.changePassword(
          models.PasswordChangeRequest(
            currentPassword: currentPassword,
            newPassword: newPassword,
            confirmPassword: newPassword, // 일반적으로 같은 값
          ),
        );
        results['passwordChanged'] = passwordResult.success;
      }

      // 추가 정보 업데이트
      if (additionalData != null) {
        final updateResult = await user.updateMyInfo(additionalData);
        results['additionalData'] = updateResult.data;
      }

      // 최종 사용자 정보 조회
      final finalUserInfo = await user.getMyInfo();
      results['user'] = finalUserInfo.data;

      return results;
    } catch (e) {
      throw Exception('사용자 프로필 업데이트 실패: $e');
    }
  }

  /// 서버 연결 상태 확인
  Future<Map<String, dynamic>> checkServerConnection() async {
    try {
      final startTime = DateTime.now();
      
      // Health check 엔드포인트 호출 (간단한 GET 요청)
      final response = await _baseApi.get<Map<String, dynamic>>('/health');
      
      final endTime = DateTime.now();
      final responseTime = endTime.difference(startTime).inMilliseconds;
      
      return {
        'isConnected': response.success,
        'responseTime': responseTime,
        'serverUrl': EnvironmentConfig.baseUrl,
        'timestamp': DateTime.now().toIso8601String(),
        'status': response.success ? 'healthy' : 'error',
        'message': response.success ? '서버 연결 정상' : '서버 연결 실패',
        'data': response.data,
      };
    } catch (e) {
      return {
        'isConnected': false,
        'responseTime': -1,
        'serverUrl': EnvironmentConfig.baseUrl,
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'error',
        'message': '서버 연결 실패: $e',
        'error': e.toString(),
      };
    }
  }

  /// 앱 초기화 시 필요한 모든 데이터 로드
  Future<Map<String, dynamic>> initializeAppData() async {
    try {
      // 먼저 서버 연결 확인
      final connectionCheck = await checkServerConnection();
      
      if (!connectionCheck['isConnected']) {
        return {
          'isInitialized': false,
          'connectionStatus': connectionCheck,
          'error': '서버 연결 실패',
          'timestamp': DateTime.now().toIso8601String(),
        };
      }
      
      if (!isAuthenticated) {
        return {
          'isInitialized': false,
          'connectionStatus': connectionCheck,
          'error': '인증되지 않은 사용자',
          'timestamp': DateTime.now().toIso8601String(),
        };
      }

      final results = await Future.wait([
        user.getMyInfo(),
        points.getPointSummary(),
        statistics.getOverview(),
        callLog.getRecentCallLogs(limit: 10),
      ]);

      return {
        'user': results[0].data,
        'pointSummary': results[1].data,
        'overview': results[2].data,
        'recentCallLogs': results[3].data,
        'connectionStatus': connectionCheck,
        'isInitialized': true,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw Exception('앱 초기화 데이터 로드 실패: $e');
    }
  }
}
