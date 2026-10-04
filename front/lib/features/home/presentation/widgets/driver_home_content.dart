import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/design_system/design_system.dart';
import '../../../../core/endpoints.dart';
import '../../../../core/enums/home_profile.dart';
import '../../../../core/services/http_service.dart';
import '../../../driver_operations/data/models/driver_operation_models.dart';
import '../../../documents/presentation/pages/my_documents.dart';
import '../../../vehicles/presentation/pages/my_vehicles.dart';
import '../../../rides/presentation/pages/ride_tracking_page.dart';
import '../../../rides/presentation/widgets/active_ride_details_sheet.dart';
import '../../../ride_cancellation/presentation/widgets/driver_cancellation_gate.dart';
import '../controllers/driver_availability_controller.dart';

class DriverHomeContent extends StatefulWidget {
  final String firstName;
  final int userId;
  final DriverAvailabilityController availabilityController;
  final int refreshVersion;
  final int cancellationRefreshVersion;
  final VoidCallback onHistoryTap;
  final VoidCallback onWalletTap;

  const DriverHomeContent({
    super.key,
    required this.firstName,
    required this.userId,
    required this.availabilityController,
    this.refreshVersion = 0,
    this.cancellationRefreshVersion = 0,
    required this.onHistoryTap,
    required this.onWalletTap,
  });

  @override
  State<DriverHomeContent> createState() => _DriverHomeContentState();
}

class _DriverHomeContentState extends State<DriverHomeContent> {
  int _refreshVersion = 0;

  @override
  void didUpdateWidget(covariant DriverHomeContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshVersion != widget.refreshVersion) {
      _refreshVersion++;
    }
  }

  void _reloadHomeData() {
    if (!mounted) return;

    setState(() {
      _refreshVersion++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 24),
      children: [
        RichText(
          text: TextSpan(
            text: 'Olá, ',
            style: const TextStyle(
              fontSize: 28,
              height: 1.2,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.7,
              color: FretColors.screenDark,
            ),
            children: [
              TextSpan(
                text: '${widget.firstName}!',
                style: const TextStyle(color: FretColors.screenGold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Fique online e deixe o FreteJá encontrar corridas compatíveis para você.',
          style: TextStyle(
            fontSize: 13,
            height: 1.55,
            color: FretColors.screenMuted,
          ),
        ),
        const SizedBox(height: 16),
        _DriverRequiredSetupAlert(
          userId: widget.userId,
          refreshVersion: _refreshVersion,
        ),
        const SizedBox(height: 12),
        _DriverAvailabilitySummary(controller: widget.availabilityController),
        const SizedBox(height: 16),
        _BalanceCard(
          userId: widget.userId,
          refreshVersion: _refreshVersion,
          onTap: widget.onWalletTap,
        ),
        const SizedBox(height: 16),
        _DriverRideInProgressSection(
          userId: widget.userId,
          refreshVersion: _refreshVersion,
          cancellationRefreshVersion: widget.cancellationRefreshVersion,
          onRideFinished: _reloadHomeData,
        ),
        const SizedBox(height: 10),
        _DriverShortcutCard(
          icon: Icons.history_rounded,
          title: 'Histórico de corridas',
          subtitle: 'Ver corridas anteriores e finalizadas',
          onTap: widget.onHistoryTap,
        ),
        const SizedBox(height: 10),
        _DriverShortcutCard(
          icon: Icons.local_shipping_rounded,
          title: 'Meus veículos',
          subtitle: 'Gerencie seus veículos cadastrados',
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => MyVehiclesPage(userId: widget.userId),
              ),
            );

            _reloadHomeData();
          },
        ),
        const SizedBox(height: 10),
        _DriverShortcutCard(
          icon: Icons.description_outlined,
          title: 'Meus documentos',
          subtitle: 'CNH, CRLV e habilitações',
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => MyDocumentsPage(userId: widget.userId),
              ),
            );

            _reloadHomeData();
          },
        ),
      ],
    );
  }
}

class _DriverRequiredSetupAlert extends StatefulWidget {
  final int userId;
  final int refreshVersion;

  const _DriverRequiredSetupAlert({
    required this.userId,
    required this.refreshVersion,
  });

  @override
  State<_DriverRequiredSetupAlert> createState() =>
      _DriverRequiredSetupAlertState();
}

