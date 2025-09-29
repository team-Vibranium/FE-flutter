import '../models/api_models.dart';
import 'base_api_service.dart';

/// 전화 알람 API 서비스
/// API 명세서의 알람 관리 섹션을 구현
class AlarmApiService {
  static final AlarmApiService _instance = AlarmApiService._internal();
  factory AlarmApiService() => _instance;
  AlarmApiService._internal();

  final BaseApiService _baseApi = BaseApiService();

  /// 알람 등록
  /// POST /api/alarms
  Future<ApiResponse<PhoneAlarm>> createAlarm(CreateAlarmRequest request) async {
    try {
      return await _baseApi.post<PhoneAlarm>(
        '/api/alarms',
        body: request.toJson(),
        fromJson: (json) => PhoneAlarm.fromJson(json),
      );
    } catch (e) {
      return ApiResponse.error('알람 생성 중 오류가 발생했습니다: $e');
    }
  }

  /// 사용자 알람 목록 조회
  /// GET /api/alarms?activeOnly={activeOnly}
  Future<ApiResponse<List<PhoneAlarm>>> getAlarms({bool activeOnly = true}) async {
    try {
      return await _baseApi.get<List<PhoneAlarm>>(
        '/api/alarms',
        queryParameters: {'activeOnly': activeOnly.toString()},
        fromJson: (json) => (json as List)
            .map((item) => PhoneAlarm.fromJson(item))
            .toList(),
      );
    } catch (e) {
      return ApiResponse.error('알람 목록 조회 중 오류가 발생했습니다: $e');
    }
  }

  /// 특정 알람 조회
  /// GET /api/alarms/{alarmId}
  Future<ApiResponse<PhoneAlarm>> getAlarm(int alarmId) async {
    try {
      return await _baseApi.get<PhoneAlarm>(
        '/api/alarms/$alarmId',
        fromJson: (json) => PhoneAlarm.fromJson(json),
      );
    } catch (e) {
      return ApiResponse.error('알람 조회 중 오류가 발생했습니다: $e');
    }
  }

  /// 알람 수정
  /// PUT /api/alarms/{alarmId}
  Future<ApiResponse<PhoneAlarm>> updateAlarm(
    int alarmId,
    UpdateAlarmRequest request,
  ) async {
    try {
      return await _baseApi.put<PhoneAlarm>(
        '/api/alarms/$alarmId',
        body: request.toJson(),
        fromJson: (json) => PhoneAlarm.fromJson(json),
      );
    } catch (e) {
      return ApiResponse.error('알람 수정 중 오류가 발생했습니다: $e');
    }
  }

  /// 알람 삭제 (비활성화 처리)
  /// DELETE /api/alarms/{alarmId}
  Future<ApiResponse<String>> deleteAlarm(int alarmId) async {
    try {
      return await _baseApi.delete<String>(
        '/api/alarms/$alarmId',
        fromJson: (json) => json['message'] as String,
      );
    } catch (e) {
      return ApiResponse.error('알람 삭제 중 오류가 발생했습니다: $e');
    }
  }
}