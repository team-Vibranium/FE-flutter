// API 응답 모델들
// 노션 API 스펙에 맞춰 정의된 데이터 모델들

/// 기본 API 응답 래퍼
class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final String? error;
  final int? statusCode;

  const ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.error,
    this.statusCode,
  });

  factory ApiResponse.success(T data, {String? message}) {
    return ApiResponse(
      success: true,
      data: data,
      message: message,
      statusCode: 200,
    );
  }

  factory ApiResponse.error(String error, {int? statusCode}) {
    return ApiResponse(
      success: false,
      error: error,
      statusCode: statusCode ?? 500,
    );
  }

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    try {
      return ApiResponse.success(fromJsonT(json));
    } catch (e) {
      return ApiResponse.error('JSON 파싱 오류: $e');
    }
  }
}

/// 사용자 모델
class User {
  final int id;
  final String email;
  final String nickname;
  final int points;
  final String selectedAvatar;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.email,
    required this.nickname,
    required this.points,
    required this.selectedAvatar,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      email: json['email'] as String,
      nickname: json['nickname'] as String,
      points: json['points'] as int,
      selectedAvatar: json['selectedAvatar'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nickname': nickname,
      'points': points,
      'selectedAvatar': selectedAvatar,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'User(id: $id, email: $email, nickname: $nickname, points: $points, selectedAvatar: $selectedAvatar)';
  }
}

/// 인증 토큰 모델
class AuthToken {
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;

