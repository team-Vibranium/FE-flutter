// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_alarm.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LocalAlarm _$LocalAlarmFromJson(Map<String, dynamic> json) => LocalAlarm(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  hour: (json['hour'] as num).toInt(),
  minute: (json['minute'] as num).toInt(),
  isEnabled: json['isEnabled'] as bool? ?? true,
  repeatDays:
      (json['repeatDays'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      const [],
  soundPath: json['soundPath'] as String?,
  vibrate: json['vibrate'] as bool? ?? true,
  snoozeEnabled: json['snoozeEnabled'] as bool? ?? true,
  snoozeInterval: (json['snoozeInterval'] as num?)?.toInt() ?? 5,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  label: json['label'] as String?,
  type: json['type'] as String? ?? 'normal',
);

Map<String, dynamic> _$LocalAlarmToJson(LocalAlarm instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'hour': instance.hour,
      'minute': instance.minute,
      'isEnabled': instance.isEnabled,
      'repeatDays': instance.repeatDays,
      'soundPath': instance.soundPath,
      'vibrate': instance.vibrate,
      'snoozeEnabled': instance.snoozeEnabled,
      'snoozeInterval': instance.snoozeInterval,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'label': instance.label,
      'type': instance.type,
    };
