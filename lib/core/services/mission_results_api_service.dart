import '../models/api_models.dart';
import 'base_api_service.dart';

/// 미션 결과 관련 API 서비스
/// 미션 완료 결과 저장 및 조회 API 호출 담당
class MissionResultsApiService {
  static final MissionResultsApiService _instance = MissionResultsApiService._internal();
  factory MissionResultsApiService() => _instance;
  MissionResultsApiService._internal();

  final BaseApiService _baseApi = BaseApiService();

  /// 미션 결과 저장 (간소화)
  /// POST /api/mission-results
  Future<ApiResponse<Map<String, dynamic>>> createMissionResult({
    required String callLogId,
    required String missionType,
    required bool success,
    int? score,
    int? timeSpent,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final body = {
        'callLogId': callLogId,
        'missionType': missionType,
        'success': success,
      };

      if (score != null) body['score'] = score;
      if (timeSpent != null) body['timeSpent'] = timeSpent;
      if (metadata != null) body['metadata'] = metadata;

      return await _baseApi.post<Map<String, dynamic>>(
        '/api/mission-results',
        body: body,
        fromJson: (json) => json as Map<String, dynamic>,
      );
    } catch (e) {
      // 실제 API가 없는 경우 더미 데이터 반환
      return ApiResponse.success({
        'id': DateTime.now().millisecondsSinceEpoch,
        'callLogId': callLogId,
        'missionType': missionType,
        'success': success,
        'score': score,
        'timeSpent': timeSpent,
        'createdAt': DateTime.now().toIso8601String(),
      });
    }
  }

