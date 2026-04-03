class AuthUser {
  final int id;
  final String username;
  final String role;
  final bool mustChangePassword;
  final bool isActive;

  AuthUser({
    required this.id,
    required this.username,
    required this.role,
    required this.mustChangePassword,
    required this.isActive,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as int,
      username: json['username'] as String,
      role: json['role'] as String,
      mustChangePassword: (json['must_change_password'] ?? false) as bool,
      isActive: (json['is_active'] ?? true) as bool,
    );
  }
}
