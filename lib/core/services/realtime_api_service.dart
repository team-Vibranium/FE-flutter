import '../models/api_models.dart';
import 'base_api_service.dart';

/// OpenAI Realtime API 서비스
/// /api/realtime/* 엔드포인트들을 관리
class RealtimeApiService {
  static final RealtimeApiService _instance = RealtimeApiService._internal();
  factory RealtimeApiService() => _instance;
  RealtimeApiService._internal();

  final BaseApiService _baseApi = BaseApiService();

  /// OpenAI Realtime API 세션 생성
  /// POST /api/realtime/session
  Future<ApiResponse<SessionResponse>> createSession({
    required int alarmId,
    int? snoozeCount,
  }) async {
    try {
      final queryParams = <String>['alarmId=$alarmId'];
      if (snoozeCount != null) {
        queryParams.add('snoozeCount=$snoozeCount');
      }
      final queryString = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';

      return await _baseApi.post<SessionResponse>(
        '/api/realtime/session$queryString',
        fromJson: (json) => SessionResponse.fromJson(json),
      );
    } catch (e) {
      return ApiResponse.error('세션 생성 중 오류가 발생했습니다: $e');
    }
  }
}