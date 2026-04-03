class IncidentCommentUser {
  final int id;
  final String username;
  final String role;

  IncidentCommentUser({
    required this.id,
    required this.username,
    required this.role,
  });

  factory IncidentCommentUser.fromJson(Map<String, dynamic> json) {
    return IncidentCommentUser(
      id: json['id'] as int,
      username: json['username'] as String,
      role: (json['role'] ?? '') as String,
    );
  }
}

class IncidentCommentModel {
  final int id;
  final int incidentId;
  final int userId;
  final String comment;
  final DateTime createdAt;
  final IncidentCommentUser? user;

  IncidentCommentModel({
    required this.id,
    required this.incidentId,
    required this.userId,
    required this.comment,
    required this.createdAt,
    required this.user,
  });

  factory IncidentCommentModel.fromJson(Map<String, dynamic> json) {
    return IncidentCommentModel(
      id: json['id'] as int,
      incidentId: json['incident_id'] as int,
      userId: json['user_id'] as int,
      comment: json['comment'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      user: json['user'] != null
          ? IncidentCommentUser.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }
}
