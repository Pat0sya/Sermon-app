import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sermon_mobile/core/theme/app_theme.dart';
import 'features/auth/presentation/auth_gate_screen.dart';

void main() {
  runApp(const ProviderScope(child: SermonApp()));
}

class SermonApp extends StatelessWidget {
  const SermonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SerMon',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const AuthGateScreen(),
    );
  }
}
