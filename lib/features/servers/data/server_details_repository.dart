import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sermon_mobile/features/servers/domain/server_threshold_model.dart';

import '../../../core/network/dio_provider.dart';
import '../domain/current_metrics_model.dart';
import '../domain/metric_history_item.dart';
import '../domain/server_model.dart';

final serverDetailsRepositoryProvider = Provider<ServerDetailsRepository>((
  ref,
) {
  return ServerDetailsRepository(ref.read(dioProvider));
});
final serverThresholdsProvider =
    FutureProvider.family<List<ServerThresholdModel>, int>((
      ref,
      serverId,
    ) async {
      return ref
          .read(serverDetailsRepositoryProvider)
          .getServerThresholds(serverId);
    });
final serverByIdProvider = FutureProvider.family<ServerModel, int>((
  ref,
  serverId,
) async {
  return ref.read(serverDetailsRepositoryProvider).getServerById(serverId);
});

final currentMetricsProvider = FutureProvider.family<CurrentMetricsModel, int>((
  ref,
  serverId,
) async {
  return ref.read(serverDetailsRepositoryProvider).getCurrentMetrics(serverId);
});

final cpuHistoryProvider = FutureProvider.family<List<MetricHistoryItem>, int>((
  ref,
  serverId,
) async {
  return ref
      .read(serverDetailsRepositoryProvider)
      .getMetricHistory(serverId: serverId, metric: 'cpu', period: '1h');
});

final ramHistoryProvider = FutureProvider.family<List<MetricHistoryItem>, int>((
  ref,
  serverId,
) async {
  return ref
      .read(serverDetailsRepositoryProvider)
      .getMetricHistory(serverId: serverId, metric: 'ram', period: '1h');
});

final diskHistoryProvider = FutureProvider.family<List<MetricHistoryItem>, int>(
  (ref, serverId) async {
    return ref
        .read(serverDetailsRepositoryProvider)
        .getMetricHistory(serverId: serverId, metric: 'disk', period: '1h');
  },
);

class ServerDetailsRepository {
  final Dio dio;

  ServerDetailsRepository(this.dio);
  Future<List<ServerThresholdModel>> getServerThresholds(int serverId) async {
    final response = await dio.get('/servers/$serverId/thresholds');
    final body = response.data as Map<String, dynamic>;

    if (body['success'] != true) {
      throw Exception(body['error'] ?? 'Failed to load thresholds');
    }

    final data = body['data'] as List<dynamic>;
    return data
        .map(
          (item) => ServerThresholdModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> updateServerThreshold({
    required int serverId,
    required String metricType,
    required int warningValue,
    required int criticalValue,
  }) async {
    final response = await dio.put(
      '/servers/$serverId/thresholds/$metricType',
      data: {'warning_value': warningValue, 'critical_value': criticalValue},
    );

    final body = response.data as Map<String, dynamic>;
    if (body['success'] != true) {
      throw Exception(body['error'] ?? 'Failed to update threshold');
    }
  }

  Future<ServerModel> getServerById(int serverId) async {
    final response = await dio.get('/servers/$serverId');
    final body = response.data as Map<String, dynamic>;

    if (body['success'] != true) {
      throw Exception(body['error'] ?? 'Failed to load server');
    }

    return ServerModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<CurrentMetricsModel> getCurrentMetrics(int serverId) async {
    final response = await dio.get('/servers/$serverId/metrics/current');
    final body = response.data as Map<String, dynamic>;

    if (body['success'] != true) {
      throw Exception(body['error'] ?? 'Failed to load current metrics');
    }

    return CurrentMetricsModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<List<MetricHistoryItem>> getMetricHistory({
    required int serverId,
    required String metric,
    required String period,
  }) async {
    final response = await dio.get(
      '/servers/$serverId/metrics/history',
      queryParameters: {'metric': metric, 'period': period},
    );

    final body = response.data as Map<String, dynamic>;

    if (body['success'] != true) {
      throw Exception(body['error'] ?? 'Failed to load metric history');
    }

    final data = body['data'] as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>;

    return items
        .map((item) => MetricHistoryItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
