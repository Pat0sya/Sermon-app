class ServerModel {
  final int id;
  final String name;
  final String host;
  final String os;
  final String description;
  final bool isActive;
  final String status;
  final dynamic lastSeenAt;

  ServerModel({
    required this.id,
    required this.name,
    required this.host,
    required this.os,
    required this.description,
    required this.isActive,
    required this.status,
    required this.lastSeenAt,
  });

  factory ServerModel.fromJson(Map<String, dynamic> json) {
    return ServerModel(
      id: json['id'] as int,
      name: json['name'] as String,
      host: json['host'] as String,
      os: json['os'] as String,
      description: (json['description'] ?? '') as String,
      isActive: json['is_active'] as bool,
      status: json['status'] as String,
      lastSeenAt: json['last_seen_at'],
    );
  }
}
