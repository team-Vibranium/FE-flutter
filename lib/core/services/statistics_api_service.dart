import '../models/api_models.dart';
import 'base_api_service.dart';

/// 통계 관련 API 서비스
/// 사용자 통계 데이터 조회 API 호출 담당
class StatisticsApiService {
  static final StatisticsApiService _instance = StatisticsApiService._internal();
  factory StatisticsApiService() => _instance;
  StatisticsApiService._internal();

  final BaseApiService _baseApi = BaseApiService();

  /// 전체 통계 조회
  /// GET /api/statistics/overview
  Future<ApiResponse<StatisticsOverview>> getOverview() async {
    try {
      return await _baseApi.get<StatisticsOverview>(
        '/api/statistics/overview',
        fromJson: (json) => StatisticsOverview.fromJson(json),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 기간별 통계 조회
  /// GET /api/statistics/period
  Future<ApiResponse<PeriodStatistics>> getPeriodStatistics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final queryParams = {
        'startDate': startDate.toIso8601String().split('.')[0], // "2025-09-30T00:00:00"
        'endDate': endDate.toIso8601String().split('.')[0],     // "2025-09-30T23:59:59"
      };

      return await _baseApi.get<PeriodStatistics>(
        '/api/statistics/period',
        queryParameters: queryParams,
        fromJson: (json) => PeriodStatistics.fromJson(json),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 캘린더 통계 조회
  /// GET /api/statistics/calendar
  Future<ApiResponse<CalendarStatistics>> getCalendarStatistics({
    required int year,
    required int month,
  }) async {
    try {
      final queryParams = {
        'year': year.toString(),
        'month': month.toString(),
      };

      return await _baseApi.get<CalendarStatistics>(
        '/api/statistics/calendar',
        queryParameters: queryParams,
        fromJson: (json) => CalendarStatistics.fromJson(json),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 주간 통계 조회
  Future<ApiResponse<PeriodStatistics>> getWeeklyStatistics([DateTime? date]) async {
    final targetDate = date ?? DateTime.now();
    final startOfWeek = targetDate.subtract(Duration(days: targetDate.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    return getPeriodStatistics(
      startDate: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
      endDate: DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day, 23, 59, 59),
    );
  }

  /// 월간 통계 조회
  Future<ApiResponse<PeriodStatistics>> getMonthlyStatistics([DateTime? date]) async {
    final targetDate = date ?? DateTime.now();
    final startOfMonth = DateTime(targetDate.year, targetDate.month, 1);
    final endOfMonth = DateTime(targetDate.year, targetDate.month + 1, 0, 23, 59, 59);

    return getPeriodStatistics(
      startDate: startOfMonth,
      endDate: endOfMonth,
    );
  }

  /// 연간 통계 조회
  Future<ApiResponse<PeriodStatistics>> getYearlyStatistics([int? year]) async {
    final targetYear = year ?? DateTime.now().year;
    final startOfYear = DateTime(targetYear, 1, 1);
    final endOfYear = DateTime(targetYear, 12, 31, 23, 59, 59);

    return getPeriodStatistics(
      startDate: startOfYear,
      endDate: endOfYear,
    );
  }

  /// 최근 N일 통계 조회
  Future<ApiResponse<PeriodStatistics>> getRecentDaysStatistics(int days) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days - 1));

    return getPeriodStatistics(
      startDate: DateTime(startDate.year, startDate.month, startDate.day),
      endDate: DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59),
    );
  }

  /// 오늘 통계 조회
  Future<ApiResponse<PeriodStatistics>> getTodayStatistics() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

    return getPeriodStatistics(
      startDate: startOfDay,
      endDate: endOfDay,
    );
  }

  /// 어제 통계 조회
  Future<ApiResponse<PeriodStatistics>> getYesterdayStatistics() async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final startOfDay = DateTime(yesterday.year, yesterday.month, yesterday.day);
    final endOfDay = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);

    return getPeriodStatistics(
      startDate: startOfDay,
      endDate: endOfDay,
    );
  }

  /// 이번 주 캘린더 통계 조회
  Future<ApiResponse<CalendarStatistics>> getThisWeekCalendar() async {
    final now = DateTime.now();
    return getCalendarStatistics(year: now.year, month: now.month);
  }

  /// 이번 달 캘린더 통계 조회
  Future<ApiResponse<CalendarStatistics>> getThisMonthCalendar() async {
    final now = DateTime.now();
    return getCalendarStatistics(year: now.year, month: now.month);
  }

  /// 지난 달 캘린더 통계 조회
  Future<ApiResponse<CalendarStatistics>> getLastMonthCalendar() async {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1);
    return getCalendarStatistics(year: lastMonth.year, month: lastMonth.month);
  }