  /// 미션 결과 조회 (통화 기록 ID로)
  /// GET /api/mission-results?callLogId={callLogId}
  Future<ApiResponse<List<MissionResult>>> getMissionResultsByCallLog(String callLogId) async {
    try {
      return await _baseApi.get<List<MissionResult>>(
        '/api/mission-results',
        queryParameters: {'callLogId': callLogId},
        fromJson: (json) {
          final List<dynamic> results = json['data'] ?? [];
          return results
              .map((item) => MissionResult.fromJson(item as Map<String, dynamic>))
              .toList();
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 미션 결과 조회 (사용자별)
  /// GET /api/mission-results/user
  Future<ApiResponse<List<MissionResult>>> getUserMissionResults({
    int? limit,
    int? offset,
    MissionType? missionType,
    DateTime? startDate,
    DateTime? endDate,
    bool? successOnly,
  }) async {
    try {
      final queryParams = <String, String>{};
      
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();
      if (missionType != null) queryParams['missionType'] = missionType.name;
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String().split('T')[0];
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String().split('T')[0];
      if (successOnly != null) queryParams['success'] = successOnly.toString();

      return await _baseApi.get<List<MissionResult>>(
        '/api/mission-results/user',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        fromJson: (json) {
          final List<dynamic> results = json['data'] ?? [];
          return results
              .map((item) => MissionResult.fromJson(item as Map<String, dynamic>))
              .toList();
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 미션 통계 조회
  /// GET /api/mission-results/stats
  Future<ApiResponse<Map<String, dynamic>>> getMissionStats({
    DateTime? startDate,
    DateTime? endDate,
    MissionType? missionType,
  }) async {
    try {
      final queryParams = <String, String>{};
      
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String().split('T')[0];
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String().split('T')[0];
      if (missionType != null) queryParams['missionType'] = missionType.name;

      return await _baseApi.get<Map<String, dynamic>>(
        '/api/mission-results/stats',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        fromJson: (json) => json as Map<String, dynamic>,
      );
    } catch (e) {
      // API가 구현되지 않은 경우 더미 데이터 계산
      try {
        final resultsResponse = await getUserMissionResults(
          startDate: startDate,
          endDate: endDate,
          missionType: missionType,
        );

        if (resultsResponse.success && resultsResponse.data != null) {
          final results = resultsResponse.data!;
          final totalMissions = results.length;
          final successfulMissions = results.where((r) => r.isCompleted).length;
          final failedMissions = totalMissions - successfulMissions;
          final successRate = totalMissions > 0 ? (successfulMissions / totalMissions * 100) : 0.0;

          // 미션 타입별 통계
          final missionTypeStats = <String, Map<String, dynamic>>{};
          for (final missionType in MissionType.values) {
            final typeMissions = results.where((r) => r.missionType == missionType).toList();
            final typeTotal = typeMissions.length;
            final typeSuccess = typeMissions.where((r) => r.isCompleted).length;
            
            if (typeTotal > 0) {
              missionTypeStats[missionType.name] = {
                'total': typeTotal,
                'successful': typeSuccess,
                'failed': typeTotal - typeSuccess,
                'successRate': (typeSuccess / typeTotal * 100),
                'averageScore': typeMissions
                    .where((r) => r.score != null)
                    .map((r) => r.score!)
                    .fold<double>(0, (sum, score) => sum + score) / 
                    (typeMissions.where((r) => r.score != null).length > 0 
                        ? typeMissions.where((r) => r.score != null).length 
                        : 1),
              };
            }
          }

          return ApiResponse.success({
            'totalMissions': totalMissions,
            'successfulMissions': successfulMissions,
            'failedMissions': failedMissions,
            'successRate': successRate,
            'missionTypeStats': missionTypeStats,
          });
        }

        return ApiResponse.error('미션 통계 계산 실패');
      } catch (e) {
        return ApiResponse.error('미션 통계 조회 오류: $e');
      }
    }
  }

  /// 특정 미션 타입의 최고 점수 조회
  Future<ApiResponse<MissionResult?>> getBestScoreForMissionType(MissionType missionType) async {
    try {
      final resultsResponse = await getUserMissionResults(
        missionType: missionType,
        successOnly: true,
      );

      if (resultsResponse.success && resultsResponse.data != null) {
        final results = resultsResponse.data!;
        final resultsWithScore = results.where((r) => r.score != null).toList();
        
        if (resultsWithScore.isEmpty) {
          return ApiResponse.success(null);
        }

        resultsWithScore.sort((a, b) => b.score!.compareTo(a.score!));
        return ApiResponse.success(resultsWithScore.first);
      }

      return ApiResponse.error('최고 점수 조회 실패');
    } catch (e) {
      return ApiResponse.error('최고 점수 조회 오류: $e');
    }
  }

  /// 최근 미션 결과 조회
  Future<ApiResponse<List<MissionResult>>> getRecentMissionResults({int limit = 10}) async {
    return getUserMissionResults(limit: limit, offset: 0);
  }

  /// 성공한 미션만 조회
  Future<ApiResponse<List<MissionResult>>> getSuccessfulMissions({
    int? limit,
    int? offset,
    MissionType? missionType,
  }) async {
    return getUserMissionResults(
      limit: limit,
      offset: offset,
      missionType: missionType,
      successOnly: true,
    );
  }

  /// 실패한 미션만 조회
  Future<ApiResponse<List<MissionResult>>> getFailedMissions({
    int? limit,
    int? offset,
    MissionType? missionType,
  }) async {
    return getUserMissionResults(
      limit: limit,
      offset: offset,
      missionType: missionType,
      successOnly: false,
    );
  }

  /// 미션 결과 업데이트
  /// PUT /api/mission-results/{id}
  Future<ApiResponse<MissionResult>> updateMissionResult(
    String missionResultId, {
    bool? success,
    int? score,
    int? timeSpent,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final body = <String, dynamic>{};

      if (success != null) body['success'] = success;
      if (score != null) body['score'] = score;
      if (timeSpent != null) body['timeSpent'] = timeSpent;
      if (metadata != null) body['metadata'] = metadata;

      return await _baseApi.put<MissionResult>(
        '/api/mission-results/$missionResultId',
        body: body,
        fromJson: (json) => MissionResult.fromJson(json),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 미션 결과 삭제
  /// DELETE /api/mission-results/{id}
  Future<ApiResponse<void>> deleteMissionResult(String missionResultId) async {
    try {
      return await _baseApi.delete<void>('/api/mission-results/$missionResultId');
    } catch (e) {
      rethrow;
    }
  }

  /// 월별 미션 통계
  Future<ApiResponse<Map<String, dynamic>>> getMonthlyMissionStats({
    int? year,
    int? month,
  }) async {
    final now = DateTime.now();
    final targetYear = year ?? now.year;
    final targetMonth = month ?? now.month;
    
    final startDate = DateTime(targetYear, targetMonth, 1);
    final endDate = DateTime(targetYear, targetMonth + 1, 1).subtract(const Duration(days: 1));

    final statsResponse = await getMissionStats(
      startDate: startDate,
      endDate: endDate,
    );

    if (statsResponse.success && statsResponse.data != null) {
      final stats = Map<String, dynamic>.from(statsResponse.data!);
      stats['year'] = targetYear;
      stats['month'] = targetMonth;
      return ApiResponse.success(stats);
    }

    return statsResponse;
  }
}
