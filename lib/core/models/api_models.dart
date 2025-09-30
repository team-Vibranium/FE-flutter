// API 응답 모델들
// 노션 API 스펙에 맞춰 정의된 데이터 모델들

import '../utils/date_time_utils.dart';

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

  // accessToken과 refreshToken getter 추가 (호환성을 위해)
  String get accessToken => token;
  String get refreshToken => token; // 현재 구조에서는 같은 토큰 사용

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    // Debug: LoginResponse.fromJson 시작
    // Debug: 전체 json: $json
    // Debug: json['user']: ${json['user']}
    // Debug: json['token']: ${json['token']}
    // Debug: json['user'] 타입: ${json['user'].runtimeType}
    
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

/// 전화 알람 모델
class PhoneAlarm {
  final int alarmId;
  final DateTime alarmTime;
  final String instructions;
  final String voice;
  final String voiceDescription;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PhoneAlarm({
    required this.alarmId,
    required this.alarmTime,
    required this.instructions,
    required this.voice,
    required this.voiceDescription,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PhoneAlarm.fromJson(Map<String, dynamic> json) {
    return PhoneAlarm(
      alarmId: json['alarmId'] as int,
      alarmTime: DateTime.parse(json['alarmTime'] as String),
      instructions: json['instructions'] as String,
      voice: json['voice'] as String,
      voiceDescription: json['voiceDescription'] as String,
      active: json['active'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'alarmId': alarmId,
      'alarmTime': alarmTime.toIso8601String(),
      'instructions': instructions,
      'voice': voice,
      'voiceDescription': voiceDescription,
      'active': active,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

/// 알람 생성 요청 모델
class CreateAlarmRequest {
  final DateTime alarmTime;
  final String instructions;
  final String voice;

  const CreateAlarmRequest({
    required this.alarmTime,
    required this.instructions,
    required this.voice,
  });

  Map<String, dynamic> toJson() {
    return {
      'alarmTime': alarmTime.toIso8601String(),
      'instructions': instructions,
      'voice': voice,
    };
  }
}

/// 알람 수정 요청 모델
class UpdateAlarmRequest {
  final DateTime alarmTime;
  final String instructions;
  final String voice;

  const UpdateAlarmRequest({
    required this.alarmTime,
    required this.instructions,
    required this.voice,
  });

  Map<String, dynamic> toJson() {
    return {
      'alarmTime': alarmTime.toIso8601String(),
      'instructions': instructions,
      'voice': voice,
    };
  }
}

/// 통화 기록 모델 (API 명세서에 맞게 업데이트)
class CallLog {
  final int id;
  final User? user;
  final DateTime callStart;
  final DateTime? callEnd;
  final String result; // SUCCESS, FAIL_NO_TALK, FAIL_SNOOZE
  final int snoozeCount;
  final String? conversationData;
  final DateTime createdAt;
  final bool successful;
  final List<Utterance>? conversationList;

  const CallLog({
    required this.id,
    this.user,
    required this.callStart,
    this.callEnd,
    required this.result,
    required this.snoozeCount,
    this.conversationData,
    required this.createdAt,
    required this.successful,
    this.conversationList,
  });

  // Convenience getters for backward compatibility
  bool get isSuccessful => successful;
  DateTime get startTime => callStart;
  int get duration => callEnd != null ? callEnd!.difference(callStart).inSeconds : 0;
  String get transcript => conversationData ?? '';

  factory CallLog.fromJson(Map<String, dynamic> json) {
    return CallLog(
      id: json['id'] as int,
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      callStart: DateTime.parse(json['callStart'] as String),
      callEnd: json['callEnd'] != null ? DateTime.parse(json['callEnd'] as String).subtract(const Duration(hours: 9)) : null,
      result: json['result'] as String,
      snoozeCount: json['snoozeCount'] as int,
      conversationData: json['conversationData'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      successful: json['successful'] as bool,
      conversationList: json['conversationList'] != null
          ? (json['conversationList'] as List)
              .map((e) => Utterance.fromJson(e))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user?.toJson(),
      'callStart': callStart.toIso8601String(),
      'callEnd': callEnd?.toIso8601String(),
      'result': result,
      'snoozeCount': snoozeCount,
      'conversationData': conversationData,
      'createdAt': createdAt.toIso8601String(),
      'successful': successful,
      'conversationList': conversationList?.map((e) => e.toJson()).toList(),
    };
  }
}

/// 대화 발화 모델 (API 명세서에서 추가됨)
class Utterance {
  final String speaker; // user, assistant, system
  final String text;
  final DateTime timestamp;

  const Utterance({
    required this.speaker,
    required this.text,
    required this.timestamp,
  });

  factory Utterance.fromJson(Map<String, dynamic> json) {
    return Utterance(
      speaker: json['speaker'] as String,
      text: json['text'] as String,
      timestamp: DateTimeUtils.parseUtcToLocalSafe(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    // ISO 8601 문자열 형식으로 전송 (백엔드 Jackson이 파싱 가능)
    final isoString = timestamp.toIso8601String();
    final withoutMillis = isoString.split('.').first; // yyyy-MM-ddTHH:mm:ss

    return {
      'speaker': speaker,
      'text': text,
      'timestamp': withoutMillis,
    };
  }
}

/// OpenAI Realtime API 세션 응답 모델
class SessionResponse {
  final String ephemeralKey;
  final String sessionId;
  final int expiresInSeconds;

  const SessionResponse({
    required this.ephemeralKey,
    required this.sessionId,
    required this.expiresInSeconds,
  });

  factory SessionResponse.fromJson(Map<String, dynamic> json) {
    return SessionResponse(
      ephemeralKey: json['ephemeralKey'] as String,
      sessionId: json['sessionId'] as String,
      expiresInSeconds: json['expiresInSeconds'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ephemeralKey': ephemeralKey,
      'sessionId': sessionId,
      'expiresInSeconds': expiresInSeconds,
    };
  }
}

/// 통화 시작 요청 모델
class CallStartRequest {
  final String sessionId;

  const CallStartRequest({
    required this.sessionId,
  });

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
    };
  }
}

/// 통화 시작 응답 모델
class CallStartResponse {
  final int callId;
  final String sessionId;
  final DateTime callStart;

  const CallStartResponse({
    required this.callId,
    required this.sessionId,
    required this.callStart,
  });

  factory CallStartResponse.fromJson(Map<String, dynamic> json) {
    return CallStartResponse(
      callId: json['callId'] as int,
      sessionId: json['sessionId'] as String,
      callStart: DateTime.parse(json['callStart'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'callId': callId,
      'sessionId': sessionId,
      'callStart': callStart.toIso8601String(),
    };
  }
}

/// 통화 종료 요청 모델
class CallEndRequest {
  final DateTime callEnd;
  final String result;
  final int snoozeCount;

  const CallEndRequest({
    required this.callEnd,
    required this.result,
    this.snoozeCount = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'callEnd': callEnd.toIso8601String(),
      'result': result,
      'snoozeCount': snoozeCount,
    };
  }
}

/// 대화 내용 저장 요청 모델
class TranscriptRequest {
  final List<Utterance> conversation;

  const TranscriptRequest({
    required this.conversation,
  });

  Map<String, dynamic> toJson() {
    return {
      'conversation': conversation.map((e) => e.toJson()).toList(),
    };
  }
}

/// 통화 상세 정보 응답 모델
class CallDetailResponse {
  final int callId;
  final DateTime callStart;
  final DateTime? callEnd;
  final String result;
  final int snoozeCount;
  final List<Utterance>? conversation;
  final DateTime createdAt;

  const CallDetailResponse({
    required this.callId,
    required this.callStart,
    this.callEnd,
    required this.result,
    required this.snoozeCount,
    this.conversation,
    required this.createdAt,
  });

  factory CallDetailResponse.fromJson(Map<String, dynamic> json) {
    return CallDetailResponse(
      callId: json['callId'] as int,
      callStart: DateTimeUtils.parseUtcToLocalSafe(json['callStart'] as String),
      callEnd: json['callEnd'] != null ? DateTimeUtils.parseUtcToLocalSafe(json['callEnd'] as String) : null,
      result: json['result'] as String,
      snoozeCount: json['snoozeCount'] as int,
      conversation: json['conversation'] != null
          ? (json['conversation'] as List)
              .map((e) => Utterance.fromJson(e))
              .toList()
          : null,
      createdAt: DateTimeUtils.parseUtcToLocalSafe(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'callId': callId,
      'callStart': callStart.toIso8601String(),
      'callEnd': callEnd?.toIso8601String(),
      'result': result,
      'snoozeCount': snoozeCount,
      'conversation': conversation?.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

/// 포인트 현황 모델 (API 명세서에 맞게 업데이트)
class PointSummary {
  final int consumptionPoints;
  final int gradePoints;
  final int totalPoints;
  final String currentGrade;
  final int earnedToday;
  final int spentToday;

  const PointSummary({
    required this.consumptionPoints,
    required this.gradePoints,
    required this.totalPoints,
    required this.currentGrade,
    required this.earnedToday,
    required this.spentToday,
  });

  factory PointSummary.fromJson(Map<String, dynamic> json) {
    return PointSummary(
      consumptionPoints: json['consumptionPoints'] as int,
      gradePoints: json['gradePoints'] as int,
      totalPoints: json['totalPoints'] as int,
      currentGrade: json['currentGrade'] as String,
      earnedToday: json['earnedToday'] as int? ?? 0,
      spentToday: json['spentToday'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'consumptionPoints': consumptionPoints,
      'gradePoints': gradePoints,
      'totalPoints': totalPoints,
      'currentGrade': currentGrade,
      'earnedToday': earnedToday,
      'spentToday': spentToday,
    };
  }
}

/// 포인트 트랜잭션 모델 (API 명세서에 맞게 업데이트)
class PointTransaction {
  final int id;
  final String type; // GRADE 또는 CONSUMPTION
  final int amount;
  final String description;
  final DateTime createdAt;
  final String? relatedAlarmId;

  const PointTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.createdAt,
    this.relatedAlarmId,
  });

  factory PointTransaction.fromJson(Map<String, dynamic> json) {
    return PointTransaction(
      id: json['id'] as int,
      type: json['type'] as String,
      amount: json['amount'] as int,
      description: json['description'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      relatedAlarmId: json['relatedAlarmId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'relatedAlarmId': relatedAlarmId,
    };
  }
}

/// 포인트 거래 타입
enum PointTransactionType {
  earned, // 획득
  spent,  // 사용
}

/// 미션 결과 모델 (API 명세서에 맞게 업데이트)
class MissionResult {
  final int id;
  final int callLogId;
  final String missionType; // API에서는 문자열로 관리
  final bool success;
  final int? score;

  const MissionResult({
    required this.id,
    required this.callLogId,
    required this.missionType,
    required this.success,
    this.score,
  });

  factory MissionResult.fromJson(Map<String, dynamic> json) {
    return MissionResult(
      id: json['id'] as int,
      callLogId: json['callLogId'] as int,
      missionType: json['missionType'] as String,
      success: json['success'] as bool,
      score: json['score'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'callLogId': callLogId,
      'missionType': missionType,
      'success': success,
      if (score != null) 'score': score,
    };
  }
}

/// 미션 타입 (API 명세서에 맞게 업데이트)
enum MissionType {
  PUZZLE,   // 퍼즐
  MATH,     // 수학 문제
  MEMORY,   // 기억 게임
  QUIZ,     // 퀴즈
}

/// 음성 타입 (API 명세서에서 추가됨)
enum VoiceType {
  ALLOY,    // 균형 잡힌 중성적 목소리
  ASH,      // 부드럽고 차분한 목소리
  BALLAD,   // 서정적이고 따뜻한 목소리
  CORAL,    // 활기찬 여성 목소리
  ECHO,     // 맑고 선명한 목소리
  SAGE,     // 차분하고 부드러운 목소리
  SHIMMER,  // 밝고 경쾌한 목소리
  VERSE,    // 리드미컬하고 표현력 있는 목소리
}

/// 통계 개요 모델
class StatisticsOverview {
  final int totalAlarms;
  final int successAlarms;
  final int missedAlarms;
  final double successRate;
  final int consecutiveDays;
  final String averageWakeTime;
  final double last30DaysSuccessRate;
  final double monthlySuccessRate;
  final int monthlyPoints;
  final double averageCallTime; // 추가된 필드
  final int successfulWakeups; // 추가된 필드
  final int totalCallTime; // 추가된 필드
  final int totalPoints; // 추가된 필드
  final int completedMissions; // 추가된 필드

  const StatisticsOverview({
    required this.totalAlarms,
    required this.successAlarms,
    required this.missedAlarms,
    required this.successRate,
    required this.consecutiveDays,
    required this.averageWakeTime,
    required this.last30DaysSuccessRate,
    required this.monthlySuccessRate,
    required this.monthlyPoints,
    required this.averageCallTime,
    required this.successfulWakeups,
    required this.totalCallTime,
    required this.totalPoints,
    required this.completedMissions,
  });

  factory StatisticsOverview.fromJson(Map<String, dynamic> json) {
    return StatisticsOverview(
      totalAlarms: json['totalAlarms'] as int? ?? 0,
      successAlarms: json['successAlarms'] as int? ?? 0,
      missedAlarms: json['missedAlarms'] as int? ?? 0,
      successRate: (json['successRate'] as num?)?.toDouble() ?? 0.0,
      consecutiveDays: json['consecutiveDays'] as int? ?? 0,
      averageWakeTime: json['averageWakeTime'] as String? ?? '00:00',
      last30DaysSuccessRate: (json['last30DaysSuccessRate'] as num?)?.toDouble() ?? 0.0,
      monthlySuccessRate: (json['monthlySuccessRate'] as num?)?.toDouble() ?? 0.0,
      monthlyPoints: json['monthlyPoints'] as int? ?? 0,
      averageCallTime: (json['averageCallTime'] as num?)?.toDouble() ?? 0.0,
      successfulWakeups: json['successfulWakeups'] as int? ?? 0,
      totalCallTime: json['totalCallTime'] as int? ?? 0,
      totalPoints: json['totalPoints'] as int? ?? 0,
      completedMissions: json['completedMissions'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalAlarms': totalAlarms,
      'successAlarms': successAlarms,
      'missedAlarms': missedAlarms,
      'successRate': successRate,
      'consecutiveDays': consecutiveDays,
      'averageWakeTime': averageWakeTime,
      'last30DaysSuccessRate': last30DaysSuccessRate,
      'monthlySuccessRate': monthlySuccessRate,
      'monthlyPoints': monthlyPoints,
      'averageCallTime': averageCallTime,
      'successfulWakeups': successfulWakeups,
      'totalCallTime': totalCallTime,
      'totalPoints': totalPoints,
      'completedMissions': completedMissions,
    };
  }
}

/// 기간별 통계 모델
class PeriodStatistics {
  final Map<String, dynamic> period;
  final int totalAlarms;
  final int successAlarms;
  final int failedAlarms;
  final double successRate;
  final int totalPoints;
  final String averageWakeTime;
  final List<DailyStatistics> dailyStats;

  const PeriodStatistics({
    required this.period,
    required this.totalAlarms,
    required this.successAlarms,
    required this.failedAlarms,
    required this.successRate,
    required this.totalPoints,
    required this.averageWakeTime,
    required this.dailyStats,
  });

  factory PeriodStatistics.fromJson(Map<String, dynamic> json) {
    return PeriodStatistics(
      period: json['period'] as Map<String, dynamic>? ?? {},
      totalAlarms: json['totalAlarms'] as int? ?? 0,
      successAlarms: json['successAlarms'] as int? ?? 0,
      failedAlarms: json['failedAlarms'] as int? ?? 0,
      successRate: (json['successRate'] as num?)?.toDouble() ?? 0.0,
      totalPoints: json['totalPoints'] as int? ?? 0,
      averageWakeTime: json['averageWakeTime'] as String? ?? '00:00',
      dailyStats: (json['dailyStats'] as List?)
          ?.map((e) => DailyStatistics.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'period': period,
      'totalAlarms': totalAlarms,
      'successAlarms': successAlarms,
      'failedAlarms': failedAlarms,
      'successRate': successRate,
      'totalPoints': totalPoints,
      'averageWakeTime': averageWakeTime,
      'dailyStats': dailyStats.map((e) => e.toJson()).toList(),
    };
  }
}

/// 일별 통계 모델
class DailyStatistics {
  final String date;
  final int alarmCount;
  final int successCount;
  final int failCount;
  final int points;

  const DailyStatistics({
    required this.date,
    required this.alarmCount,
    required this.successCount,
    required this.failCount,
    required this.points,
  });

  factory DailyStatistics.fromJson(Map<String, dynamic> json) {
    return DailyStatistics(
      date: json['date'] as String? ?? '',
      alarmCount: json['alarmCount'] as int? ?? 0,
      successCount: json['successCount'] as int? ?? 0,
      failCount: json['failCount'] as int? ?? 0,
      points: json['points'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'alarmCount': alarmCount,
      'successCount': successCount,
      'failCount': failCount,
      'points': points,
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
  final int alarmCount;
  final int successCount;
  final int failCount;
  final String status;

  const CalendarDay({
    required this.day,
    required this.alarmCount,
    required this.successCount,
    required this.failCount,
    required this.status,
  });

  factory CalendarDay.fromJson(Map<String, dynamic> json) {
    return CalendarDay(
      day: json['day'] as int? ?? 0,
      alarmCount: json['alarmCount'] as int? ?? 0,
      successCount: json['successCount'] as int? ?? 0,
      failCount: json['failCount'] as int? ?? 0,
      status: json['status'] as String? ?? 'none',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'alarmCount': alarmCount,
      'successCount': successCount,
      'failCount': failCount,
      'status': status,
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

/// 비밀번호 변경 요청 모델 (API 명세서에 맞게 업데이트)
class PasswordChangeRequest {
  final String currentPassword;
  final String newPassword;
  final String confirmPassword;

  const PasswordChangeRequest({
    required this.currentPassword,
    required this.newPassword,
    required this.confirmPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
      'confirmPassword': confirmPassword,
    };
  }
}

/// 닉네임 변경 요청 모델 (API 명세서에 맞게 업데이트)
class NicknameChangeRequest {
  final String newNickname;

  const NicknameChangeRequest({
    required this.newNickname,
  });

  Map<String, dynamic> toJson() {
    return {
      'newNickname': newNickname,
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
  final String type; // "GRADE" 또는 "CONSUMPTION"
  final int amount;
  final String description;
  final Map<String, dynamic>? metadata;

  const EarnPointsRequest({
    required this.type,
    required this.amount,
    required this.description,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'amount': amount,
      'description': description,
      'metadata': metadata,
    };
  }
}

/// 스누즈 응답 모델
class SnoozeResponse {
  final int currentSnoozeCount;
  final bool shouldFail;

  const SnoozeResponse({
    required this.currentSnoozeCount,
    required this.shouldFail,
  });

  factory SnoozeResponse.fromJson(Map<String, dynamic> json) {
    return SnoozeResponse(
      currentSnoozeCount: json['currentSnoozeCount'] as int,
      shouldFail: json['shouldFail'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentSnoozeCount': currentSnoozeCount,
      'shouldFail': shouldFail,
    };
  }
}