  /// 성공률 계산 헬퍼 메서드
  double calculateSuccessRate(int successful, int total) {
    if (total == 0) return 0.0;
    return (successful / total * 100);
  }

  /// 평균 통화 시간 계산 헬퍼 메서드
  int calculateAverageCallTime(int totalTime, int totalCalls) {
    if (totalCalls == 0) return 0;
    return (totalTime / totalCalls).round();
  }

  /// 연속 성공 일수 계산을 위한 일별 데이터 분석
  int calculateCurrentStreak(List<DailyStatistics> dailyStats) {
    if (dailyStats.isEmpty) return 0;

    // 최근 날짜부터 역순으로 확인
    dailyStats.sort((a, b) => b.date.compareTo(a.date));
    
    int streak = 0;
    for (final stat in dailyStats) {
          if (stat.alarmCount > 0 && stat.successCount > 0) {
        streak++;
      } else if (stat.alarmCount > 0) {
        // 알람이 있었지만 성공하지 못한 경우 연속 중단
        break;
      }
      // 알람이 없었던 날은 건너뛰기
    }

    return streak;
  }

  /// 최고 연속 성공 일수 계산
  int calculateBestStreak(List<DailyStatistics> dailyStats) {
    if (dailyStats.isEmpty) return 0;

    // 날짜 순으로 정렬
    dailyStats.sort((a, b) => a.date.compareTo(b.date));
    
    int currentStreak = 0;
    int bestStreak = 0;

    for (final stat in dailyStats) {
          if (stat.alarmCount > 0 && stat.successCount > 0) {
        currentStreak++;
        if (currentStreak > bestStreak) {
          bestStreak = currentStreak;
        }
      } else if (stat.alarmCount > 0) {
        currentStreak = 0;
      }
    }

    return bestStreak;
  }

  /// 주간별 성과 비교
  Future<ApiResponse<Map<String, dynamic>>> getWeeklyComparison() async {
    try {
      final thisWeek = await getWeeklyStatistics();
      final lastWeek = await getWeeklyStatistics(
        DateTime.now().subtract(const Duration(days: 7)),
      );

      if (!thisWeek.success || !lastWeek.success) {
        return ApiResponse.error('주간 비교 데이터 조회 실패');
      }

      final comparison = {
        'thisWeek': {
          'totalAlarms': thisWeek.data!.totalAlarms,
          'successAlarms': thisWeek.data!.successAlarms,
          'failedAlarms': thisWeek.data!.failedAlarms,
          'successRate': thisWeek.data!.successRate,
          'totalPoints': thisWeek.data!.totalPoints,
          'averageWakeTime': thisWeek.data!.averageWakeTime,
        },
        'lastWeek': {
          'totalAlarms': lastWeek.data!.totalAlarms,
          'successAlarms': lastWeek.data!.successAlarms,
          'failedAlarms': lastWeek.data!.failedAlarms,
          'successRate': lastWeek.data!.successRate,
          'totalPoints': lastWeek.data!.totalPoints,
          'averageWakeTime': lastWeek.data!.averageWakeTime,
        },
        'changes': {
          'successRate': thisWeek.data!.successRate - lastWeek.data!.successRate,
          'totalAlarms': thisWeek.data!.totalAlarms - lastWeek.data!.totalAlarms,
          'totalPoints': thisWeek.data!.totalPoints - lastWeek.data!.totalPoints,
          'averageWakeTime': thisWeek.data!.averageWakeTime,
        }
      };

      return ApiResponse.success(comparison);
    } catch (e) {
      return ApiResponse.error('주간 비교 계산 오류: $e');
    }
  }

