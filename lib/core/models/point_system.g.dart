// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'point_system.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PointTransaction _$PointTransactionFromJson(Map<String, dynamic> json) =>
    PointTransaction(
      id: (json['id'] as num).toInt(),
      type: $enumDecode(_$PointTypeEnumMap, json['type']),
      amount: (json['amount'] as num).toInt(),
      description: json['description'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      relatedAlarmId: json['relatedAlarmId'] as String?,
    );

Map<String, dynamic> _$PointTransactionToJson(PointTransaction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$PointTypeEnumMap[instance.type]!,
      'amount': instance.amount,
      'description': instance.description,
      'createdAt': instance.createdAt.toIso8601String(),
      'relatedAlarmId': instance.relatedAlarmId,
    };

const _$PointTypeEnumMap = {
  PointType.consumption: 'CONSUMPTION',
  PointType.grade: 'GRADE',
};

PointSystem _$PointSystemFromJson(Map<String, dynamic> json) => PointSystem(
  consumptionPoints: (json['consumptionPoints'] as num).toInt(),
  gradePoints: (json['gradePoints'] as num).toInt(),
  currentGrade: $enumDecode(_$UserGradeEnumMap, json['currentGrade']),
  recentTransactions: (json['recentTransactions'] as List<dynamic>)
      .map((e) => PointTransaction.fromJson(e as Map<String, dynamic>))
      .toList(),
  dailyGradePointsEarned: (json['dailyGradePointsEarned'] as num).toInt(),
  lastResetDate: DateTime.parse(json['lastResetDate'] as String),
);

Map<String, dynamic> _$PointSystemToJson(PointSystem instance) =>
    <String, dynamic>{
      'consumptionPoints': instance.consumptionPoints,
      'gradePoints': instance.gradePoints,
      'currentGrade': _$UserGradeEnumMap[instance.currentGrade]!,
      'recentTransactions': instance.recentTransactions,
      'dailyGradePointsEarned': instance.dailyGradePointsEarned,
      'lastResetDate': instance.lastResetDate.toIso8601String(),
    };

const _$UserGradeEnumMap = {
  UserGrade.beginner: 'BEGINNER',
  UserGrade.bronze: 'BRONZE',
  UserGrade.silver: 'SILVER',
  UserGrade.gold: 'GOLD',
  UserGrade.platinum: 'PLATINUM',
  UserGrade.diamond: 'DIAMOND',
  UserGrade.master: 'MASTER',
  UserGrade.grandmaster: 'GRANDMASTER',
  UserGrade.challenger: 'CHALLENGER',
};
