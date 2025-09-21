import 'package:json_annotation/json_annotation.dart';

part 'mission_result.g.dart';

enum MissionType {
  @JsonValue('PUZZLE')
  puzzle,
}

@JsonSerializable()
class MissionResult {
  final int id;
  final int callLogId;
  final MissionType missionType;
  final bool success;

  const MissionResult({
    required this.id,
    required this.callLogId,
    required this.missionType,
    required this.success,
  });

  factory MissionResult.fromJson(Map<String, dynamic> json) => _$MissionResultFromJson(json);
  Map<String, dynamic> toJson() => _$MissionResultToJson(this);
}