  /// 월간별 성과 비교
  Future<ApiResponse<Map<String, dynamic>>> getMonthlyComparison() async {
    try {
      final thisMonth = await getMonthlyStatistics();
      final lastMonth = await getMonthlyStatistics(
        DateTime.now().subtract(const Duration(days: 30)),
      );

      if (!thisMonth.success || !lastMonth.success) {
        return ApiResponse.error('월간 비교 데이터 조회 실패');
      }

      final comparison = {
        'thisMonth': {
          'totalAlarms': thisMonth.data!.totalAlarms,
          'successAlarms': thisMonth.data!.successAlarms,
          'failedAlarms': thisMonth.data!.failedAlarms,
          'successRate': thisMonth.data!.successRate,
          'totalPoints': thisMonth.data!.totalPoints,
          'averageWakeTime': thisMonth.data!.averageWakeTime,
        },
        'lastMonth': {
          'totalAlarms': lastMonth.data!.totalAlarms,
          'successAlarms': lastMonth.data!.successAlarms,
          'failedAlarms': lastMonth.data!.failedAlarms,
          'successRate': lastMonth.data!.successRate,
          'totalPoints': lastMonth.data!.totalPoints,
          'averageWakeTime': lastMonth.data!.averageWakeTime,
        },
        'changes': {
          'successRate': thisMonth.data!.successRate - lastMonth.data!.successRate,
          'totalAlarms': thisMonth.data!.totalAlarms - lastMonth.data!.totalAlarms,
          'totalPoints': thisMonth.data!.totalPoints - lastMonth.data!.totalPoints,
          'averageWakeTime': thisMonth.data!.averageWakeTime,
        }
      };

      return ApiResponse.success(comparison);
    } catch (e) {
      return ApiResponse.error('월간 비교 계산 오류: $e');
    }
  }

  /// 상세 기간별 통계 조회 (API 명세 기반)
  /// GET /api/statistics/period?startDate={startDate}&endDate={endDate}
  Future<ApiResponse<Map<String, dynamic>>> getDetailedPeriodStatistics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final queryParams = {
        'startDate': startDate.toIso8601String().split('.')[0], // "2025-09-30T00:00:00"
        'endDate': endDate.toIso8601String().split('.')[0],     // "2025-09-30T23:59:59"
      };

