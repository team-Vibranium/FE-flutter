import '../models/api_models.dart';
import 'base_api_service.dart';

/// 통화 관리 API 서비스
/// /api/calls/* 엔드포인트들을 관리
class CallManagementApiService {
  static final CallManagementApiService _instance = CallManagementApiService._internal();
  factory CallManagementApiService() => _instance;
  CallManagementApiService._internal();

  final BaseApiService _baseApi = BaseApiService();

  /// 통화 시작
  /// POST /api/calls/start
  Future<ApiResponse<CallStartResponse>> startCall(CallStartRequest request) async {
    try {
      return await _baseApi.post<CallStartResponse>(
        '/api/calls/start',
        body: request.toJson(),
        fromJson: (json) => CallStartResponse.fromJson(json),
      );
    } catch (e) {
      return ApiResponse.error('통화 시작 중 오류가 발생했습니다: $e');
    }
  }

  /// 통화 종료
  /// POST /api/calls/{callId}/end
  Future<ApiResponse<void>> endCall(int callId, CallEndRequest request) async {
    try {
      return await _baseApi.post<void>(
        '/api/calls/$callId/end',
        body: request.toJson(),
      );
    } catch (e) {
      return ApiResponse.error('통화 종료 중 오류가 발생했습니다: $e');
    }
  }

  /// 대화 내용 저장
  /// POST /api/calls/{callId}/transcript
  Future<ApiResponse<void>> saveTranscript(int callId, TranscriptRequest request) async {
    try {
      return await _baseApi.post<void>(
        '/api/calls/$callId/transcript',
        body: request.toJson(),
      );
    } catch (e) {
      return ApiResponse.error('대화 내용 저장 중 오류가 발생했습니다: $e');
    }
  }

  /// 통화 조회
  /// GET /api/calls/{callId}
  Future<ApiResponse<CallDetailResponse>> getCall(int callId) async {
    try {
      return await _baseApi.get<CallDetailResponse>(
        '/api/calls/$callId',
        fromJson: (json) => CallDetailResponse.fromJson(json),
      );
    } catch (e) {
      return ApiResponse.error('통화 정보 조회 중 오류가 발생했습니다: $e');
    }
  }

  /// 통화 스누즈
  /// POST /api/calls/{callId}/snooze
  Future<ApiResponse<SnoozeResponse>> snoozeCall(int callId) async {
    try {
      return await _baseApi.post<SnoozeResponse>(
        '/api/calls/$callId/snooze',
        fromJson: (json) => SnoozeResponse.fromJson(json),
      );
    } catch (e) {
      return ApiResponse.error('스누즈 처리 중 오류가 발생했습니다: $e');
    }
  }
}
