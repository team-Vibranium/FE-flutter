import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final int id;
  final String email;
  final String nickname;
  final int points;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.email,
    required this.nickname,
    required this.points,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  User copyWith({
    int? id,
    String? email,
    String? nickname,
    int? points,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      nickname: nickname ?? this.nickname,
      points: points ?? this.points,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
