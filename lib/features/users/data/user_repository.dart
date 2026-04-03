import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../domain/user_model.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.read(dioProvider));
});

final usersProvider = FutureProvider<List<UserModel>>((ref) async {
  return ref.read(userRepositoryProvider).getUsers();
});

class UserRepository {
  final Dio dio;

  UserRepository(this.dio);

  Future<List<UserModel>> getUsers() async {
    final response = await dio.get('/users');
    final body = response.data as Map<String, dynamic>;

    if (body['success'] != true) {
      throw Exception(body['error'] ?? 'Failed to load users');
    }

    final data = body['data'] as List<dynamic>;
    return data
        .map((item) => UserModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> createUser({
    required String username,
    required String password,
    required String role,
  }) async {
    final response = await dio.post(
      '/users',
      data: {'username': username, 'password': password, 'role': role},
    );

    final body = response.data as Map<String, dynamic>;
    if (body['success'] != true) {
      throw Exception(body['error'] ?? 'Failed to create user');
    }
  }

  Future<void> resetPassword({
    required int userId,
    required String newPassword,
  }) async {
    final response = await dio.post(
      '/users/$userId/reset-password',
      data: {'new_password': newPassword},
    );

    final body = response.data as Map<String, dynamic>;
    if (body['success'] != true) {
      throw Exception(body['error'] ?? 'Failed to reset password');
    }
  }

  Future<void> deactivateUser(int userId) async {
    final response = await dio.patch('/users/$userId/deactivate');
    final body = response.data as Map<String, dynamic>;

    if (body['success'] != true) {
      throw Exception(body['error'] ?? 'Failed to deactivate user');
    }
  }

  Future<void> activateUser(int userId) async {
    final response = await dio.patch('/users/$userId/activate');
    final body = response.data as Map<String, dynamic>;

    if (body['success'] != true) {
      throw Exception(body['error'] ?? 'Failed to activate user');
    }
  }
}
