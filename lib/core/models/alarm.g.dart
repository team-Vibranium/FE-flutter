// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alarm.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Alarm _$AlarmFromJson(Map<String, dynamic> json) => Alarm(
  id: (json['id'] as num).toInt(),
  time: json['time'] as String,
  days: (json['days'] as List<dynamic>).map((e) => e as String).toList(),
  type: $enumDecode(_$AlarmTypeEnumMap, json['type']),
  isEnabled: json['isEnabled'] as bool,
  tag: json['tag'] as String,
  successRate: (json['successRate'] as num).toInt(),
  backendAlarmId: (json['backendAlarmId'] as num?)?.toInt(),
);

Map<String, dynamic> _$AlarmToJson(Alarm instance) => <String, dynamic>{
  'id': instance.id,
  'time': instance.time,
  'days': instance.days,
  'type': _$AlarmTypeEnumMap[instance.type]!,
  'isEnabled': instance.isEnabled,
  'tag': instance.tag,
  'successRate': instance.successRate,
  'backendAlarmId': instance.backendAlarmId,
};

const _$AlarmTypeEnumMap = {AlarmType.normal: 'NORMAL', AlarmType.call: 'CALL'};
