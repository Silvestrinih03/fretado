import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/design_system/design_system.dart';
import '../../../../core/enums/home_profile.dart';
import '../../../../core/navigation/app_navigator.dart';
import '../../../../core/services/http_service.dart';
import '../../../../core/services/session/session_storage.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../data/datasources/driver_operations_datasource.dart';
import '../../data/repositories/driver_operations_repository_impl.dart';
import '../controllers/driver_offer_controller.dart';
import '../pages/driver_offer_page.dart';

/// Mantém a oferta pendente acima de toda a pilha de navegação do motorista.
class DriverOfferGate extends StatefulWidget {
  final Widget child;
  final DriverOfferController? controllerOverride;

  const DriverOfferGate({super.key, required this.child})
    : controllerOverride = null;

  @visibleForTesting
  const DriverOfferGate.forTesting({
    super.key,
    required this.child,
    required DriverOfferController controller,
  }) : controllerOverride = controller;

  @override
  State<DriverOfferGate> createState() => _DriverOfferGateState();
}

class _DriverOfferGateState extends State<DriverOfferGate> {
  final SessionStorage _session = SessionStorage.instance;

  HttpService? _httpService;
  DriverOfferController? _controller;
  int? _driverUserId;

  @override
  void initState() {
    super.initState();
    final controllerOverride = widget.controllerOverride;
    if (controllerOverride != null) {
      _controller = controllerOverride;
      return;
    }
    _session.addListener(_handleSessionChanged);
    unawaited(_loadSession());
  }

  Future<void> _loadSession() async {
    await _session.loadSavedSession();
    if (mounted) _synchronizeController();
  }

  void _handleSessionChanged() => _synchronizeController();

  void _synchronizeController() {
    if (!mounted) return;

    final userId = _session.currentUserId;
    final isAuthenticatedDriver =
        userId != null &&
        _session.currentUserTypeId == 2 &&
        _session.hasValidAccessToken;

    if (isAuthenticatedDriver && _driverUserId == userId) return;

    _disposeController();
    if (isAuthenticatedDriver) {
      final httpService = HttpService();
      _httpService = httpService;
      _driverUserId = userId;
      _controller = DriverOfferController(
        repository: DriverOperationsRepositoryImpl(
          DriverOperationsDatasource(httpService),
        ),
        userId: userId,
      );
    }
    setState(() {});
  }

  void _disposeController() {
    _controller?.dispose();
    _controller = null;
    _httpService?.dispose();
    _httpService = null;
    _driverUserId = null;
  }

  void _openFreshHome(bool accepted) {
    final userId = _session.currentUserId;
    if (userId == null || _session.currentUserTypeId != 2) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      appNavigatorKey.currentState?.pushAndRemoveUntil<void>(
        MaterialPageRoute<void>(
          builder: (_) => HomePage(
            profile: HomeProfileEnum.driver,
            userId: userId,
            userTypeId: 2,
          ),
        ),
        (_) => false,
      );
    });
  }

  @override
  void dispose() {
    if (widget.controllerOverride == null) {
      _session.removeListener(_handleSessionChanged);
      _disposeController();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controllerOverride ?? _controller;
    if (controller == null) return widget.child;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final blocking = controller.isBlocking;
        return PopScope(
          canPop: !blocking,
          child: Stack(
            fit: StackFit.expand,
            children: [
              widget.child,
              if (blocking)
                Positioned.fill(
                  child: switch (controller.state) {
                    DriverOfferState.checking => const _CheckingOfferPage(),
                    DriverOfferState.error => _OfferCheckErrorPage(
                      message: controller.error,
                      onRetry: () => controller.refresh(forceDetails: true),
                    ),
                    DriverOfferState.pending ||
                    DriverOfferState.acting => DriverOfferPage(
                      controller: controller,
                      onResolved: _openFreshHome,
                    ),
                    DriverOfferState.idle => const SizedBox.shrink(),
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CheckingOfferPage extends StatelessWidget {
  const _CheckingOfferPage();

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: FretColors.appBackground,
    child: SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: FretColors.brandGold),
            SizedBox(height: 18),
            Text(
              'Verificando novas solicitações...',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    ),
  );
}

class _OfferCheckErrorPage extends StatelessWidget {
  final String? message;
  final VoidCallback onRetry;

  const _OfferCheckErrorPage({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: FretColors.appBackground,
    child: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                size: 42,
                color: FretColors.brandGoldDark,
              ),
              const SizedBox(height: 16),
              const Text(
                'Não foi possível verificar suas ofertas',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                message ?? 'Confira sua conexão e tente novamente.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: FretColors.textSecondary),
              ),
              const SizedBox(height: 22),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: FretColors.brandGold,
                  foregroundColor: FretColors.brandBlack,
                ),
                onPressed: onRetry,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
