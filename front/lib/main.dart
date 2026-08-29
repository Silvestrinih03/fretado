import 'package:flutter/material.dart';

import 'app/design_system/design_system.dart';
import 'core/enums/home_profile.dart';
import 'core/navigation/app_navigator.dart';
import 'core/services/myself/services/myself_service.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/reset_password_page.dart';
import 'features/home/presentation/pages/home_page.dart';

void main() {
  runApp(const FretadoApp());
}

class FretadoApp extends StatelessWidget {
  const FretadoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
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
      onGenerateRoute: (settings) {
        final String? resetPasswordToken =
            _extractResetPasswordTokenFromRoute(settings.name) ??
            _extractResetPasswordToken(Uri.base);

        if (resetPasswordToken != null) {
          return MaterialPageRoute<void>(
            builder: (_) => ResetPasswordPage(token: resetPasswordToken),
            settings: settings,
          );
        }

        return MaterialPageRoute<void>(
          builder: (_) => const SessionGate(),
          settings: settings,
        );
      },
    );
  }
}

String? _extractResetPasswordTokenFromRoute(String? routeName) {
  if (routeName == null || routeName.isEmpty) {
    return null;
  }

  final Uri routeUri = Uri.parse(routeName);
  return _extractResetPasswordToken(routeUri);
}

String? _extractResetPasswordToken(Uri uri) {
  final String? queryToken = uri.queryParameters['token'];
  if (_isResetPasswordPath(uri.path) || _isRootPath(uri.path)) {
    if (queryToken != null && queryToken.trim().isNotEmpty) {
      return queryToken;
    }
  }

  final String fragment = uri.fragment;
  if (fragment.isEmpty) {
    return null;
  }

  final Uri fragmentUri = Uri.parse(
    fragment.startsWith('/') ? fragment : '/$fragment',
  );

  if (_isResetPasswordPath(fragmentUri.path)) {
    return fragmentUri.queryParameters['token'];
  }

  return null;
}

bool _isResetPasswordPath(String path) {
  final String normalizedPath = path
      .toLowerCase()
      .replaceAll(RegExp(r'^/+'), '')
      .replaceAll(RegExp(r'/+$'), '');
  return normalizedPath == 'reset-password';
}

bool _isRootPath(String path) {
  return path.isEmpty || path == '/';
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
    _sessionFuture = _loadSession();
  }

  Future<void> _loadSession() async {
    await _myselfService.loadSavedSession();
    if (!_myselfService.hasValidAccessToken) {
      await _myselfService.logout();
    }
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

        if (userId == null ||
            userTypeId == null ||
            !_myselfService.hasValidAccessToken) {
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
