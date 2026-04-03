import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../../../core/storage/auth_storage.dart';
import '../domain/auth_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    dio: ref.read(dioProvider),
    storage: ref.read(authStorageProvider),
  );
});

class AuthRepository {
  final Dio dio;
  final AuthStorage storage;

  AuthRepository({required this.dio, required this.storage});

  Future<AuthUser> login({
    required String username,
    required String password,
  }) async {
    final response = await dio.post(
      '/auth/login',
      data: {'username': username, 'password': password},
    );

    final body = response.data as Map<String, dynamic>;

    String token;
    Map<String, dynamic> userJson;

    if (body.containsKey('success')) {
      final success = body['success'] as bool? ?? false;
      if (!success) {
        throw Exception(body['error'] ?? 'Login failed');
      }

      final data = body['data'] as Map<String, dynamic>;
      token = data['token'] as String;
      userJson = data['user'] as Map<String, dynamic>;
    } else {
      token = body['token'] as String;
      userJson = body['user'] as Map<String, dynamic>;
    }

    await storage.saveToken(token);

    return AuthUser.fromJson(userJson);
  }

  Future<AuthUser> getMe() async {
    final response = await dio.get('/auth/me');
    final body = response.data as Map<String, dynamic>;

    if (body['success'] != true) {
      throw Exception(body['error'] ?? 'Failed to get user');
    }

    final data = body['data'] as Map<String, dynamic>;
    final userJson = data['user'] as Map<String, dynamic>;

    return AuthUser.fromJson(userJson);
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final response = await dio.post(
      '/auth/change-password',
      data: {'old_password': oldPassword, 'new_password': newPassword},
    );

    final body = response.data as Map<String, dynamic>;
    if (body['success'] != true) {
      throw Exception(body['error'] ?? 'Failed to change password');
    }
  }

  Future<void> logout() async {
    await storage.clearToken();
  }
}
