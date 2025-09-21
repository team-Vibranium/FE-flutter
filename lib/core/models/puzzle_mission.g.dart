// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'puzzle_mission.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PuzzleMission _$PuzzleMissionFromJson(Map<String, dynamic> json) =>
    PuzzleMission(
      id: (json['id'] as num).toInt(),
      type: $enumDecode(_$PuzzleTypeEnumMap, json['type']),
      question: json['question'] as String,
      options: (json['options'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      correctAnswer: json['correctAnswer'] as String,
      timeLimitSeconds: (json['timeLimitSeconds'] as num).toInt(),
    );

Map<String, dynamic> _$PuzzleMissionToJson(PuzzleMission instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$PuzzleTypeEnumMap[instance.type]!,
      'question': instance.question,
      'options': instance.options,
      'correctAnswer': instance.correctAnswer,
      'timeLimitSeconds': instance.timeLimitSeconds,
    };

const _$PuzzleTypeEnumMap = {
  PuzzleType.numberSequence: 'numberSequence',
  PuzzleType.patternMatch: 'patternMatch',
  PuzzleType.colorSequence: 'colorSequence',
};
