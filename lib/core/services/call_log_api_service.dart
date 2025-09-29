import '../models/api_models.dart';
import 'base_api_service.dart';

/// 통화 기록 관련 API 서비스
/// 알람 통화 기록 생성 및 조회 API 호출 담당
class CallLogApiService {
  static final CallLogApiService _instance = CallLogApiService._internal();
  factory CallLogApiService() => _instance;
  CallLogApiService._internal();

  final BaseApiService _baseApi = BaseApiService();

  /// 통화 기록 조회
  /// GET /api/call-logs
  Future<ApiResponse<List<CallLog>>> getCallLogs({
    int? limit,
    int? offset,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, String>{};
      
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();

      return await _baseApi.get<List<CallLog>>(
        '/api/call-logs',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        fromJson: (json) {
          final List<dynamic> callLogsList = json['callLogs'] ?? json['data'] ?? [];
          return callLogsList
              .map((item) => CallLog.fromJson(item as Map<String, dynamic>))
              .toList();
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 특정 통화 기록 조회
  /// GET /api/call-logs/{id}
  Future<ApiResponse<CallLog>> getCallLog(String callLogId) async {
    try {
      return await _baseApi.get<CallLog>(
        '/api/call-logs/$callLogId',
        fromJson: (json) => CallLog.fromJson(json),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 통화 기록 생성
  /// POST /api/call-logs
  Future<ApiResponse<CallLog>> createCallLog({
    required String alarmTitle,
    required DateTime startTime,
    DateTime? endTime,
    int duration = 0,
    bool isSuccessful = false,
    String? transcript,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final body = {
        'alarmTitle': alarmTitle,
        'startTime': startTime.toIso8601String(),
        'duration': duration,
        'isSuccessful': isSuccessful,
      };

      if (endTime != null) {
        body['endTime'] = endTime.toIso8601String();
      }
      if (transcript != null) {
        body['transcript'] = transcript;
      }
      if (metadata != null) {
        body['metadata'] = metadata;
      }

      return await _baseApi.post<CallLog>(
        '/api/call-logs',
        body: body,
        fromJson: (json) => CallLog.fromJson(json),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 통화 기록 업데이트
  /// PUT /api/call-logs/{id}
  Future<ApiResponse<CallLog>> updateCallLog(
    String callLogId, {
    DateTime? endTime,
    int? duration,
    bool? isSuccessful,
    String? transcript,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final body = <String, dynamic>{};

      if (endTime != null) body['endTime'] = endTime.toIso8601String();
      if (duration != null) body['duration'] = duration;
      if (isSuccessful != null) body['isSuccessful'] = isSuccessful;
      if (transcript != null) body['transcript'] = transcript;
      if (metadata != null) body['metadata'] = metadata;

      return await _baseApi.put<CallLog>(
        '/api/call-logs/$callLogId',
        body: body,
        fromJson: (json) => CallLog.fromJson(json),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 통화 기록 삭제
  /// DELETE /api/call-logs/{id}
  Future<ApiResponse<void>> deleteCallLog(String callLogId) async {
    try {
      return await _baseApi.delete<void>('/api/call-logs/$callLogId');
    } catch (e) {
      rethrow;
    }
  }

  /// 최근 통화 기록 조회
  Future<ApiResponse<List<CallLog>>> getRecentCallLogs({int limit = 10}) async {
    return getCallLogs(limit: limit, offset: 0);
  }

  /// 성공한 통화 기록만 조회
  Future<ApiResponse<List<CallLog>>> getSuccessfulCallLogs({
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, String>{
        'isSuccessful': 'true',
      };
      
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();

      return await _baseApi.get<List<CallLog>>(
        '/api/call-logs',
        queryParameters: queryParams,
        fromJson: (json) {
          final List<dynamic> callLogsList = json['callLogs'] ?? json['data'] ?? [];
          return callLogsList
              .map((item) => CallLog.fromJson(item as Map<String, dynamic>))
              .toList();
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 특정 기간의 통화 기록 조회
  Future<ApiResponse<List<CallLog>>> getCallLogsByDateRange(
    DateTime startDate,
    DateTime endDate, {
    int? limit,
    int? offset,
  }) async {
    return getCallLogs(
      startDate: startDate,
      endDate: endDate,
      limit: limit,
      offset: offset,
    );
  }

  /// 페이지네이션을 지원하는 통화 기록 조회
  /// GET /api/call-logs (with pagination metadata)
  Future<ApiResponse<Map<String, dynamic>>> getCallLogsByPage({
    int limit = 20,
    int offset = 0,
    DateTime? startDate,
    DateTime? endDate,
    String? result, // SUCCESS, FAIL_NO_TALK, FAIL_TIMEOUT 등
    bool? isSuccessful,
  }) async {
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
        'offset': offset.toString(),
      };
      
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String().split('T')[0];
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String().split('T')[0];
      if (result != null) queryParams['result'] = result;
      if (isSuccessful != null) queryParams['isSuccessful'] = isSuccessful.toString();

      return await _baseApi.get<Map<String, dynamic>>(
        '/api/call-logs',
        queryParameters: queryParams,
        fromJson: (json) {
          final List<dynamic> callLogs = json['callLogs'] ?? json['data'] ?? [];
          final callLogList = callLogs
              .map((item) => CallLog.fromJson(item as Map<String, dynamic>))
              .toList();

          return {
            'callLogs': callLogList,
            'totalCount': json['totalCount'] ?? callLogList.length,
            'hasMore': json['hasMore'] ?? false,
            'limit': json['limit'] ?? limit,
            'offset': json['offset'] ?? offset,
          };
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 통화 기록 통계 조회
  Future<ApiResponse<Map<String, dynamic>>> getCallLogStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, String>{};
      
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String().split('T')[0];
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String().split('T')[0];

      return await _baseApi.get<Map<String, dynamic>>(
        '/api/call-logs/stats',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        fromJson: (json) => json as Map<String, dynamic>,
      );
    } catch (e) {
      // API가 아직 구현되지 않은 경우 더미 데이터 반환
      final callLogsResponse = await getCallLogs(
        startDate: startDate,
        endDate: endDate,
      );
      
      if (callLogsResponse.success && callLogsResponse.data != null) {
        final callLogs = callLogsResponse.data!;
        final totalCalls = callLogs.length;
        final successfulCalls = callLogs.where((log) => log.isSuccessful).length;
        final failedCalls = totalCalls - successfulCalls;
        final successRate = totalCalls > 0 ? (successfulCalls / totalCalls * 100) : 0.0;
        
        final totalDuration = callLogs
            .where((log) => log.duration > 0)
            .fold<int>(0, (sum, log) => sum + log.duration);
        final averageDuration = totalCalls > 0 ? totalDuration / totalCalls : 0.0;

        return ApiResponse.success({
          'totalCalls': totalCalls,
          'successfulCalls': successfulCalls,
          'failedCalls': failedCalls,
          'successRate': successRate,
          'totalDuration': totalDuration,
          'averageDuration': averageDuration,
        });
      }
      
      return ApiResponse.error('통화 기록 통계 조회 실패: $e');
    }
  }

  /// 월별 통화 기록 통계
  Future<ApiResponse<Map<String, dynamic>>> getMonthlyCallLogStats({
    int? year,
    int? month,
  }) async {
    final now = DateTime.now();
    final targetYear = year ?? now.year;
    final targetMonth = month ?? now.month;
    
    final startDate = DateTime(targetYear, targetMonth, 1);
    final endDate = DateTime(targetYear, targetMonth + 1, 1).subtract(const Duration(days: 1));

    final statsResponse = await getCallLogStats(
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

  /// 통화 기록 검색
  Future<ApiResponse<List<CallLog>>> searchCallLogs({
    String? query,
    DateTime? startDate,
    DateTime? endDate,
    bool? isSuccessful,
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, String>{};
      
      if (query != null && query.isNotEmpty) queryParams['q'] = query;
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String().split('T')[0];
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String().split('T')[0];
      if (isSuccessful != null) queryParams['isSuccessful'] = isSuccessful.toString();
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();

      return await _baseApi.get<List<CallLog>>(
        '/api/call-logs/search',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        fromJson: (json) {
          final List<dynamic> callLogsList = json['callLogs'] ?? json['data'] ?? [];
          return callLogsList
              .map((item) => CallLog.fromJson(item as Map<String, dynamic>))
              .toList();
        },
      );
    } catch (e) {
      // 검색 API가 구현되지 않은 경우 기본 조회로 대체
      return getCallLogs(
        startDate: startDate,
        endDate: endDate,
        limit: limit,
        offset: offset,
      );
    }
  }
}
