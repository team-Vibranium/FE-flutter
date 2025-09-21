class UserModel {
  final int points;
  final String selectedAvatar;

  const UserModel({
    required this.points,
    required this.selectedAvatar,
  });

  UserModel copyWith({
    int? points,
    String? selectedAvatar,
  }) {
    return UserModel(
      points: points ?? this.points,
      selectedAvatar: selectedAvatar ?? this.selectedAvatar,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'points': points,
      'selectedAvatar': selectedAvatar,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      points: json['points'] ?? 0,
      selectedAvatar: json['selectedAvatar'] ?? 'default',
    );
  }
}
