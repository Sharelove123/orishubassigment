import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'features/auth/screens/login_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: PolsoHealthApp(),
    ),
  );
}

class PolsoHealthApp extends StatelessWidget {
  const PolsoHealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Polso Health',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
    );
  }
}
