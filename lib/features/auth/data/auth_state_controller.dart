import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:sermon_mobile/core/network/dio_provider.dart';

import '../data/auth_repository.dart';
import '../domain/auth_user.dart';

final authStateControllerProvider =
    StateNotifierProvider<AuthStateController, AsyncValue<AuthUser?>>((ref) {
      return AuthStateController(ref);
    });

class AuthStateController extends StateNotifier<AsyncValue<AuthUser?>> {
  final Ref ref;

  AuthStateController(this.ref) : super(const AsyncLoading()) {
    checkAuth();
  }

  Future<void> checkAuth() async {
    state = const AsyncLoading();

    try {
      final token = await ref.read(authStorageProvider).getToken();

      if (token == null || token.isEmpty) {
        state = const AsyncData(null);
        return;
      }

      final user = await ref.read(authRepositoryProvider).getMe();
      state = AsyncData(user);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }

  void setAuthenticated(AuthUser user) {
    state = AsyncData(user);
  }

  void updateUser(AuthUser user) {
    state = AsyncData(user);
  }
}
