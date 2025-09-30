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
  Future<ApiResponse<List<PointTransaction>>> getPointTransaction({
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
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String().split('T')[0];
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String().split('T')[0];

      return await _baseApi.get<List<PointTransaction>>(
        '/api/points/history',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        fromJson: (json) {
          final List<dynamic> historyList = json['history'] ?? json['data'] ?? [];
          return historyList
              .map((item) => PointTransaction.fromJson(item as Map<String, dynamic>))
              .toList();
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 포인트 사용
  /// POST /api/points/spend
  Future<ApiResponse<PointTransaction>> spendPoints(SpendPointsRequest request) async {
    try {
      return await _baseApi.post<PointTransaction>(
        '/api/points/spend',
        body: request.toJson(),
        fromJson: (json) => PointTransaction.fromJson(json),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 포인트 획득
  /// POST /api/points/earn
  Future<ApiResponse<PointTransaction>> earnPoints(EarnPointsRequest request) async {
    try {
      return await _baseApi.post<PointTransaction>(
        '/api/points/earn',
        body: request.toJson(),
        fromJson: (json) => PointTransaction.fromJson(json),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 알람 성공으로 포인트 획득
  Future<ApiResponse<PointTransaction>> earnPointsForAlarmSuccess({
    required String alarmId,
    int points = 10,
  }) async {
    // 기본 포인트를 GRADE와 CONSUMPTION 모두에 반영 (일일 제한은 서버에서 기본 포인트에만 적용)
    // 반환값은 마지막 호출 응답으로 유지해 기존 사용처와의 호환성 보장
    ApiResponse<PointTransaction> lastResponse = await earnPoints(EarnPointsRequest(
      type: 'GRADE',
      amount: points,
      description: '알람 성공',
      metadata: {'alarmId': alarmId, 'reason': 'alarm_success', 'pointType': 'base'},
    ));
    lastResponse = await earnPoints(EarnPointsRequest(
      type: 'CONSUMPTION',
      amount: points,
      description: '알람 성공',
      metadata: {'alarmId': alarmId, 'reason': 'alarm_success', 'pointType': 'base'},
    ));
    return lastResponse;
  }

  /// 미션 완료로 포인트 획득
  Future<ApiResponse<PointTransaction>> earnPointsForMissionComplete({
    required String missionId,
    required MissionType missionType,
    required int score,
    int basePoints = 5,
  }) async {
    // 점수에 따른 보너스 포인트 계산
    final bonusPoints = (score / 10).floor();

    // 1) 기본 포인트 전송: GRADE, CONSUMPTION (일일 제한 적용 대상)
    ApiResponse<PointTransaction> lastResponse = await earnPoints(EarnPointsRequest(
      type: 'GRADE',
      amount: basePoints,
      description: '미션 완료 (${missionType.name})',
      metadata: {
        'missionId': missionId,
        'missionType': missionType.name,
        'score': score,
        'pointType': 'base',
        'reason': 'mission_complete',
      },
    ));

    lastResponse = await earnPoints(EarnPointsRequest(
      type: 'CONSUMPTION',
      amount: basePoints,
      description: '미션 완료 (${missionType.name})',
      metadata: {
        'missionId': missionId,
        'missionType': missionType.name,
        'score': score,
        'pointType': 'base',
        'reason': 'mission_complete',
      },
    ));

    // 2) 보너스 포인트가 있으면 별도 전송: GRADE, CONSUMPTION (일일 제한 제외)
    if (bonusPoints > 0) {
      lastResponse = await earnPoints(EarnPointsRequest(
        type: 'GRADE',
        amount: bonusPoints,
        description: '미션 완료 보너스 (${missionType.name})',
        metadata: {
          'missionId': missionId,
          'missionType': missionType.name,
          'score': score,
          'pointType': 'bonus',
          'reason': 'mission_bonus',
        },
      ));

      lastResponse = await earnPoints(EarnPointsRequest(
        type: 'CONSUMPTION',
        amount: bonusPoints,
        description: '미션 완료 보너스 (${missionType.name})',
        metadata: {
          'missionId': missionId,
          'missionType': missionType.name,
          'score': score,
          'pointType': 'bonus',
          'reason': 'mission_bonus',
        },
      ));
    }

    return lastResponse;
  }

  /// 연속 알람 성공으로 포인트 획득
  Future<ApiResponse<PointTransaction>> earnPointsForStreakBonus({
    required int streakDays,
    int basePoints = 20,
  }) async {
    // 연속 일수에 따른 보너스 계산
    final bonusPoints = (streakDays / 7).floor() * 10;

    // 1) 기본 포인트 전송: GRADE, CONSUMPTION
    ApiResponse<PointTransaction> lastResponse = await earnPoints(EarnPointsRequest(
      type: 'GRADE',
      amount: basePoints,
      description: '$streakDays일 연속 성공 보너스',
      metadata: {
        'streakDays': streakDays,
        'pointType': 'base',
        'reason': 'streak_bonus',
      },
    ));

    lastResponse = await earnPoints(EarnPointsRequest(
      type: 'CONSUMPTION',
      amount: basePoints,
      description: '$streakDays일 연속 성공 보너스',
      metadata: {
        'streakDays': streakDays,
        'pointType': 'base',
        'reason': 'streak_bonus',
      },
    ));

    // 2) 보너스 포인트 전송 (있을 경우): GRADE, CONSUMPTION
    if (bonusPoints > 0) {
      lastResponse = await earnPoints(EarnPointsRequest(
        type: 'GRADE',
        amount: bonusPoints,
        description: '$streakDays일 연속 성공 보너스 (보너스)',
        metadata: {
          'streakDays': streakDays,
          'pointType': 'bonus',
          'reason': 'streak_bonus',
        },
      ));

      lastResponse = await earnPoints(EarnPointsRequest(
        type: 'CONSUMPTION',
        amount: bonusPoints,
        description: '$streakDays일 연속 성공 보너스 (보너스)',
        metadata: {
          'streakDays': streakDays,
          'pointType': 'bonus',
          'reason': 'streak_bonus',
        },
      ));
    }

    return lastResponse;
  }

  /// 스킨 구매로 포인트 사용
  Future<ApiResponse<PointTransaction>> spendPointsForSkin({
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
  Future<ApiResponse<PointTransaction>> spendPointsForFeature({
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
  Future<ApiResponse<List<PointTransaction>>> getRecentPointTransaction({int limit = 20}) async {
    return getPointTransaction(limit: limit, offset: 0);
  }

  /// 획득한 포인트 내역만 조회
  Future<ApiResponse<List<PointTransaction>>> getEarnedPointTransaction({
    int? limit,
    int? offset,
  }) async {
    return getPointTransaction(
      type: PointTransactionType.earned,
      limit: limit,
      offset: offset,
    );
  }

  /// 사용한 포인트 내역만 조회
  Future<ApiResponse<List<PointTransaction>>> getSpentPointTransaction({
    int? limit,
    int? offset,
  }) async {
    return getPointTransaction(
      type: PointTransactionType.spent,
      limit: limit,
      offset: offset,
    );
  }

  /// 특정 기간의 포인트 내역 조회
  Future<ApiResponse<List<PointTransaction>>> getPointTransactionByDateRange(
    DateTime startDate,
    DateTime endDate, {
    int? limit,
    int? offset,
    PointTransactionType? type,
  }) async {
    return getPointTransaction(
      startDate: startDate,
      endDate: endDate,
      type: type,
      limit: limit,
      offset: offset,
    );
  }

  /// 포인트 잔액 확인
  Future<ApiResponse<Map<String, dynamic>>> getPointBalance() async {
    try {
      final response = await getPointSummary();
      if (response.success && response.data != null) {
        final summary = response.data!;
        return ApiResponse.success({
          'consumptionPoints': 0, // PointSummary에는 이 속성이 없으므로 0으로 설정
          'gradePoints': 0, // PointSummary에는 이 속성이 없으므로 0으로 설정
          'totalPoints': summary.totalPoints,
          'currentGrade': 'BRONZE', // PointSummary에는 등급 정보가 없으므로 기본값
        });
      }
      return ApiResponse.error('포인트 잔액 조회 실패');
    } catch (e) {
      return ApiResponse.error('포인트 잔액 조회 오류: $e');
    }
  }

  /// 포인트 사용 가능 여부 확인
  Future<bool> canSpendPoints(int amount, String pointType) async {
    try {
      final balanceResponse = await getPointBalance();
      if (!balanceResponse.success || balanceResponse.data == null) {
        return false;
      }

      final balance = balanceResponse.data!;
      switch (pointType) {
        case 'consumption':
          return (balance['consumptionPoints'] as int) >= amount;
        case 'grade':
          return (balance['gradePoints'] as int) >= amount;
        default:
          return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// 월별 포인트 통계 조회
  Future<ApiResponse<Map<String, dynamic>>> getMonthlyPointStats({
    int? year,
    int? month,
  }) async {
    try {
      final now = DateTime.now();
      final targetYear = year ?? now.year;
      final targetMonth = month ?? now.month;
      
      final startDate = DateTime(targetYear, targetMonth, 1);
      final endDate = DateTime(targetYear, targetMonth + 1, 1).subtract(const Duration(days: 1));

      final historyResponse = await getPointTransactionByDateRange(startDate, endDate);
      
      if (!historyResponse.success || historyResponse.data == null) {
        return ApiResponse.error('월별 포인트 통계 조회 실패');
      }

      final history = historyResponse.data!;
      int totalEarned = 0;
      int totalSpent = 0;
      int transactionCount = 0;

      for (final transaction in history) {
        if (transaction.amount > 0) {
          totalEarned += transaction.amount;
        } else {
          totalSpent += transaction.amount.abs();
        }
        transactionCount++;
      }

      return ApiResponse.success({
        'year': targetYear,
        'month': targetMonth,
        'totalEarned': totalEarned,
        'totalSpent': totalSpent,
        'netGain': totalEarned - totalSpent,
        'transactionCount': transactionCount,
        'averageTransaction': transactionCount > 0 ? (totalEarned + totalSpent) / transactionCount : 0,
      });
    } catch (e) {
      return ApiResponse.error('월별 포인트 통계 조회 오류: $e');
    }
  }

  /// 포인트 랭킹 조회 (향후 구현을 위한 준비)
  Future<ApiResponse<List<Map<String, dynamic>>>> getPointRanking({
    int limit = 10,
    String period = 'monthly', // daily, weekly, monthly, all
  }) async {
    try {
      final queryParams = {
        'limit': limit.toString(),
        'period': period,
      };

      return await _baseApi.get<List<Map<String, dynamic>>>(
        '/api/points/ranking',
        queryParameters: queryParams,
        fromJson: (json) {
          final List<dynamic> rankingList = json['ranking'] ?? json['data'] ?? [];
          return rankingList
              .map((item) => item as Map<String, dynamic>)
              .toList();
        },
      );
    } catch (e) {
      // 아직 구현되지 않은 API이므로 더미 데이터 반환
      return ApiResponse.success([
        {'rank': 1, 'nickname': '알람마스터', 'points': 2500, 'isCurrentUser': false},
        {'rank': 2, 'nickname': '아침형인간', 'points': 2200, 'isCurrentUser': false},
        {'rank': 3, 'nickname': '일찍자기', 'points': 1800, 'isCurrentUser': true},
      ]);
    }
  }
}