  const AuthToken({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  factory AuthToken.fromJson(Map<String, dynamic> json) {
    return AuthToken(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresAt': expiresAt.toIso8601String(),
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// 로그인/회원가입 응답 모델 (서버 응답 구조에 맞춤)
class LoginResponse {
  final User user;
  final String token;

  const LoginResponse({
    required this.user,
    required this.token,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    print('🔍 LoginResponse.fromJson 시작');
    print('🔍 전체 json: $json');
    print('🔍 json[\'user\']: ${json['user']}');
    print('🔍 json[\'token\']: ${json['token']}');
    print('🔍 json[\'user\'] 타입: ${json['user'].runtimeType}');
    
    return LoginResponse(
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      token: json['token'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'token': token,
    };
  }
}

/// 통화 기록 모델
class CallLog {
  final String id;
  final String userId;
  final String alarmTitle;
  final DateTime startTime;
  final DateTime? endTime;
  final int duration; // 초 단위
  final bool isSuccessful;
  final String? transcript;
  final Map<String, dynamic>? metadata;

  const CallLog({
    required this.id,
    required this.userId,
    required this.alarmTitle,
    required this.startTime,
    this.endTime,
    required this.duration,
    required this.isSuccessful,
    this.transcript,
    this.metadata,
  });

  factory CallLog.fromJson(Map<String, dynamic> json) {
    return CallLog(
      id: json['id'] as String,
      userId: json['userId'] as String,
      alarmTitle: json['alarmTitle'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime'] as String) : null,
      duration: json['duration'] as int,
      isSuccessful: json['isSuccessful'] as bool,
      transcript: json['transcript'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'alarmTitle': alarmTitle,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'duration': duration,
      'isSuccessful': isSuccessful,
      'transcript': transcript,
      'metadata': metadata,
    };
  }
}

/// 포인트 현황 모델
class PointSummary {
  final int totalPoints;
  final int earnedToday;
  final int spentToday;
  final int earnedThisWeek;
  final int spentThisWeek;
  final int earnedThisMonth;
  final int spentThisMonth;

  const PointSummary({
    required this.totalPoints,
    required this.earnedToday,
    required this.spentToday,
    required this.earnedThisWeek,
    required this.spentThisWeek,
    required this.earnedThisMonth,
    required this.spentThisMonth,
  });

  factory PointSummary.fromJson(Map<String, dynamic> json) {
    return PointSummary(
      totalPoints: json['totalPoints'] as int,
      earnedToday: json['earnedToday'] as int,
      spentToday: json['spentToday'] as int,
      earnedThisWeek: json['earnedThisWeek'] as int,
      spentThisWeek: json['spentThisWeek'] as int,
      earnedThisMonth: json['earnedThisMonth'] as int,
      spentThisMonth: json['spentThisMonth'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalPoints': totalPoints,
      'earnedToday': earnedToday,
      'spentToday': spentToday,
      'earnedThisWeek': earnedThisWeek,
      'spentThisWeek': spentThisWeek,
      'earnedThisMonth': earnedThisMonth,
      'spentThisMonth': spentThisMonth,
    };
  }
}

/// 포인트 내역 모델
class PointHistory {
  final String id;
  final String userId;
  final int amount;
  final PointTransactionType type;
  final String description;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  const PointHistory({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.description,
    required this.createdAt,
    this.metadata,
  });

  factory PointHistory.fromJson(Map<String, dynamic> json) {
    return PointHistory(
      id: json['id'] as String,
      userId: json['userId'] as String,
      amount: json['amount'] as int,
      type: PointTransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => PointTransactionType.earned,
      ),
      description: json['description'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'type': type.name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }
}

/// 포인트 거래 타입
enum PointTransactionType {
  earned, // 획득
  spent,  // 사용
}

/// 미션 결과 모델
class MissionResult {
  final String id;
  final String userId;
  final String alarmId;
  final MissionType missionType;
  final bool isCompleted;
  final int score;
  final DateTime completedAt;
  final Map<String, dynamic>? resultData;

  const MissionResult({
    required this.id,
    required this.userId,
    required this.alarmId,
    required this.missionType,
    required this.isCompleted,
    required this.score,
    required this.completedAt,
    this.resultData,
  });

  factory MissionResult.fromJson(Map<String, dynamic> json) {
    return MissionResult(
      id: json['id'] as String,
      userId: json['userId'] as String,
      alarmId: json['alarmId'] as String,
      missionType: MissionType.values.firstWhere(
        (e) => e.name == json['missionType'],
        orElse: () => MissionType.math,
      ),
      isCompleted: json['isCompleted'] as bool,
      score: json['score'] as int,
      completedAt: DateTime.parse(json['completedAt'] as String),
      resultData: json['resultData'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'alarmId': alarmId,
      'missionType': missionType.name,
      'isCompleted': isCompleted,
      'score': score,
      'completedAt': completedAt.toIso8601String(),
      'resultData': resultData,
    };
  }
}

/// 미션 타입
enum MissionType {
  math,     // 수학 문제
  memory,   // 기억 게임
  puzzle,   // 퍼즐
  voice,    // 음성 인식
  walking,  // 걷기
}

/// 통계 개요 모델
class StatisticsOverview {
  final int totalAlarms;
  final int successfulWakeups;
  final double successRate;
  final int totalCallTime; // 초 단위
  final int averageCallTime; // 초 단위
  final int totalPoints;
  final int completedMissions;

  const StatisticsOverview({
    required this.totalAlarms,
    required this.successfulWakeups,
    required this.successRate,
    required this.totalCallTime,
    required this.averageCallTime,
    required this.totalPoints,
    required this.completedMissions,
  });

  factory StatisticsOverview.fromJson(Map<String, dynamic> json) {
    return StatisticsOverview(
      totalAlarms: json['totalAlarms'] as int,
      successfulWakeups: json['successfulWakeups'] as int,
      successRate: (json['successRate'] as num).toDouble(),
      totalCallTime: json['totalCallTime'] as int,
      averageCallTime: json['averageCallTime'] as int,
      totalPoints: json['totalPoints'] as int,
      completedMissions: json['completedMissions'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalAlarms': totalAlarms,
      'successfulWakeups': successfulWakeups,
      'successRate': successRate,
      'totalCallTime': totalCallTime,
      'averageCallTime': averageCallTime,
      'totalPoints': totalPoints,
      'completedMissions': completedMissions,
    };
  }
}

/// 기간별 통계 모델
class PeriodStatistics {
  final DateTime startDate;
  final DateTime endDate;
  final List<DailyStatistics> dailyStats;
  final StatisticsOverview summary;

  const PeriodStatistics({
    required this.startDate,
    required this.endDate,
    required this.dailyStats,
    required this.summary,
  });

  factory PeriodStatistics.fromJson(Map<String, dynamic> json) {
    return PeriodStatistics(
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      dailyStats: (json['dailyStats'] as List)
          .map((e) => DailyStatistics.fromJson(e as Map<String, dynamic>))
          .toList(),
      summary: StatisticsOverview.fromJson(json['summary'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'dailyStats': dailyStats.map((e) => e.toJson()).toList(),
      'summary': summary.toJson(),
    };
  }
}

/// 일별 통계 모델
class DailyStatistics {
  final DateTime date;
  final int alarmCount;
  final int successfulWakeups;
  final int totalCallTime;
  final int pointsEarned;
  final int pointsSpent;

  const DailyStatistics({
    required this.date,
    required this.alarmCount,
    required this.successfulWakeups,
    required this.totalCallTime,
    required this.pointsEarned,
    required this.pointsSpent,
  });

  factory DailyStatistics.fromJson(Map<String, dynamic> json) {
    return DailyStatistics(
      date: DateTime.parse(json['date'] as String),
      alarmCount: json['alarmCount'] as int,
      successfulWakeups: json['successfulWakeups'] as int,
      totalCallTime: json['totalCallTime'] as int,
      pointsEarned: json['pointsEarned'] as int,
      pointsSpent: json['pointsSpent'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'alarmCount': alarmCount,
      'successfulWakeups': successfulWakeups,
      'totalCallTime': totalCallTime,
      'pointsEarned': pointsEarned,
      'pointsSpent': pointsSpent,
    };
  }
}

/// 캘린더 통계 모델
class CalendarStatistics {
  final int year;
  final int month;
  final List<CalendarDay> days;

  const CalendarStatistics({
    required this.year,
    required this.month,
    required this.days,
  });

  factory CalendarStatistics.fromJson(Map<String, dynamic> json) {
    return CalendarStatistics(
      year: json['year'] as int,
      month: json['month'] as int,
      days: (json['days'] as List)
          .map((e) => CalendarDay.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'month': month,
      'days': days.map((e) => e.toJson()).toList(),
    };
  }
}

/// 캘린더 일자 모델
class CalendarDay {
  final int day;
  final bool hasAlarm;
  final bool wasSuccessful;
  final int alarmCount;
  final int pointsEarned;

  const CalendarDay({
    required this.day,
    required this.hasAlarm,
    required this.wasSuccessful,
    required this.alarmCount,
    required this.pointsEarned,
  });

  factory CalendarDay.fromJson(Map<String, dynamic> json) {
    return CalendarDay(
      day: json['day'] as int,
      hasAlarm: json['hasAlarm'] as bool,
      wasSuccessful: json['wasSuccessful'] as bool,
      alarmCount: json['alarmCount'] as int,
      pointsEarned: json['pointsEarned'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'hasAlarm': hasAlarm,
      'wasSuccessful': wasSuccessful,
      'alarmCount': alarmCount,
      'pointsEarned': pointsEarned,
    };
  }
}

/// 회원가입 요청 모델
class RegisterRequest {
  final String email;
  final String password;
  final String nickname;

  const RegisterRequest({
    required this.email,
    required this.password,
    required this.nickname,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'nickname': nickname,
    };
  }
}

/// 로그인 요청 모델
class LoginRequest {
  final String email;
  final String password;

  const LoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

/// 비밀번호 변경 요청 모델
class PasswordChangeRequest {
  final String currentPassword;
  final String newPassword;

  const PasswordChangeRequest({
    required this.currentPassword,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    };
  }
}

/// 닉네임 변경 요청 모델
class NicknameChangeRequest {
  final String nickname;

  const NicknameChangeRequest({
    required this.nickname,
  });

  Map<String, dynamic> toJson() {
    return {
      'nickname': nickname,
    };
  }
}

/// 포인트 사용 요청 모델
class SpendPointsRequest {
  final int amount;
  final String description;
  final Map<String, dynamic>? metadata;

  const SpendPointsRequest({
    required this.amount,
    required this.description,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'description': description,
      'metadata': metadata,
    };
  }
}

/// 포인트 획득 요청 모델
class EarnPointsRequest {
  final int amount;
  final String description;
  final Map<String, dynamic>? metadata;

  const EarnPointsRequest({
    required this.amount,
    required this.description,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'description': description,
      'metadata': metadata,
    };
  }
}
