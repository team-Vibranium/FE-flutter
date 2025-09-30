import 'package:intl/intl.dart';

/// 날짜/시간 유틸리티 클래스
class DateTimeUtils {
  /// UTC 시간 문자열을 로컬 DateTime으로 변환
  static DateTime parseUtcToLocal(String utcString) {
    try {
      // UTC 시간으로 파싱
      final utcDateTime = DateTime.parse(utcString);
      
      // UTC 시간을 로컬 시간으로 변환
      return utcDateTime.toLocal();
    } catch (e) {
      // Debug: UTC 시간 파싱 오류: $e
      return DateTime.now();
    }
  }

  /// 로컬 DateTime을 UTC 문자열로 변환
  static String toUtcString(DateTime localDateTime) {
    return localDateTime.toUtc().toIso8601String();
  }

  /// DateTime을 LocalDate 형식 (yyyy-MM-dd)으로 변환
  static String toLocalDateString(DateTime dateTime) {
    final formatter = DateFormat('yyyy-MM-dd');
    return formatter.format(dateTime);
  }

  /// 현재 날짜를 LocalDate 형식 (yyyy-MM-dd)으로 변환
  static String nowToLocalDateString() {
    return toLocalDateString(DateTime.now());
  }

  /// 현재 로컬 시간을 UTC 문자열로 변환
  static String nowToUtcString() {
    return DateTime.now().toUtc().toIso8601String();
  }

  /// 날짜를 한국어 형식으로 포맷팅
  static String formatKorean(DateTime dateTime) {
    final formatter = DateFormat('yyyy년 MM월 dd일 HH:mm');
    return formatter.format(dateTime);
  }

  /// 시간을 HH:mm 형식으로 포맷팅
  static String formatTime(DateTime dateTime) {
    final formatter = DateFormat('HH:mm');
    return formatter.format(dateTime);
  }

  /// 날짜를 yyyy-MM-dd 형식으로 포맷팅
  static String formatDate(DateTime dateTime) {
    final formatter = DateFormat('yyyy-MM-dd');
    return formatter.format(dateTime);
  }

  /// 상대적 시간 표시 (예: "2시간 전", "3일 전")
  static String formatRelative(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }

  /// UTC 시간이 올바른지 검증
  static bool isValidUtcTime(DateTime dateTime) {
    // 2030년 이후의 시간은 잘못된 것으로 간주
    if (dateTime.year > 2030) {
      return false;
    }

    // 2020년 이전의 시간도 잘못된 것으로 간주
    if (dateTime.year < 2020) {
      return false;
    }

    return true;
  }

  /// 잘못된 UTC 시간을 현재 시간으로 대체
  static DateTime parseUtcToLocalSafe(String utcString) {
    final parsed = parseUtcToLocal(utcString);
    
    if (!isValidUtcTime(parsed)) {
      // Debug: 잘못된 UTC 시간 감지: $utcString -> 현재 시간으로 대체
      return DateTime.now();
    }
    
    return parsed;
  }
}
