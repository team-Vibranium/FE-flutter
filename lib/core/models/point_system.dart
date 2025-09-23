import 'package:json_annotation/json_annotation.dart';

part 'point_system.g.dart';

/// 포인트 타입 구분
enum PointType {
  @JsonValue('CONSUMPTION')
  consumption, // 소비 포인트 (캐릭터 구매용)
  @JsonValue('GRADE')
  grade, // 등급 포인트 (티어 시스템용)
}

/// 등급 시스템
enum UserGrade {
  @JsonValue('BEGINNER')
  beginner,
  @JsonValue('BRONZE')
  bronze,
  @JsonValue('SILVER')
  silver,
  @JsonValue('GOLD')
  gold,
  @JsonValue('PLATINUM')
  platinum,
  @JsonValue('DIAMOND')
  diamond,
  @JsonValue('MASTER')
  master,
  @JsonValue('GRANDMASTER')
  grandmaster,
  @JsonValue('CHALLENGER')
  challenger,
}

/// 포인트 내역
@JsonSerializable()
class PointTransaction {
  final int id;
  final PointType type;
  final int amount; // 양수: 획득, 음수: 소비
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

  factory PointTransaction.fromJson(Map<String, dynamic> json) => _$PointTransactionFromJson(json);
  Map<String, dynamic> toJson() => _$PointTransactionToJson(this);
}

/// 포인트 시스템 모델
@JsonSerializable()
class PointSystem {
  final int consumptionPoints; // 소비 포인트 (캐릭터 구매용)
  final int gradePoints; // 등급 포인트 (티어 시스템용)
  final UserGrade currentGrade;
  final List<PointTransaction> recentTransactions;
  final int dailyGradePointsEarned; // 오늘 획득한 등급 포인트
  final DateTime lastResetDate; // 마지막 일일 리셋 날짜

  const PointSystem({
    required this.consumptionPoints,
    required this.gradePoints,
    required this.currentGrade,
    required this.recentTransactions,
    required this.dailyGradePointsEarned,
    required this.lastResetDate,
  });

  factory PointSystem.fromJson(Map<String, dynamic> json) => _$PointSystemFromJson(json);
  Map<String, dynamic> toJson() => _$PointSystemToJson(this);

  /// 현재 등급에서 다음 등급까지 필요한 포인트
  int get pointsToNextGrade {
    final nextGradeRequirement = getGradeRequirement(getNextGrade());
    final currentGradeRequirement = getGradeRequirement(currentGrade);
    return nextGradeRequirement - (gradePoints - currentGradeRequirement);
  }

  /// 현재 등급에서의 진행률 (0.0 ~ 1.0)
  double get gradeProgress {
    if (currentGrade == UserGrade.challenger) return 1.0;
    
    final currentGradeRequirement = getGradeRequirement(currentGrade);
    final nextGradeRequirement = getGradeRequirement(getNextGrade());
    final currentProgress = gradePoints - currentGradeRequirement;
    final totalRequired = nextGradeRequirement - currentGradeRequirement;
    
    return (currentProgress / totalRequired).clamp(0.0, 1.0);
  }

  /// 오늘 더 획득할 수 있는 등급 포인트
  int get remainingDailyGradePoints {
    const maxDailyPoints = 30;
    return (maxDailyPoints - dailyGradePointsEarned).clamp(0, maxDailyPoints);
  }

  /// 다음 등급 가져오기
  UserGrade getNextGrade() {
    switch (currentGrade) {
      case UserGrade.beginner:
        return UserGrade.bronze;
      case UserGrade.bronze:
        return UserGrade.silver;
      case UserGrade.silver:
        return UserGrade.gold;
      case UserGrade.gold:
        return UserGrade.platinum;
      case UserGrade.platinum:
        return UserGrade.diamond;
      case UserGrade.diamond:
        return UserGrade.master;
      case UserGrade.master:
        return UserGrade.grandmaster;
      case UserGrade.grandmaster:
        return UserGrade.challenger;
      case UserGrade.challenger:
        return UserGrade.challenger;
    }
  }

  /// 등급별 필요 포인트 계산
  static int getGradeRequirement(UserGrade grade) {
    switch (grade) {
      case UserGrade.beginner:
        return 0;
      case UserGrade.bronze:
        return 100;
      case UserGrade.silver:
        return 300;
      case UserGrade.gold:
        return 600;
      case UserGrade.platinum:
        return 1600; // 600 + 1000
      case UserGrade.diamond:
        return 2600; // 1600 + 1000
      case UserGrade.master:
        return 3600; // 2600 + 1000
      case UserGrade.grandmaster:
        return 4600; // 3600 + 1000
      case UserGrade.challenger:
        return 5600; // 4600 + 1000
    }
  }

