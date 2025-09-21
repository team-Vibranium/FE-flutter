// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'call_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CallLog _$CallLogFromJson(Map<String, dynamic> json) => CallLog(
  id: (json['id'] as num).toInt(),
  userId: (json['userId'] as num).toInt(),
  callStart: json['callStart'] == null
      ? null
      : DateTime.parse(json['callStart'] as String),
  callEnd: json['callEnd'] == null
      ? null
      : DateTime.parse(json['callEnd'] as String),
  result: $enumDecode(_$CallResultEnumMap, json['result']),
  snoozeCount: (json['snoozeCount'] as num).toInt(),
);

Map<String, dynamic> _$CallLogToJson(CallLog instance) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'callStart': instance.callStart?.toIso8601String(),
  'callEnd': instance.callEnd?.toIso8601String(),
  'result': _$CallResultEnumMap[instance.result]!,
  'snoozeCount': instance.snoozeCount,
};

const _$CallResultEnumMap = {
  CallResult.success: 'SUCCESS',
  CallResult.failNoTalk: 'FAIL_NO_TALK',
  CallResult.failSnooze: 'FAIL_SNOOZE',
};
