class ThresholdModel {
  final int id;
  final String metricType;
  final int warningValue;
  final int criticalValue;

  ThresholdModel({
    required this.id,
    required this.metricType,
    required this.warningValue,
    required this.criticalValue,
  });

  factory ThresholdModel.fromJson(Map<String, dynamic> json) {
    return ThresholdModel(
      id: json['id'] as int,
      metricType: json['metric_type'] as String,
      warningValue: json['warning_value'] as int,
      criticalValue: json['critical_value'] as int,
    );
  }
}