  /// 포인트로 등급 계산
  static UserGrade calculateGradeFromPoints(int gradePoints) {
    if (gradePoints >= getGradeRequirement(UserGrade.challenger)) return UserGrade.challenger;
    if (gradePoints >= getGradeRequirement(UserGrade.grandmaster)) return UserGrade.grandmaster;
    if (gradePoints >= getGradeRequirement(UserGrade.master)) return UserGrade.master;
    if (gradePoints >= getGradeRequirement(UserGrade.diamond)) return UserGrade.diamond;
    if (gradePoints >= getGradeRequirement(UserGrade.platinum)) return UserGrade.platinum;
    if (gradePoints >= getGradeRequirement(UserGrade.gold)) return UserGrade.gold;
    if (gradePoints >= getGradeRequirement(UserGrade.silver)) return UserGrade.silver;
    if (gradePoints >= getGradeRequirement(UserGrade.bronze)) return UserGrade.bronze;
    return UserGrade.beginner;
  }

  /// 등급 표시명
  String get gradeDisplayName {
    switch (currentGrade) {
      case UserGrade.beginner:
        return '비기너';
      case UserGrade.bronze:
        return '브론즈';
      case UserGrade.silver:
        return '실버';
      case UserGrade.gold:
        return '골드';
      case UserGrade.platinum:
        return '플래티넘';
      case UserGrade.diamond:
        return '다이아몬드';
      case UserGrade.master:
        return '마스터';
      case UserGrade.grandmaster:
        return '그랜드마스터';
      case UserGrade.challenger:
        return '챌린저';
    }
  }

  /// 포인트 추가
  PointSystem addPoints({
    required PointType type,
    required int amount,
    required String description,
    String? relatedAlarmId,
  }) {
    final now = DateTime.now();
    final isNewDay = lastResetDate.day != now.day || 
                     lastResetDate.month != now.month || 
                     lastResetDate.year != now.year;

    // 일일 리셋 처리
    final newDailyPoints = isNewDay ? 0 : dailyGradePointsEarned;
    final newResetDate = isNewDay ? now : lastResetDate;

    // 등급 포인트의 경우 일일 제한 확인
    int actualAmount = amount;
    if (type == PointType.grade && amount > 0) {
      final remainingDaily = 30 - newDailyPoints;
      actualAmount = amount.clamp(0, remainingDaily);
    }

    final newTransaction = PointTransaction(
      id: DateTime.now().millisecondsSinceEpoch,
      type: type,
      amount: actualAmount,
      description: description,
      createdAt: now,
      relatedAlarmId: relatedAlarmId,
    );

    final newTransactions = [newTransaction, ...recentTransactions.take(19)].toList();

    final newConsumptionPoints = type == PointType.consumption 
        ? consumptionPoints + actualAmount
        : consumptionPoints;
    final newGradePoints = type == PointType.grade 
        ? gradePoints + actualAmount
        : gradePoints;
    
    final newGrade = calculateGradeFromPoints(newGradePoints);
    final newDailyGradePoints = type == PointType.grade && actualAmount > 0
        ? newDailyPoints + actualAmount
        : newDailyPoints;

    return PointSystem(
      consumptionPoints: newConsumptionPoints,
      gradePoints: newGradePoints,
      currentGrade: newGrade,
      recentTransactions: newTransactions,
      dailyGradePointsEarned: newDailyGradePoints,
      lastResetDate: newResetDate,
    );
  }

  PointSystem copyWith({
    int? consumptionPoints,
    int? gradePoints,
    UserGrade? currentGrade,
    List<PointTransaction>? recentTransactions,
    int? dailyGradePointsEarned,
    DateTime? lastResetDate,
  }) {
    return PointSystem(
      consumptionPoints: consumptionPoints ?? this.consumptionPoints,
      gradePoints: gradePoints ?? this.gradePoints,
      currentGrade: currentGrade ?? this.currentGrade,
      recentTransactions: recentTransactions ?? this.recentTransactions,
      dailyGradePointsEarned: dailyGradePointsEarned ?? this.dailyGradePointsEarned,
      lastResetDate: lastResetDate ?? this.lastResetDate,
    );
  }
}