      return await _baseApi.get<Map<String, dynamic>>(
        '/api/statistics/period',
        queryParameters: queryParams,
        fromJson: (json) => json,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 캘린더 통계 조회 (API 명세 기반)
  /// GET /api/statistics/calendar?year={year}&month={month}
  Future<ApiResponse<Map<String, dynamic>>> getDetailedCalendarStatistics({
    required int year,
    required int month,
  }) async {
    try {
      final queryParams = {
        'year': year.toString(),
        'month': month.toString(),
      };

      return await _baseApi.get<Map<String, dynamic>>(
        '/api/statistics/calendar',
        queryParameters: queryParams,
        fromJson: (json) => json,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 통계 대시보드 데이터 조회 (종합)
  Future<ApiResponse<Map<String, dynamic>>> getDashboardStatistics() async {
    try {
      // 여러 통계 데이터를 병렬로 조회
      final results = await Future.wait([
        getOverview(),
        getWeeklyStatistics(),
        getMonthlyStatistics(),
        getThisMonthCalendar(),
        getRecentDaysStatistics(7),
        getRecentDaysStatistics(30),
      ]);

      final overview = results[0];
      final weekly = results[1];
      final monthly = results[2];
      final calendar = results[3];
      final last7Days = results[4];
      final last30Days = results[5];

      if (!overview.success) {
        return ApiResponse.error('대시보드 통계 조회 실패: 전체 개요 데이터 오류');
      }

      return ApiResponse.success({
        'overview': overview.data,
        'weekly': weekly.success ? weekly.data : null,
        'monthly': monthly.success ? monthly.data : null,
        'calendar': calendar.success ? calendar.data : null,
        'last7Days': last7Days.success ? last7Days.data : null,
        'last30Days': last30Days.success ? last30Days.data : null,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ApiResponse.error('대시보드 통계 조회 오류: $e');
    }
  }

  /// 성과 트렌드 분석
  Future<ApiResponse<Map<String, dynamic>>> getPerformanceTrend({
    int days = 30,
  }) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));

      final periodStats = await getDetailedPeriodStatistics(
        startDate: startDate,
        endDate: endDate,
      );

      if (!periodStats.success || periodStats.data == null) {
        return ApiResponse.error('성과 트렌드 데이터 조회 실패');
      }

      final data = periodStats.data!;
      final dailyStats = data['dailyStats'] as List<dynamic>? ?? [];

      // 트렌드 분석
      final successRates = <double>[];
      final alarmCounts = <int>[];
      final pointsEarned = <int>[];

      for (final dayStat in dailyStats) {
        final dayData = dayStat as Map<String, dynamic>;
        final alarmCount = dayData['alarmCount'] as int? ?? 0;
        final successCount = dayData['successCount'] as int? ?? 0;
        final points = dayData['points'] as int? ?? 0;

        alarmCounts.add(alarmCount);
        pointsEarned.add(points);
        successRates.add(alarmCount > 0 ? (successCount / alarmCount * 100) : 0.0);
      }

      // 트렌드 계산 (선형 회귀 간소화)
      final trendAnalysis = {
        'successRateTrend': _calculateTrend(successRates),
        'alarmCountTrend': _calculateTrend(alarmCounts.map((e) => e.toDouble()).toList()),
        'pointsTrend': _calculateTrend(pointsEarned.map((e) => e.toDouble()).toList()),
        'averageSuccessRate': successRates.isNotEmpty 
            ? successRates.reduce((a, b) => a + b) / successRates.length 
            : 0.0,
        'totalAlarms': alarmCounts.reduce((a, b) => a + b),
        'totalPoints': pointsEarned.reduce((a, b) => a + b),
      };

      return ApiResponse.success(trendAnalysis);
    } catch (e) {
      return ApiResponse.error('성과 트렌드 분석 오류: $e');
    }
  }

  /// 간단한 트렌드 계산 (증가/감소/유지)
  String _calculateTrend(List<double> values) {
    if (values.length < 2) return 'insufficient_data';

    final firstHalf = values.sublist(0, values.length ~/ 2);
    final secondHalf = values.sublist(values.length ~/ 2);

    final firstAvg = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
    final secondAvg = secondHalf.reduce((a, b) => a + b) / secondHalf.length;

    final difference = secondAvg - firstAvg;
    
    if (difference > 5) return 'increasing';
    if (difference < -5) return 'decreasing';
    return 'stable';
  }

  /// 목표 달성률 계산
  Future<ApiResponse<Map<String, dynamic>>> getGoalAchievement({
    int? targetSuccessRate,
    int? targetAlarmsPerWeek,
    int? targetPointsPerMonth,
  }) async {
    try {
      final weekly = await getWeeklyStatistics();
      final monthly = await getMonthlyStatistics();

      if (!weekly.success || !monthly.success) {
        return ApiResponse.error('목표 달성률 계산을 위한 데이터 조회 실패');
      }

      final weeklyData = weekly.data!;
      final monthlyData = monthly.data!;

      final achievements = <String, dynamic>{};

      // 성공률 목표
      if (targetSuccessRate != null) {
        achievements['successRate'] = {
          'target': targetSuccessRate,
              'current': weeklyData.successRate,
              'achieved': weeklyData.successRate >= targetSuccessRate,
              'progress': (weeklyData.successRate / targetSuccessRate * 100).clamp(0, 100),
        };
      }

      // 주간 알람 목표
      if (targetAlarmsPerWeek != null) {
        achievements['weeklyAlarms'] = {
          'target': targetAlarmsPerWeek,
              'current': weeklyData.totalAlarms,
              'achieved': weeklyData.totalAlarms >= targetAlarmsPerWeek,
              'progress': (weeklyData.totalAlarms / targetAlarmsPerWeek * 100).clamp(0, 100),
        };
      }

      // 월간 포인트 목표
      if (targetPointsPerMonth != null) {
        achievements['monthlyPoints'] = {
          'target': targetPointsPerMonth,
              'current': monthlyData.totalPoints,
              'achieved': monthlyData.totalPoints >= targetPointsPerMonth,
              'progress': (monthlyData.totalPoints / targetPointsPerMonth * 100).clamp(0, 100),
        };
      }

      return ApiResponse.success({
        'achievements': achievements,
        'overallProgress': achievements.values
            .map((a) => a['progress'] as double)
            .reduce((a, b) => a + b) / achievements.length,
      });
    } catch (e) {
      return ApiResponse.error('목표 달성률 계산 오류: $e');
    }
  }

  /// 통계 요약 (위젯용)
  Future<ApiResponse<Map<String, dynamic>>> getStatisticsSummary() async {
    try {
      final overview = await getOverview();
      final weekly = await getWeeklyStatistics();
      
      if (!overview.success) {
        return ApiResponse.error('통계 요약 조회 실패');
      }

      final summary = {
        'totalAlarms': overview.data!.totalAlarms,
        'successRate': overview.data!.successRate,
        'consecutiveDays': 0, // StatisticsOverview에는 이 속성이 없으므로 0으로 설정
        'averageWakeTime': '07:30', // StatisticsOverview에는 이 속성이 없으므로 기본값
            'weeklyProgress': weekly.success ? (weekly.data!.successRate) : 0.0,
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      return ApiResponse.success(summary);
    } catch (e) {
      return ApiResponse.error('통계 요약 조회 오류: $e');
    }
  }
}
