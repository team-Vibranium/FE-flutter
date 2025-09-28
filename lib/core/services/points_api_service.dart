import '../models/api_models.dart';
import 'base_api_service.dart';

/// 포인트 시스템 관련 API 서비스
/// 포인트 조회, 획득, 사용 관련 API 호출 담당
class PointsApiService {
  static final PointsApiService _instance = PointsApiService._internal();
  factory PointsApiService() => _instance;
  PointsApiService._internal();

  final BaseApiService _baseApi = BaseApiService();

  /// 포인트 현황 조회
  /// GET /api/points/summary
  Future<ApiResponse<PointSummary>> getPointSummary() async {
    try {
      return await _baseApi.get<PointSummary>(
        '/api/points/summary',
        fromJson: (json) => PointSummary.fromJson(json),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 포인트 내역 조회
  /// GET /api/points/history
  Future<ApiResponse<List<PointHistory>>> getPointHistory({
    int? limit,
    int? offset,
    PointTransactionType? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, String>{};
      
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();
      if (type != null) queryParams['type'] = type.name;
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();

      return await _baseApi.get<List<PointHistory>>(
        '/api/points/history',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        fromJson: (json) {
          final List<dynamic> historyList = json['history'] ?? json['data'] ?? [];
          return historyList
              .map((item) => PointHistory.fromJson(item as Map<String, dynamic>))
              .toList();
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 포인트 사용
  /// POST /api/points/spend
  Future<ApiResponse<PointHistory>> spendPoints(SpendPointsRequest request) async {
    try {
      return await _baseApi.post<PointHistory>(
        '/api/points/spend',
        body: request.toJson(),
        fromJson: (json) => PointHistory.fromJson(json),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 포인트 획득
  /// POST /api/points/earn
  Future<ApiResponse<PointHistory>> earnPoints(EarnPointsRequest request) async {
    try {
      return await _baseApi.post<PointHistory>(
        '/api/points/earn',
        body: request.toJson(),
        fromJson: (json) => PointHistory.fromJson(json),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 알람 성공으로 포인트 획득
  Future<ApiResponse<PointHistory>> earnPointsForAlarmSuccess({
    required String alarmId,
    int points = 10,
  }) async {
    return earnPoints(EarnPointsRequest(
      amount: points,
      description: '알람 성공',
      metadata: {'alarmId': alarmId, 'reason': 'alarm_success'},
    ));
  }

  /// 미션 완료로 포인트 획득
  Future<ApiResponse<PointHistory>> earnPointsForMissionComplete({
    required String missionId,
    required MissionType missionType,
    required int score,
    int basePoints = 5,
  }) async {
    // 점수에 따른 보너스 포인트 계산
    final bonusPoints = (score / 10).floor();
    final totalPoints = basePoints + bonusPoints;

    return earnPoints(EarnPointsRequest(
      amount: totalPoints,
      description: '미션 완료 (${missionType.name})',
      metadata: {
        'missionId': missionId,
        'missionType': missionType.name,
        'score': score,
        'basePoints': basePoints,
        'bonusPoints': bonusPoints,
        'reason': 'mission_complete',
      },
    ));
  }

  /// 연속 알람 성공으로 포인트 획득
  Future<ApiResponse<PointHistory>> earnPointsForStreakBonus({
    required int streakDays,
    int basePoints = 20,
  }) async {
    // 연속 일수에 따른 보너스 계산
    final bonusPoints = (streakDays / 7).floor() * 10;
    final totalPoints = basePoints + bonusPoints;

    return earnPoints(EarnPointsRequest(
      amount: totalPoints,
      description: '$streakDays일 연속 성공 보너스',
      metadata: {
        'streakDays': streakDays,
        'basePoints': basePoints,
        'bonusPoints': bonusPoints,
        'reason': 'streak_bonus',
      },
    ));
  }

  /// 스킨 구매로 포인트 사용
  Future<ApiResponse<PointHistory>> spendPointsForSkin({
    required String skinId,
    required int price,
  }) async {
    return spendPoints(SpendPointsRequest(
      amount: price,
      description: '스킨 구매',
      metadata: {'skinId': skinId, 'reason': 'skin_purchase'},
    ));
  }

  /// 부가 기능 구매로 포인트 사용
  Future<ApiResponse<PointHistory>> spendPointsForFeature({
    required String featureId,
    required int price,
  }) async {
    return spendPoints(SpendPointsRequest(
      amount: price,
      description: '부가 기능 구매',
      metadata: {'featureId': featureId, 'reason': 'feature_purchase'},
    ));
  }

  /// 최근 포인트 내역 조회
  Future<ApiResponse<List<PointHistory>>> getRecentPointHistory({int limit = 20}) async {
    return getPointHistory(limit: limit, offset: 0);
  }

  /// 획득한 포인트 내역만 조회
  Future<ApiResponse<List<PointHistory>>> getEarnedPointHistory({
    int? limit,
    int? offset,
  }) async {
    return getPointHistory(
      type: PointTransactionType.earned,
      limit: limit,
      offset: offset,
    );
  }

  /// 사용한 포인트 내역만 조회
  Future<ApiResponse<List<PointHistory>>> getSpentPointHistory({
    int? limit,
    int? offset,
  }) async {
    return getPointHistory(
      type: PointTransactionType.spent,
      limit: limit,
      offset: offset,
    );
  }

  /// 특정 기간의 포인트 내역 조회
  Future<ApiResponse<List<PointHistory>>> getPointHistoryByDateRange(
    DateTime startDate,
    DateTime endDate, {
    int? limit,
    int? offset,
    PointTransactionType? type,
  }) async {
    return getPointHistory(
      startDate: startDate,
      endDate: endDate,
      type: type,
      limit: limit,
      offset: offset,
    );
  }
}
