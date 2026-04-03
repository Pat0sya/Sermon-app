class MetricHistoryItem {
  final int id;
  final int serverId;
  final String metricType;
  final double metricValue;
  final DateTime collectedAt;

  MetricHistoryItem({
    required this.id,
    required this.serverId,
    required this.metricType,
    required this.metricValue,
    required this.collectedAt,
  });

  factory MetricHistoryItem.fromJson(Map<String, dynamic> json) {
    return MetricHistoryItem(
      id: json['id'] as int,
      serverId: json['server_id'] as int,
      metricType: json['metric_type'] as String,
      metricValue: (json['metric_value'] as num).toDouble(),
      collectedAt: DateTime.parse(json['collected_at'] as String),
    );
  }
}