class _DriverRequiredSetupAlertState extends State<_DriverRequiredSetupAlert> {
  late final HttpService _httpService;
  late Future<_DriverRequiredSetupStatus> _statusFuture;

  @override
  void initState() {
    super.initState();
    _httpService = HttpService();
    _statusFuture = _loadStatus();
  }

  @override
  void didUpdateWidget(covariant _DriverRequiredSetupAlert oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.refreshVersion != widget.refreshVersion) {
      _reload();
    }
  }

  @override
  void dispose() {
    _httpService.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _statusFuture = _loadStatus();
    });
  }

  Future<_DriverRequiredSetupStatus> _loadStatus() async {
    try {
      final results = await Future.wait<bool>([
        _loadHasVehicle(),
        _loadHasDriverLicense(),
      ]);

      return _DriverRequiredSetupStatus(
        hasVehicle: results[0],
        hasDriverLicense: results[1],
        errorMessage: null,
      );
    } on HttpServiceException catch (e) {
      return _DriverRequiredSetupStatus.error(e.message);
    } catch (_) {
      return const _DriverRequiredSetupStatus.error(
        'Nao foi possivel verificar seus cadastros obrigatorios.',
      );
    }
  }

  Future<bool> _loadHasVehicle() async {
    final Map<String, dynamic> response;
    try {
      response = await _httpService.get(
        Endpoints.vehiclesByUser(widget.userId),
      );
    } on HttpServiceException catch (e) {
      if (e.statusCode == 404) return false;
      rethrow;
    }

    final dynamic data = response['data'];
    return data is List<dynamic> && data.isNotEmpty;
  }

  Future<bool> _loadHasDriverLicense() async {
    try {
      final response = await _httpService.get(
        Endpoints.driverDocumentByUserId(widget.userId),
      );

      final licenseNumber = _readString(response['license_number']);
      final licenseCategoryId = _readInt(response['license_category_id']) ?? 0;

      return licenseNumber.isNotEmpty && licenseCategoryId > 0;
    } on HttpServiceException catch (e) {
      if (e.statusCode == 404) return false;
      rethrow;
    }
  }

  Future<void> _openVehiclesPage() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MyVehiclesPage(userId: widget.userId),
      ),
    );

    if (mounted) _reload();
  }

  Future<void> _openDocumentsPage() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MyDocumentsPage(userId: widget.userId),
      ),
    );

    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DriverRequiredSetupStatus>(
      future: _statusFuture,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState != ConnectionState.done;
        final status = snapshot.data;

        if (isLoading) {
          return const _DriverSetupNoticeCard(
            icon: Icons.hourglass_top_rounded,
            title: 'Verificando cadastro',
            message: 'Conferindo veiculo e CNH.',
          );
        }

        if (status == null || status.errorMessage != null) {
          return _DriverSetupNoticeCard(
            icon: Icons.error_outline_rounded,
            title: 'Nao foi possivel verificar',
            message:
                status?.errorMessage ??
                'Tente novamente para validar seus dados obrigatorios.',
            actions: [
              TextButton.icon(
                onPressed: _reload,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Tentar novamente'),
              ),
            ],
          );
        }

        if (status.isComplete) {
          return const SizedBox.shrink();
        }

        return _DriverSetupNoticeCard(
          icon: Icons.warning_amber_rounded,
          title: 'Cadastro obrigatorio pendente',
          message: status.message,
          actions: [
            if (!status.hasVehicle)
              ElevatedButton.icon(
                onPressed: _openVehiclesPage,
                icon: const Icon(Icons.local_shipping_rounded, size: 18),
                label: const Text('Cadastrar veiculo'),
              ),
            if (!status.hasDriverLicense)
              OutlinedButton.icon(
                onPressed: _openDocumentsPage,
                icon: const Icon(Icons.badge_outlined, size: 18),
                label: const Text('Cadastrar CNH'),
              ),
            IconButton(
              tooltip: 'Atualizar',
              onPressed: _reload,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        );
      },
    );
  }

  String _readString(dynamic value) {
    if (value is String) return value.trim();
    return '';
  }

  int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}

class _DriverSetupNoticeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final List<Widget> actions;

  const _DriverSetupNoticeCard({
    required this.icon,
    required this.title,
    required this.message,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FretColors.attention050,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FretColors.attention300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: FretColors.attention100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: FretColors.attention800, size: 24),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: FretColors.neutral900,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: const TextStyle(
                        color: FretColors.neutral700,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: actions,
            ),
          ],
        ],
      ),
    );
  }
}

