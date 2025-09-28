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
}
