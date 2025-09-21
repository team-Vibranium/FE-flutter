import 'package:json_annotation/json_annotation.dart';

part 'alarm.g.dart';

enum AlarmType {
  @JsonValue('NORMAL')
  normal,
  @JsonValue('CALL')
  call,
}

@JsonSerializable()
class Alarm {
  final int id;
  final String time;
  final List<String> days;
  final AlarmType type;
  final bool isEnabled;
  final String tag;
  final int successRate;

  const Alarm({
    required this.id,
    required this.time,
    required this.days,
    required this.type,
    required this.isEnabled,
    required this.tag,
    required this.successRate,
  });

  factory Alarm.fromJson(Map<String, dynamic> json) => _$AlarmFromJson(json);
  Map<String, dynamic> toJson() => _$AlarmToJson(this);

  Alarm copyWith({
    int? id,
    String? time,
    List<String>? days,
    AlarmType? type,
    bool? isEnabled,
    String? tag,
    int? successRate,
  }) {
    return Alarm(
      id: id ?? this.id,
      time: time ?? this.time,
      days: days ?? this.days,
      type: type ?? this.type,
      isEnabled: isEnabled ?? this.isEnabled,
      tag: tag ?? this.tag,
      successRate: successRate ?? this.successRate,
    );
  }

  String get typeDisplayName {
    switch (type) {
      case AlarmType.normal:
        return '일반알람';
      case AlarmType.call:
        return '전화알람';
    }
  }
}
