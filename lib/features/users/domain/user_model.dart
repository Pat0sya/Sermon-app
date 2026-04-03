class UserModel {
  final int id;
  final String username;
  final String role;
  final bool mustChangePassword;
  final bool isActive;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.username,
    required this.role,
    required this.mustChangePassword,
    required this.isActive,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      username: json['username'] as String,
      role: json['role'] as String,
      mustChangePassword: json['must_change_password'] as bool,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
