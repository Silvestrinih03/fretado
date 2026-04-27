import 'package:flutter/material.dart';

import 'features/auth/presentation/pages/login_page.dart';

void main() {
  runApp(const FretadoApp());
}

class FretadoApp extends StatelessWidget {
  const FretadoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fretado',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1F4E79)),
      ),
      home: const LoginPage(),
    );
  }
}
