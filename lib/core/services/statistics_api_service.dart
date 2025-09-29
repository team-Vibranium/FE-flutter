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
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
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
      if (stat.alarmCount > 0 && stat.successfulWakeups > 0) {
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
      if (stat.alarmCount > 0 && stat.successfulWakeups > 0) {
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
        'thisWeek': thisWeek.data!.summary,
        'lastWeek': lastWeek.data!.summary,
        'changes': {
          'successRate': thisWeek.data!.summary.successRate - lastWeek.data!.summary.successRate,
          'totalAlarms': thisWeek.data!.summary.totalAlarms - lastWeek.data!.summary.totalAlarms,
          'totalPoints': thisWeek.data!.summary.totalPoints - lastWeek.data!.summary.totalPoints,
          'averageCallTime': thisWeek.data!.summary.averageCallTime - lastWeek.data!.summary.averageCallTime,
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
        'thisMonth': thisMonth.data!.summary,
        'lastMonth': lastMonth.data!.summary,
        'changes': {
          'successRate': thisMonth.data!.summary.successRate - lastMonth.data!.summary.successRate,
          'totalAlarms': thisMonth.data!.summary.totalAlarms - lastMonth.data!.summary.totalAlarms,
          'totalPoints': thisMonth.data!.summary.totalPoints - lastMonth.data!.summary.totalPoints,
          'averageCallTime': thisMonth.data!.summary.averageCallTime - lastMonth.data!.summary.averageCallTime,
        }
      };

      return ApiResponse.success(comparison);
    } catch (e) {
      return ApiResponse.error('월간 비교 계산 오류: $e');
    }
  }
}
