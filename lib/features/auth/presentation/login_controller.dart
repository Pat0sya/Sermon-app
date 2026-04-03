import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../data/auth_repository.dart';
import '../domain/auth_user.dart';

final loginControllerProvider =
    StateNotifierProvider<LoginController, AsyncValue<AuthUser?>>((ref) {
      return LoginController(ref);
    });

class LoginController extends StateNotifier<AsyncValue<AuthUser?>> {
  final Ref ref;

  LoginController(this.ref) : super(const AsyncData(null));

  Future<void> login({
    required String username,
    required String password,
  }) async {
    state = const AsyncLoading();

    try {
      final user = await ref
          .read(authRepositoryProvider)
          .login(username: username, password: password);
      print('LOGIN OK: ${user.username}');
      state = AsyncData(user);
    } catch (e, st) {
      print('LOGIN ERROR: $e');
      state = AsyncError(e, st);
    }
  }
}
