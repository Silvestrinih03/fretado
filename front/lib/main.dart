import 'package:flutter/material.dart';

import 'app/design_system/design_system.dart';
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
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);

        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: TextScaler.linear(0.92)),
          child: child ?? const SizedBox.shrink(),
        );
      },
      theme: ThemeData(
        useMaterial3: true,
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1F4E79)),
        inputDecorationTheme: InputDecorationTheme(
          errorMaxLines: 2,
          errorStyle: const TextStyle(
            color: FretColors.destructive600,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.25,
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: FretColors.destructive500,
              width: 1.2,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: FretColors.destructive600,
              width: 1.4,
            ),
          ),
        ),
      ),
      home: const LoginPage(),
    );
  }
}
