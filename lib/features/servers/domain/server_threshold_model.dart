class ServerThresholdModel {
  final int id;
  final int serverId;
  final String metricType;
  final int warningValue;
  final int criticalValue;

  ServerThresholdModel({
    required this.id,
    required this.serverId,
    required this.metricType,
    required this.warningValue,
    required this.criticalValue,
  });

  factory ServerThresholdModel.fromJson(Map<String, dynamic> json) {
    return ServerThresholdModel(
      id: json['id'] as int,
      serverId: json['server_id'] as int,
      metricType: json['metric_type'] as String,
      warningValue: json['warning_value'] as int,
      criticalValue: json['critical_value'] as int,
    );
  }
}
