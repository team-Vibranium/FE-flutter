// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mission_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MissionResult _$MissionResultFromJson(Map<String, dynamic> json) =>
    MissionResult(
      id: (json['id'] as num).toInt(),
      callLogId: (json['callLogId'] as num).toInt(),
      missionType: $enumDecode(_$MissionTypeEnumMap, json['missionType']),
      success: json['success'] as bool,
    );

Map<String, dynamic> _$MissionResultToJson(MissionResult instance) =>
    <String, dynamic>{
      'id': instance.id,
      'callLogId': instance.callLogId,
      'missionType': _$MissionTypeEnumMap[instance.missionType]!,
      'success': instance.success,
    };

const _$MissionTypeEnumMap = {MissionType.puzzle: 'PUZZLE'};
