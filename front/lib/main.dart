import 'package:flutter/material.dart';

import 'app/design_system/design_system.dart';
import 'core/enums/home_profile.dart';
import 'core/services/myself/services/myself_service.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/home/presentation/pages/home_page.dart';

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
      home: const SessionGate(),
    );
  }
}

class SessionGate extends StatefulWidget {
  const SessionGate({super.key});

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  late final Future<void> _sessionFuture;
  final MyselfService _myselfService = MyselfService();

  @override
  void initState() {
    super.initState();
    _sessionFuture = _myselfService.loadSavedSession();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _sessionFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: FretColors.white,
            body: Center(
              child: CircularProgressIndicator(
                color: FretColors.loginFooterLink,
              ),
            ),
          );
        }

        final int? userId = _myselfService.currentUserId;
        final int? userTypeId = _myselfService.currentUserTypeId;

        if (userId == null || userTypeId == null) {
          return const LoginPage();
        }

        return HomePage(
          profile: HomeProfileMapper.fromUserTypeId(userTypeId),
          userId: userId,
          userTypeId: userTypeId,
        );
      },
    );
  }
}
