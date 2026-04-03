import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sermon_mobile/features/auth/data/auth_state_controller.dart';

import '../../home/home_screen.dart';

import 'change_password_screen.dart';
import 'login_screen.dart';

class AuthGateScreen extends ConsumerWidget {
  const AuthGateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateControllerProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const LoginScreen();
        }

        if (user.mustChangePassword) {
          return ChangePasswordScreen(user: user);
        }

        return const HomeScreen();
      },
      error: (error, stackTrace) =>
          Scaffold(body: Center(child: Text('Ошибка инициализации: $error'))),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}