class _DriverRequiredSetupStatus {
  final bool hasVehicle;
  final bool hasDriverLicense;
  final String? errorMessage;

  const _DriverRequiredSetupStatus({
    required this.hasVehicle,
    required this.hasDriverLicense,
    required this.errorMessage,
  });

  const _DriverRequiredSetupStatus.error(String message)
    : hasVehicle = false,
      hasDriverLicense = false,
      errorMessage = message;

  bool get isComplete => hasVehicle && hasDriverLicense;

  String get message {
    if (!hasVehicle && !hasDriverLicense) {
      return 'Cadastre pelo menos um veiculo e sua CNH para ficar apto a receber corridas.';
    }

    if (!hasVehicle) {
      return 'Cadastre pelo menos um veiculo para ficar apto a receber corridas.';
    }

    return 'Cadastre sua CNH para ficar apto a receber corridas.';
  }
}

class _DriverAvailabilitySummary extends StatelessWidget {
  final DriverAvailabilityController controller;

  const _DriverAvailabilitySummary({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final String? statusMessage = controller.message;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DriverAvailabilityCard(controller: controller),
            const SizedBox(height: 12),
            _DriverSearchStatusCard(
              isOnline: controller.hasLoadedStatus && controller.isOnline,
              isLoading: controller.isLoading,
            ),
            if (statusMessage != null && statusMessage.isNotEmpty) ...[
              const SizedBox(height: 10),
              _DriverAvailabilityMessage(
                message: statusMessage,
                isError: !controller.isOnline,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _DriverAvailabilityCard extends StatelessWidget {
  final DriverAvailabilityController controller;

  const _DriverAvailabilityCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final bool isOnline = controller.hasLoadedStatus && controller.isOnline;
    final bool isLoading = controller.isLoading;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isOnline ? FretColors.screenDark : FretColors.white,
        borderRadius: BorderRadius.circular(18),
        border: isOnline ? null : Border.all(color: FretColors.screenBorder),
        boxShadow: isOnline
            ? null
            : const [
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLoading
                      ? 'Verificando disponibilidade'
                      : isOnline
                      ? 'Você está online'
                      : 'Você está offline',
                  style: TextStyle(
                    color: isOnline ? FretColors.white : FretColors.screenDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isLoading
                      ? 'Sincronizando seu status atual'
                      : isOnline
                      ? 'Disponível para receber novas ofertas'
                      : 'Fique online para entrar na busca de motoristas',
                  style: TextStyle(
                    color: isOnline
                        ? const Color(0x75FFFFFF)
                        : FretColors.screenMuted,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: isOnline,
            onChanged: isLoading
                ? null
                : (value) {
                    if (value) {
                      controller.goOnline();
                    } else {
                      controller.goOffline();
                    }
                  },
            activeColor: FretColors.white,
            activeTrackColor: FretColors.screenGold,
            inactiveThumbColor: FretColors.white,
            inactiveTrackColor: FretColors.neutral300,
          ),
        ],
      ),
    );
  }
}

class _DriverSearchStatusCard extends StatelessWidget {
  final bool isOnline;
  final bool isLoading;

  const _DriverSearchStatusCard({
    required this.isOnline,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FretColors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: FretColors.screenBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isOnline
                  ? FretColors.brandGold.withOpacity(0.12)
                  : FretColors.screenBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_rounded,
              size: 21,
              color: isOnline ? FretColors.screenGold : FretColors.screenMuted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLoading
                      ? 'Sincronizando disponibilidade'
                      : isOnline
                      ? 'Procurando oportunidades para você'
                      : 'Busca pausada',
                  style: const TextStyle(
                    color: FretColors.screenDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isLoading
                      ? 'Aguarde enquanto carregamos seu status.'
                      : isOnline
                      ? 'Quando surgir uma corrida compatível, você receberá uma oferta com tempo para responder.'
                      : 'Ative seu status para voltar a participar das buscas.',
                  style: const TextStyle(
                    color: FretColors.screenMuted,
                    fontSize: 11,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverAvailabilityMessage extends StatelessWidget {
  final String message;
  final bool isError;

  const _DriverAvailabilityMessage({
    required this.message,
    required this.isError,
  });

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = isError
        ? FretColors.attention050
        : FretColors.success050;
    final Color borderColor = isError
        ? FretColors.attention300
        : FretColors.success200;
    final Color foregroundColor = isError
        ? FretColors.attention800
        : FretColors.success800;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError
                ? Icons.warning_amber_rounded
                : Icons.check_circle_outline_rounded,
            color: foregroundColor,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: foregroundColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverRideInProgressSection extends StatefulWidget {
  final int userId;
  final int refreshVersion;
  final int cancellationRefreshVersion;
  final VoidCallback onRideFinished;

  const _DriverRideInProgressSection({
    required this.userId,
    required this.refreshVersion,
    required this.cancellationRefreshVersion,
    required this.onRideFinished,
  });

  @override
  State<_DriverRideInProgressSection> createState() =>
      _DriverRideInProgressSectionState();
}

class _DriverRideInProgressSectionState
    extends State<_DriverRideInProgressSection> {
  late final HttpService _httpService;
  List<DriverRideModel> _rides = <DriverRideModel>[];
  bool _initialLoading = true;
  bool _refreshing = false;
  Object? _loadError;
  int? _rideInActionId;

  @override
  void initState() {
    super.initState();
    _httpService = HttpService();
    unawaited(_loadRides(initial: true));
  }

  @override
  void didUpdateWidget(covariant _DriverRideInProgressSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.userId != widget.userId) {
      unawaited(_loadRides(initial: true));
    } else if (oldWidget.refreshVersion != widget.refreshVersion ||
        oldWidget.cancellationRefreshVersion !=
            widget.cancellationRefreshVersion) {
      unawaited(_loadRides());
    }
  }

  @override
  void dispose() {
    _httpService.dispose();
    super.dispose();
  }

  Future<void> _loadRides({bool initial = false}) async {
    if (!mounted) return;
    setState(() {
      if (initial) {
        _initialLoading = true;
      } else {
        _refreshing = true;
      }
      _loadError = null;
    });
    try {
      final response = await _httpService.get(
        Endpoints.ridesInProgressByUser(widget.userId),
      );
      final dynamic data = response['data'];
      final rides = data is List<dynamic>
          ? data
                .whereType<Map<String, dynamic>>()
                .map(DriverRideModel.fromJson)
                .toList()
          : <DriverRideModel>[];
      rides.sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      if (mounted) setState(() => _rides = rides);
    } catch (error) {
      if (mounted) setState(() => _loadError = error);
    } finally {
      if (mounted) {
        setState(() {
          _initialLoading = false;
          _refreshing = false;
        });
      }
    }
  }

  Future<void> _manualRefresh() async {
    await _loadRides();
    if (mounted) await DriverCancellationGate.checkNow(context);
  }

  Future<void> _advanceRide(DriverRideModel ride) async {
    final endpoint = _rideProgressActionEndpoint(ride);
    final message = _rideProgressSuccessMessage(ride);

    if (endpoint == null || message == null) return;

    final bool confirmed = await showFretRideProgressConfirmation(
      context,
      statusId: ride.statusId,
    );

    if (!confirmed || !mounted) return;

    setState(() => _rideInActionId = ride.id);

    try {
      await _httpService.patch(endpoint);

      if (!mounted) return;

      _showMessage(message, isError: false);

      await _loadRides();

      if (ride.statusId == 4) {
        widget.onRideFinished();
      }
    } on HttpServiceException catch (e) {
      _showMessage(e.message);
    } catch (_) {
      _showMessage('Nao foi possivel atualizar a corrida.');
    } finally {
      if (mounted) {
        setState(() => _rideInActionId = null);
      }
    }
  }

  void _showMessage(String message, {bool isError = true}) {
    if (!mounted) return;

    if (isError) {
      showFretErrorPopup(context, message: message);
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openTracking(DriverRideModel ride) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RideTrackingPage(
          rideId: ride.id,
          userId: widget.userId,
          vehicleCategory: ride.vehicleCategoryLabel,
          profile: HomeProfileEnum.driver,
        ),
      ),
    );
    if (mounted) await _loadRides();
  }

  void _openDetails(DriverRideModel ride) {
    showActiveRideDetailsSheet(
      context,
      ride: ride,
      profile: HomeProfileEnum.driver,
      onTrack: () => _openTracking(ride),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Corrida em andamento',
                    style: TextStyle(
                      color: FretColors.screenDark,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (_rides.isNotEmpty)
                    Text(
                      '${_rides.length} ${_rides.length == 1 ? 'corrida ativa' : 'corridas ativas'}',
                      style: const TextStyle(
                        color: FretColors.screenMuted,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: _refreshing ? null : _manualRefresh,
              style: TextButton.styleFrom(
                foregroundColor: FretColors.screenGold,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: _refreshing
                  ? const SizedBox.square(
                      dimension: 13,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded, size: 14),
              label: const Text('Atualizar', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_loadError != null && _rides.isNotEmpty) ...[
          const Text(
            'Não foi possível atualizar agora. Os dados anteriores foram mantidos.',
            style: TextStyle(color: FretColors.destructive700, fontSize: 11),
          ),
          const SizedBox(height: 8),
        ],
        if (_initialLoading && _rides.isEmpty)
          const _DriverRideStateCard(
            icon: Icons.hourglass_top_rounded,
            title: 'Carregando corridas',
            subtitle: 'Buscando suas corridas em andamento.',
          )
        else if (_loadError != null && _rides.isEmpty)
          _DriverRideStateCard(
            icon: Icons.error_outline_rounded,
            title: 'Nao foi possivel carregar',
            subtitle: 'Verifique sua conexao e tente novamente.',
            actionLabel: 'Tentar novamente',
            onTap: _manualRefresh,
          )
        else if (_rides.isEmpty)
          const _DriverRideStateCard(
            icon: Icons.route_outlined,
            title: 'Nenhuma corrida em andamento',
            subtitle: 'Corridas aceitas e ativas aparecem aqui.',
          )
        else
          ..._rides.map(
            (ride) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _DriverActiveRideCard(
                ride: ride,
                isBusy: _rideInActionId == ride.id,
                onAdvance: () => _advanceRide(ride),
                onTrack: () => _openTracking(ride),
                onDetails: () => _openDetails(ride),
              ),
            ),
          ),
      ],
    );
  }
}

class _DriverActiveRideCard extends StatelessWidget {
  final DriverRideModel ride;
  final bool isBusy;
  final VoidCallback onAdvance;
  final VoidCallback onTrack;
  final VoidCallback onDetails;

  const _DriverActiveRideCard({
    required this.ride,
    required this.isBusy,
    required this.onAdvance,
    required this.onTrack,
    required this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    final actionLabel = _rideProgressActionLabel(ride);
    final actionIcon = _rideProgressActionIcon(ride);
    final client = ride.client;

    return FretRideSummaryCard(
      rideId: ride.id,
      statusId: ride.statusId,
      createdAt: ride.createdAt,
      origin: ride.originLabel,
      destination: ride.destinationLabel,
      totalPrice: ride.driverNetValue,
      packageWeight: ride.packageWeight,
      valueLabel: 'VOCÊ RECEBE',
      participantName: client?.fullName,
      participantInitials: client?.initials,
      participantRidesCount: client?.completedRidesCount,
      activeCancellationStatus: ride.activeCancellation?.status,
      cancellationNotice: fretCancellationNotice(
        ride.activeCancellation?.status,
        isDriver: true,
      ),
      participantSubtitle: client == null
          ? null
          : 'Cliente · ${client.completedRidesCount} corridas',
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (ride.isCancellationReturn) ...[
            const Text(
              'DEVOLUÇÃO DE CANCELAMENTO',
              style: TextStyle(
                color: FretColors.brandGoldDark,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (actionLabel != null && actionIcon != null) ...[
            ElevatedButton.icon(
              onPressed: isBusy ? null : onAdvance,
              icon: isBusy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(actionIcon, size: 18),
              label: Text(
                ride.isCancellationReturn ? 'Confirmar devolução' : actionLabel,
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
                backgroundColor: FretColors.screenGold,
                foregroundColor: FretColors.screenDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          FilledButton(
            onPressed: onTrack,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
              backgroundColor: FretColors.screenDark,
              foregroundColor: FretColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Acompanhar detalhes da corrida',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverRideStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onTap;

  const _DriverRideStateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FretColors.neutral050,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FretColors.neutral200),
      ),
      child: Column(
        children: [
          Icon(icon, color: FretColors.loginFooterLink, size: 30),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: FretColors.loginFooterLink,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: FretColors.neutral600,
              fontSize: 13,
              height: 1.25,
            ),
          ),
          if (actionLabel != null && onTap != null) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class _BalanceCard extends StatefulWidget {
  final int userId;
  final int refreshVersion;
  final VoidCallback onTap;

  const _BalanceCard({
    required this.userId,
    required this.refreshVersion,
    required this.onTap,
  });

  @override
  State<_BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<_BalanceCard> {
  late final HttpService _httpService;
  late Future<DriverWalletModel?> _walletFuture;
  bool _isBalanceVisible = false;

  @override
  void initState() {
    super.initState();
    _httpService = HttpService();
    _walletFuture = _loadWallet();
  }

  @override
  void didUpdateWidget(covariant _BalanceCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.userId != widget.userId ||
        oldWidget.refreshVersion != widget.refreshVersion) {
      setState(() {
        _walletFuture = _loadWallet();
        _isBalanceVisible = false;
      });
    }
  }

  @override
  void dispose() {
    _httpService.dispose();
    super.dispose();
  }

  Future<DriverWalletModel?> _loadWallet() async {
    try {
      final response = await _httpService.get(
        Endpoints.driverWalletByDriver(widget.userId),
      );
      return DriverWalletModel.fromJson(response);
    } on HttpServiceException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DriverWalletModel?>(
      future: _walletFuture,
      builder: (context, snapshot) {
        final bool isLoading = snapshot.connectionState != ConnectionState.done;
        final DriverWalletModel? wallet = snapshot.data;
        final bool canToggle =
            !isLoading && !snapshot.hasError && wallet != null;
        final String balanceLabel = _balanceLabel(snapshot);

        return Container(
          decoration: BoxDecoration(
            color: FretColors.screenDark,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'CARTEIRA DO MOTORISTA',
                    style: TextStyle(
                      color: Color(0x61FFFFFF),
                      fontSize: 10,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: _isBalanceVisible
                        ? 'Ocultar saldo'
                        : 'Exibir saldo',
                    onPressed: canToggle
                        ? () {
                            setState(() {
                              _isBalanceVisible = !_isBalanceVisible;
                            });
                          }
                        : null,
                    icon: Icon(
                      _isBalanceVisible
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                    ),
                    color: const Color(0x75FFFFFF),
                    disabledColor: const Color(0x40FFFFFF),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                balanceLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: FretColors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Ink(
                    decoration: BoxDecoration(
                      color: FretColors.screenGold.withOpacity(0.13),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: FretColors.screenGold.withOpacity(0.24),
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Saldo, histórico e saque',
                            style: TextStyle(
                              color: FretColors.screenGold,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          Spacer(),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: FretColors.screenGold,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _balanceLabel(AsyncSnapshot<DriverWalletModel?> snapshot) {
    if (snapshot.connectionState != ConnectionState.done) {
      return 'R\$ ••••••';
    }

    final wallet = snapshot.data;
    if (snapshot.hasError || wallet == null) {
      return 'Saldo indisponível';
    }

    if (!_isBalanceVisible) {
      return 'R\$ ••••••';
    }

    return _formatMoney(wallet.availableBalance);
  }
}

class _DriverShortcutCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DriverShortcutCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: FretColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: FretColors.screenBorder),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: FretColors.screenDark,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: FretColors.screenGold, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: FretColors.screenDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: FretColors.screenMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.chevron_right_rounded,
                color: FretColors.screenGold,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatMoney(double value) {
  final fixed = value.toStringAsFixed(2).replaceAll('.', ',');
  return 'R\$ $fixed';
}

String? _rideProgressActionEndpoint(DriverRideModel ride) {
  return switch (ride.statusId) {
    2 => Endpoints.startRide(ride.id),
    3 => Endpoints.completeRidePickup(ride.id),
    4 => Endpoints.finishRide(ride.id),
    _ => null,
  };
}

String? _rideProgressActionLabel(DriverRideModel ride) {
  return switch (ride.statusId) {
    2 => 'Iniciar corrida',
    3 => 'Confirmar coleta',
    4 => 'Finalizar entrega',
    _ => null,
  };
}

String? _rideProgressSuccessMessage(DriverRideModel ride) {
  return switch (ride.statusId) {
    2 => 'Corrida iniciada.',
    3 => 'Coleta concluida.',
    4 => 'Corrida finalizada.',
    _ => null,
  };
}

IconData? _rideProgressActionIcon(DriverRideModel ride) {
  return switch (ride.statusId) {
    2 => Icons.play_arrow_rounded,
    3 => Icons.inventory_2_outlined,
    4 => Icons.flag_outlined,
    _ => null,
  };
}
