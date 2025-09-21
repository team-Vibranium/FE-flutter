import 'package:json_annotation/json_annotation.dart';

part 'call_log.g.dart';

enum CallResult {
  @JsonValue('SUCCESS')
  success,
  @JsonValue('FAIL_NO_TALK')
  failNoTalk,
  @JsonValue('FAIL_SNOOZE')
  failSnooze,
}

@JsonSerializable()
class CallLog {
  final int id;
  final int userId;
  final DateTime? callStart;
  final DateTime? callEnd;
  final CallResult result;
  final int snoozeCount;

  const CallLog({
    required this.id,
    required this.userId,
    this.callStart,
    this.callEnd,
    required this.result,
    required this.snoozeCount,
  });

  factory CallLog.fromJson(Map<String, dynamic> json) => _$CallLogFromJson(json);
  Map<String, dynamic> toJson() => _$CallLogToJson(this);
}
