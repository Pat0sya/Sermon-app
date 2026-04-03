import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sermon_mobile/features/servers/domain/agent_token_response.dart';

import '../../../core/network/dio_provider.dart';
import '../domain/server_model.dart';

final serverRepositoryProvider = Provider<ServerRepository>((ref) {
  return ServerRepository(ref.read(dioProvider));
});

final serversProvider = FutureProvider<List<ServerModel>>((ref) async {
  return ref.read(serverRepositoryProvider).getServers();
});

class ServerRepository {
  final Dio dio;

  ServerRepository(this.dio);

  Future<List<ServerModel>> getServers() async {
    final response = await dio.get('/servers');

    final body = response.data as Map<String, dynamic>;
    final success = body['success'] as bool? ?? false;

    if (!success) {
      throw Exception(body['error'] ?? 'Failed to load servers');
    }

    final data = body['data'] as List<dynamic>;

    return data
        .map((item) => ServerModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<AgentTokenResponse> createServer({
    required String name,
    required String host,
    required String os,
    required String description,
  }) async {
    final response = await dio.post(
      '/servers',
      data: {'name': name, 'host': host, 'os': os, 'description': description},
    );

    final body = response.data as Map<String, dynamic>;
    if (body['success'] != true) {
      throw Exception(body['error'] ?? 'Failed to create server');
    }

    final data = body['data'] as Map<String, dynamic>;
    return AgentTokenResponse.fromCreateResponse(data);
  }

  Future<AgentTokenResponse> regenerateAgentToken(int serverId) async {
    final response = await dio.post(
      '/servers/$serverId/regenerate-agent-token',
    );

    final body = response.data as Map<String, dynamic>;
    if (body['success'] != true) {
      throw Exception(body['error'] ?? 'Failed to regenerate agent token');
    }

    final data = body['data'] as Map<String, dynamic>;
    return AgentTokenResponse.fromRegenerateResponse(data);
  }

  Future<void> updateServer({
    required int id,
    required String name,
    required String host,
    required String os,
    required String description,
  }) async {
    final response = await dio.patch(
      '/servers/$id',
      data: {'name': name, 'host': host, 'os': os, 'description': description},
    );

    final body = response.data as Map<String, dynamic>;
    if (body['success'] != true) {
      throw Exception(body['error'] ?? 'Failed to update server');
    }
  }

  Future<void> deactivateServer(int id) async {
    final response = await dio.patch('/servers/$id/deactivate');
    final body = response.data as Map<String, dynamic>;
    if (body['success'] != true) {
      throw Exception(body['error'] ?? 'Failed to deactivate server');
    }
  }

  Future<void> activateServer(int id) async {
    final response = await dio.patch('/servers/$id/activate');
    final body = response.data as Map<String, dynamic>;
    if (body['success'] != true) {
      throw Exception(body['error'] ?? 'Failed to activate server');
    }
  }
}
