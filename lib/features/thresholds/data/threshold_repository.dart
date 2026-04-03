import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../domain/threshold_model.dart';

final thresholdRepositoryProvider = Provider<ThresholdRepository>((ref) {
  return ThresholdRepository(ref.read(dioProvider));
});

final thresholdsProvider = FutureProvider<List<ThresholdModel>>((ref) async {
  return ref.read(thresholdRepositoryProvider).getThresholds();
});

class ThresholdRepository {
  final Dio dio;

  ThresholdRepository(this.dio);

  Future<List<ThresholdModel>> getThresholds() async {
    final response = await dio.get('/thresholds');
    final body = response.data as Map<String, dynamic>;

    if (body['success'] != true) {
      throw Exception(body['error'] ?? 'Failed to load thresholds');
    }

    final data = body['data'] as List<dynamic>;
    return data
        .map((item) => ThresholdModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateThreshold({
    required String metricType,
    required int warningValue,
    required int criticalValue,
  }) async {
    final response = await dio.put(
      '/thresholds/$metricType',
      data: {'warning_value': warningValue, 'critical_value': criticalValue},
    );

    final body = response.data as Map<String, dynamic>;
    if (body['success'] != true) {
      throw Exception(body['error'] ?? 'Failed to update threshold');
    }
  }
}
