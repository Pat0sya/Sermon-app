class CurrentMetricsModel {
  final int serverId;
  final double cpuUsage;
  final double ramUsage;
  final double diskUsage;
  final DateTime collectedAt;

  CurrentMetricsModel({
    required this.serverId,
    required this.cpuUsage,
    required this.ramUsage,
    required this.diskUsage,
    required this.collectedAt,
  });

  factory CurrentMetricsModel.fromJson(Map<String, dynamic> json) {
    return CurrentMetricsModel(
      serverId: json['server_id'] as int,
      cpuUsage: (json['cpu_usage'] as num).toDouble(),
      ramUsage: (json['ram_usage'] as num).toDouble(),
      diskUsage: (json['disk_usage'] as num).toDouble(),
      collectedAt: DateTime.parse(json['collected_at'] as String),
    );
  }
}
