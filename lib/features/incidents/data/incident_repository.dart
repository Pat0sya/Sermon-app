import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../domain/incident_comment_model.dart';
import '../domain/incident_model.dart';

final incidentRepositoryProvider = Provider<IncidentRepository>((ref) {
  return IncidentRepository(ref.read(dioProvider));
});

final incidentsProvider = FutureProvider.family<List<IncidentModel>, String?>((
  ref,
  status,
) async {
  return ref.read(incidentRepositoryProvider).getIncidents(status: status);
});

final incidentByIdProvider = FutureProvider.family<IncidentModel, int>((
  ref,
  incidentId,
) async {
  return ref.read(incidentRepositoryProvider).getIncidentById(incidentId);
});

final incidentCommentsProvider =
    FutureProvider.family<List<IncidentCommentModel>, int>((
      ref,
      incidentId,
    ) async {
      return ref.read(incidentRepositoryProvider).getComments(incidentId);
    });

class IncidentRepository {
  final Dio dio;

  IncidentRepository(this.dio);

  Future<List<IncidentModel>> getIncidents({String? status}) async {
    final response = await dio.get(
      '/incidents',
      queryParameters: status != null && status.isNotEmpty
          ? {'status': status}
          : null,
    );

    final body = response.data as Map<String, dynamic>;
    if (body['success'] != true) {
      throw Exception(body['error'] ?? 'Failed to load incidents');
    }

    final data = body['data'] as List<dynamic>;
    return data
        .map((item) => IncidentModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<IncidentModel> getIncidentById(int incidentId) async {
    final response = await dio.get('/incidents/$incidentId');
    final body = response.data as Map<String, dynamic>;

    if (body['success'] != true) {
      throw Exception(body['error'] ?? 'Failed to load incident');
    }

    return IncidentModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<List<IncidentCommentModel>> getComments(int incidentId) async {
    final response = await dio.get('/incidents/$incidentId/comments');
    final body = response.data as Map<String, dynamic>;

    if (body['success'] != true) {
      throw Exception(body['error'] ?? 'Failed to load comments');
    }

    final data = body['data'] as List<dynamic>;
    return data
        .map(
          (item) => IncidentCommentModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> updateStatus({
    required int incidentId,
    required String status,
  }) async {
    final response = await dio.patch(
      '/incidents/$incidentId/status',
      data: {'status': status},
    );

    final body = response.data as Map<String, dynamic>;
    if (body['success'] != true) {
      throw Exception(body['error'] ?? 'Failed to update status');
    }
  }

  Future<void> addComment({
    required int incidentId,
    required String comment,
  }) async {
    final response = await dio.post(
      '/incidents/$incidentId/comments',
      data: {'comment': comment},
    );

    final body = response.data as Map<String, dynamic>;
    if (body['success'] != true) {
      throw Exception(body['error'] ?? 'Failed to add comment');
    }
  }
}
