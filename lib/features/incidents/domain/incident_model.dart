class IncidentServerInfo {
  final int id;
  final String name;
  final String host;
  final String os;
  final bool isActive;
  final String status;
  final dynamic lastSeenAt;

  IncidentServerInfo({
    required this.id,
    required this.name,
    required this.host,
    required this.os,
    required this.isActive,
    required this.status,
    required this.lastSeenAt,
  });

  factory IncidentServerInfo.fromJson(Map<String, dynamic> json) {
    return IncidentServerInfo(
      id: json['id'] as int,
      name: json['name'] as String,
      host: json['host'] as String,
      os: json['os'] as String,
      isActive: json['is_active'] as bool,
      status: json['status'] as String,
      lastSeenAt: json['last_seen_at'],
    );
  }
}

class IncidentModel {
  final int id;
  final int serverId;
  final IncidentServerInfo server;
  final String metricType;
  final String status;
  final double thresholdValue;
  final double actualValue;
  final String message;
  final DateTime startedAt;
  final DateTime? closedAt;

  IncidentModel({
    required this.id,
    required this.serverId,
    required this.server,
    required this.metricType,
    required this.status,
    required this.thresholdValue,
    required this.actualValue,
    required this.message,
    required this.startedAt,
    required this.closedAt,
  });

  factory IncidentModel.fromJson(Map<String, dynamic> json) {
    return IncidentModel(
      id: json['id'] as int,
      serverId: json['server_id'] as int,
      server: IncidentServerInfo.fromJson(
        json['server'] as Map<String, dynamic>,
      ),
      metricType: json['metric_type'] as String,
      status: json['status'] as String,
      thresholdValue: (json['threshold_value'] as num).toDouble(),
      actualValue: (json['actual_value'] as num).toDouble(),
      message: json['message'] as String,
      startedAt: DateTime.parse(json['started_at'] as String),
      closedAt: json['closed_at'] != null
          ? DateTime.parse(json['closed_at'] as String)
          : null,
    );
  }
}
