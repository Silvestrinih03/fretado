import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../app/design_system/design_system.dart';
import '../../../../core/endpoints.dart';
import '../../../../core/enums/home_profile.dart';
import '../../../../core/services/http_service.dart';
import '../../../driver_operations/data/models/driver_operation_models.dart';
import '../../../driver_operations/presentation/pages/driver_operations_page.dart';
import '../../../documents/presentation/pages/my_documents.dart';
import '../../../rides/presentation/pages/ride_history_page.dart';
import '../../../vehicles/presentation/pages/my_vehicles.dart';

class DriverHomeContent extends StatelessWidget {
  final String firstName;
  final int userId;

  const DriverHomeContent({
    super.key,
    required this.firstName,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      children: [
        Text(
          'Olá, $firstName!',
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: FretColors.loginFooterLink,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Gerencie suas viagens, veiculos e documentos aqui.',
          style: TextStyle(fontSize: 15, color: FretColors.neutral700),
        ),
        const SizedBox(height: 14),
        _DriverRequiredSetupAlert(userId: userId),
        const SizedBox(height: 10),
        _DriverAvailabilityCard(
          userId: userId,
          onFindRequests: () => _openAvailableRequests(context),
        ),
        const SizedBox(height: 14),
        _BalanceCard(
          userId: userId,
          onTap: () => _openOperations(context, initialTabIndex: 2),
        ),
        const SizedBox(height: 14),
        _DriverRideInProgressSection(userId: userId),
        const SizedBox(height: 10),
        _DriverShortcutCard(
          icon: Icons.history_rounded,
          title: 'Historico de corridas',
          subtitle: 'Ver corridas anteriores e finalizadas',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => RideHistoryPage(
                  userId: userId,
                  profile: HomeProfileEnum.driver,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        _DriverShortcutCard(
          icon: Icons.local_shipping_rounded,
          title: 'Meus veiculos',
          subtitle: 'Gerenciar meus veiculos',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => MyVehiclesPage(userId: userId),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        _DriverShortcutCard(
          icon: Icons.description_outlined,
          title: 'Meus documentos',
          subtitle: 'Acompanhar validade da CNH',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => MyDocumentsPage(userId: userId),
              ),
            );
          },
        ),
      ],
    );
  }

  void _openOperations(BuildContext context, {int initialTabIndex = 0}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DriverOperationsPage(
          userId: userId,
          initialTabIndex: initialTabIndex,
        ),
      ),
    );
  }

  void _openAvailableRequests(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _AvailableRideRequestsPage(userId: userId),
      ),
    );
  }
}

class _AvailableRideRequestsPage extends StatefulWidget {
  final int userId;

  const _AvailableRideRequestsPage({required this.userId});

  @override
  State<_AvailableRideRequestsPage> createState() =>
      _AvailableRideRequestsPageState();
}

class _AvailableRideRequestsPageState
    extends State<_AvailableRideRequestsPage> {
  late final HttpService _httpService;
  late Future<List<DriverRideModel>> _ridesFuture;
  int? _rideInActionId;

  @override
  void initState() {
    super.initState();
    _httpService = HttpService();
    _ridesFuture = _loadRides();
  }

  @override
  void dispose() {
    _httpService.dispose();
    super.dispose();
  }

  Future<List<DriverRideModel>> _loadRides() async {
    final response = await _httpService.get(Endpoints.availableRides);
    final dynamic data = response['data'];

    if (data is! List<dynamic>) {
      return <DriverRideModel>[];
    }

    final rides = data
        .whereType<Map<String, dynamic>>()
        .map(DriverRideModel.fromJson)
        .toList();

    rides.sort((a, b) {
      final DateTime aDate =
          a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final DateTime bDate =
          b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });

    return rides;
  }

  void _reload() {
    setState(() {
      _ridesFuture = _loadRides();
    });
  }

  Future<void> _acceptRide(DriverRideModel ride) async {
    setState(() => _rideInActionId = ride.id);

    try {
      final offer = await _httpService.post(
        Endpoints.rideOffers,
        body: {
          'ride_id': ride.id,
          'driver_user_id': widget.userId,
          'status_id': 1,
        },
      );

      final offerId = int.tryParse(offer['id']?.toString() ?? '');
      if (offerId == null) {
        throw const HttpServiceException(
          message: 'Oferta criada sem identificador.',
        );
      }

      await _httpService.put(Endpoints.acceptOffer(offerId));

      if (!mounted) {
        return;
      }

      _showMessage('Corrida aceita.', isError: false);
      setState(() {
        _ridesFuture = _loadRides();
      });
    } on HttpServiceException catch (e) {
      _showMessage(e.message);
    } catch (_) {
      _showMessage('Nao foi possivel aceitar a corrida.');
    } finally {
      if (mounted) {
        setState(() => _rideInActionId = null);
      }
    }
  }

  void _showMessage(String message, {bool isError = true}) {
    if (!mounted) {
      return;
    }

    if (isError) {
      showFretErrorPopup(context, message: message);
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F8),
      body: SafeArea(
        child: Column(
          children: [
            _AvailableRequestsHeader(onRefresh: _reload),
            Expanded(
              child: FutureBuilder<List<DriverRideModel>>(
                future: _ridesFuture,
                builder: (context, snapshot) {
                  final bool isLoading =
                      snapshot.connectionState != ConnectionState.done;
                  final rides = snapshot.data ?? <DriverRideModel>[];

                  if (isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: _DriverRideStateCard(
                        icon: Icons.error_outline_rounded,
                        title: 'Nao foi possivel carregar',
                        subtitle: 'Verifique sua conexao e tente novamente.',
                        actionLabel: 'Tentar novamente',
                        onTap: _reload,
                      ),
                    );
                  }

                  if (rides.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: _DriverRideStateCard(
                        icon: Icons.search_off_rounded,
                        title: 'Nenhuma solicitacao encontrada',
                        subtitle: 'Corridas sem motorista aparecerao aqui.',
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                    itemCount: rides.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final ride = rides[index];
                      return _DriverActiveRideCard(
                        ride: ride,
                        isBusy: _rideInActionId == ride.id,
                        customActionLabel: 'Aceitar corrida',
                        customActionIcon: Icons.check_rounded,
                        onAdvance: () => _acceptRide(ride),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvailableRequestsHeader extends StatelessWidget {
  final VoidCallback onRefresh;

  const _AvailableRequestsHeader({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
      color: const Color(0xFFF3F4F8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: FretColors.loginFooterLink,
              size: 20,
            ),
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Text(
              'Solicitacoes disponiveis',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: FretColors.loginFooterLink,
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Atualizar',
            onPressed: onRefresh,
            icon: const Icon(
              Icons.refresh_rounded,
              color: FretColors.loginFooterLink,
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverRequiredSetupAlert extends StatefulWidget {
  final int userId;

  const _DriverRequiredSetupAlert({required this.userId});

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
    if (oldWidget.userId != widget.userId) {
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
      );
    } on HttpServiceException catch (e) {
      return _DriverRequiredSetupStatus.error(e.message);
    } catch (_) {
      return _DriverRequiredSetupStatus.error(
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
      if (e.statusCode == 404) {
        return false;
      }

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
      if (e.statusCode == 404) {
        return false;
      }

      rethrow;
    }
  }

  Future<void> _openVehiclesPage() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MyVehiclesPage(userId: widget.userId),
      ),
    );

    if (mounted) {
      _reload();
    }
  }

  Future<void> _openDocumentsPage() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MyDocumentsPage(userId: widget.userId),
      ),
    );

    if (mounted) {
      _reload();
    }
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
    if (value is String) {
      return value.trim();
    }

    return '';
  }

  int? _readInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is String) {
      return int.tryParse(value);
    }

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
    this.errorMessage,
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

class _DriverAvailabilityCard extends StatefulWidget {
  final int userId;
  final VoidCallback onFindRequests;

  const _DriverAvailabilityCard({
    required this.userId,
    required this.onFindRequests,
  });

  @override
  State<_DriverAvailabilityCard> createState() =>
      _DriverAvailabilityCardState();
}

class _DriverAvailabilityCardState extends State<_DriverAvailabilityCard> {
  static const Duration _heartbeatInterval = Duration(minutes: 5);

  late final HttpService _httpService;
  Timer? _heartbeatTimer;
  bool _isLoading = true;
  bool _isOnline = false;
  String? _message;
  DateTime? _lastSeenAt;

  @override
  void initState() {
    super.initState();
    _httpService = HttpService();
    _loadInitialStatus();
  }

  @override
  void didUpdateWidget(covariant _DriverAvailabilityCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _stopHeartbeat();
      _loadInitialStatus();
    }
  }

  @override
  void dispose() {
    _stopHeartbeat();
    _httpService.dispose();
    super.dispose();
  }

  Future<void> _loadInitialStatus() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final response = await _httpService.get(
        Endpoints.driverLocationByDriver(widget.userId),
      );
      final online = response['is_online'] == true;

      if (!mounted) {
        return;
      }

      setState(() {
        _isOnline = online;
        _lastSeenAt = _readDateTime(response['last_seen_at']);
      });

      if (online) {
        await _sendCurrentLocation(silent: true, keepLoading: true);
      } else {
        _stopHeartbeat();
      }
    } on HttpServiceException catch (e) {
      if (e.statusCode == 404) {
        await _sendCurrentLocation(silent: true, keepLoading: true);
      } else if (mounted) {
        setState(() => _message = e.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'Nao foi possivel carregar seu status.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _goOnline() async {
    if (_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      await _sendCurrentLocation(silent: false, keepLoading: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _goOffline() async {
    if (_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final response = await _httpService.patch(
        Endpoints.driverLocationOffline(widget.userId),
      );

      if (!mounted) {
        return;
      }

      _stopHeartbeat();
      setState(() {
        _isOnline = false;
        _lastSeenAt = _readDateTime(response['last_seen_at']);
        _message = 'Voce esta offline e nao recebera novas ofertas.';
      });
    } on HttpServiceException catch (e) {
      if (mounted) {
        setState(() => _message = e.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'Nao foi possivel ficar offline.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendCurrentLocation({
    required bool silent,
    bool keepLoading = false,
  }) async {
    final position = await _getCurrentPosition(silent: silent);
    if (position == null) {
      _stopHeartbeat();
      if (mounted) {
        setState(() => _isOnline = false);
      }
      return;
    }

    try {
      final response = await _httpService.post(
        Endpoints.driverLocationByDriver(widget.userId),
        body: {'latitude': position.latitude, 'longitude': position.longitude},
      );
      await _runRideDispatchJob();

      if (!mounted) {
        return;
      }

      _startHeartbeat();
      setState(() {
        _isOnline = true;
        _lastSeenAt = _readDateTime(response['last_seen_at']);
        _message = silent ? _message : 'Voce esta online.';
        if (!keepLoading) {
          _isLoading = false;
        }
      });
    } on HttpServiceException catch (e) {
      _stopHeartbeat();
      if (mounted) {
        setState(() {
          _isOnline = false;
          _message = e.message;
        });
      }
    } catch (_) {
      _stopHeartbeat();
      if (mounted) {
        setState(() {
          _isOnline = false;
          _message = 'Nao foi possivel atualizar localizacao.';
        });
      }
    }
  }

  Future<void> _runRideDispatchJob() async {
    const jobSecret = String.fromEnvironment('JOB_SECRET');
    if (jobSecret.isEmpty) {
      return;
    }

    try {
      await _httpService.post(
        Endpoints.rideDispatchJob,
        headers: {'X-Job-Secret': jobSecret},
      );
    } catch (_) {
      // O agendador do backend ainda pode processar depois.
    }
  }

  Future<Position?> _getCurrentPosition({required bool silent}) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        setState(() {
          _message = 'Ative a localizacao do navegador ou aparelho.';
        });
      }
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() {
          _message = 'Permita acesso a localizacao para ficar online.';
        });
      }
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (_) {
      if (!silent && mounted) {
        setState(() => _message = 'Nao foi possivel obter sua localizacao.');
      }
      return null;
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      _heartbeatInterval,
      (_) => _sendCurrentLocation(silent: true),
    );
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  DateTime? _readDateTime(dynamic value) {
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final Color statusColor = _isOnline
        ? FretColors.success700
        : FretColors.destructive600;
    final String statusLabel = _isOnline ? 'Online' : 'Offline';
    final String lastSeenLabel = _lastSeenAt == null
        ? 'Localizacao ainda nao enviada'
        : 'Ultima atualizacao ${_formatDateTime(_lastSeenAt)}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FretColors.neutral050,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FretColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _isOnline
                      ? FretColors.success100
                      : FretColors.destructive100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _isOnline
                      ? Icons.location_on_rounded
                      : Icons.location_off_rounded,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Disponibilidade',
                      style: TextStyle(
                        color: FretColors.loginFooterLink,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      lastSeenLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FretColors.neutral600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: _isOnline
                      ? FretColors.success100
                      : FretColors.destructive100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          if (_message != null) ...[
            const SizedBox(height: 10),
            Text(
              _message!,
              style: const TextStyle(
                color: FretColors.neutral700,
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading
                      ? null
                      : (_isOnline ? _goOffline : _goOnline),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _isOnline
                              ? Icons.power_settings_new_rounded
                              : Icons.my_location_rounded,
                        ),
                  label: Text(_isOnline ? 'Ficar offline' : 'Ficar online'),
                ),
              ),
              if (_isOnline) ...[
                const SizedBox(width: 10),
                IconButton.filledTonal(
                  tooltip: 'Atualizar localizacao',
                  onPressed: _isLoading
                      ? null
                      : () => _sendCurrentLocation(silent: false),
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : widget.onFindRequests,
              icon: const Icon(Icons.search_rounded),
              label: const Text('Encontrar solicitacoes'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverRideInProgressSection extends StatefulWidget {
  final int userId;

  const _DriverRideInProgressSection({required this.userId});

  @override
  State<_DriverRideInProgressSection> createState() =>
      _DriverRideInProgressSectionState();
}

class _DriverRideInProgressSectionState
    extends State<_DriverRideInProgressSection> {
  late final HttpService _httpService;
  late Future<List<DriverRideModel>> _ridesFuture;
  int? _rideInActionId;

  @override
  void initState() {
    super.initState();
    _httpService = HttpService();
    _ridesFuture = _loadRides();
  }

  @override
  void didUpdateWidget(covariant _DriverRideInProgressSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _ridesFuture = _loadRides();
    }
  }

  @override
  void dispose() {
    _httpService.dispose();
    super.dispose();
  }

  Future<List<DriverRideModel>> _loadRides() async {
    final response = await _httpService.get(
      Endpoints.ridesInProgressByUser(widget.userId),
    );
    final dynamic data = response['data'];

    if (data is! List<dynamic>) {
      return <DriverRideModel>[];
    }

    final rides = data
        .whereType<Map<String, dynamic>>()
        .map(DriverRideModel.fromJson)
        .toList();

    rides.sort((a, b) {
      final DateTime aDate =
          a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final DateTime bDate =
          b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });

    return rides;
  }

  void _reload() {
    setState(() {
      _ridesFuture = _loadRides();
    });
  }

  Future<void> _advanceRide(DriverRideModel ride) async {
    final endpoint = _rideProgressActionEndpoint(ride);
    final message = _rideProgressSuccessMessage(ride);

    if (endpoint == null || message == null) {
      return;
    }

    setState(() => _rideInActionId = ride.id);

    try {
      await _httpService.patch(endpoint);
      if (!mounted) {
        return;
      }

      _showMessage(message, isError: false);
      setState(() {
        _ridesFuture = _loadRides();
      });
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
    if (!mounted) {
      return;
    }

    if (isError) {
      showFretErrorPopup(context, message: message);
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DriverRideModel>>(
      future: _ridesFuture,
      builder: (context, snapshot) {
        final bool isLoading = snapshot.connectionState != ConnectionState.done;
        final List<DriverRideModel> rides =
            snapshot.data ?? <DriverRideModel>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Corridas em andamento',
                    style: TextStyle(
                      color: FretColors.loginFooterLink,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Atualizar corridas',
                  onPressed: isLoading ? null : _reload,
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: FretColors.loginFooterLink,
                    size: 21,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (isLoading)
              const _DriverRideStateCard(
                icon: Icons.hourglass_top_rounded,
                title: 'Carregando corridas',
                subtitle: 'Buscando suas corridas em andamento.',
              )
            else if (snapshot.hasError)
              _DriverRideStateCard(
                icon: Icons.error_outline_rounded,
                title: 'Nao foi possivel carregar',
                subtitle: 'Verifique sua conexao e tente novamente.',
                actionLabel: 'Tentar novamente',
                onTap: _reload,
              )
            else if (rides.isEmpty)
              const _DriverRideStateCard(
                icon: Icons.route_outlined,
                title: 'Nenhuma corrida em andamento',
                subtitle: 'Corridas aceitas e ativas aparecem aqui.',
              )
            else
              ...rides.map(
                (ride) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _DriverActiveRideCard(
                    ride: ride,
                    isBusy: _rideInActionId == ride.id,
                    onAdvance: () => _advanceRide(ride),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _DriverActiveRideCard extends StatelessWidget {
  final DriverRideModel ride;
  final bool isBusy;
  final VoidCallback onAdvance;
  final String? customActionLabel;
  final IconData? customActionIcon;

  const _DriverActiveRideCard({
    required this.ride,
    required this.isBusy,
    required this.onAdvance,
    this.customActionLabel,
    this.customActionIcon,
  });

  @override
  Widget build(BuildContext context) {
    final actionLabel = customActionLabel ?? _rideProgressActionLabel(ride);
    final actionIcon = customActionIcon ?? _rideProgressActionIcon(ride);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FretColors.neutral050,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FretColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: FretColors.neutral100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.route_rounded,
                  color: FretColors.loginFooterLink,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Corrida #${ride.id}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: FretColors.loginFooterLink,
                  ),
                ),
              ),
              _DriverRideStatusBadge(label: ride.statusLabel),
            ],
          ),
          const SizedBox(height: 12),
          _DriverRouteText(label: 'Coleta', value: ride.originLabel),
          const SizedBox(height: 6),
          _DriverRouteText(label: 'Entrega', value: ride.destinationLabel),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DriverRideInfo(
                  label: 'Valor',
                  value: _formatMoney(ride.totalPrice),
                ),
              ),
              Expanded(
                child: _DriverRideInfo(
                  label: 'Peso',
                  value: '${_formatNumber(ride.packageWeight)} kg',
                ),
              ),
              Expanded(
                child: _DriverRideInfo(
                  label: 'Cliente',
                  value: '#${ride.clientUserId}',
                ),
              ),
            ],
          ),
          if (actionLabel != null && actionIcon != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isBusy ? null : onAdvance,
                icon: isBusy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(actionIcon),
                label: Text(actionLabel),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DriverRouteText extends StatelessWidget {
  final String label;
  final String value;

  const _DriverRouteText({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 55,
          child: Text(
            label,
            style: const TextStyle(
              color: FretColors.neutral600,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: FretColors.neutral900,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _DriverRideInfo extends StatelessWidget {
  final String label;
  final String value;

  const _DriverRideInfo({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: FretColors.neutral500,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: FretColors.neutral900,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _DriverRideStatusBadge extends StatelessWidget {
  final String label;

  const _DriverRideStatusBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: FretColors.primary100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: FretColors.neutral800,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
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
  final VoidCallback onTap;

  const _BalanceCard({required this.userId, required this.onTap});

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
    if (oldWidget.userId != widget.userId) {
      _walletFuture = _loadWallet();
      _isBalanceVisible = false;
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
      if (e.statusCode == 404) {
        return null;
      }

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
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              colors: [Color(0xFF1B2397), Color(0xFF151E8C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: FretColors.loginFooterLink.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'CARTEIRA DO MOTORISTA',
                    style: TextStyle(
                      color: Color(0xFFD1D5FF),
                      letterSpacing: 0,
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
                    color: const Color(0xFFAFB6F3),
                    disabledColor: const Color(0x667C84D6),
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
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap,
                  borderRadius: BorderRadius.circular(10),
                  child: Ink(
                    decoration: const BoxDecoration(
                      color: Color(0xFF313CA3),
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Saldo, historico e saque',
                            style: TextStyle(
                              color: FretColors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          Spacer(),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: FretColors.white,
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
      return 'Carregando saldo';
    }

    final wallet = snapshot.data;
    if (snapshot.hasError || wallet == null) {
      return 'Saldo indisponivel';
    }

    if (!_isBalanceVisible) {
      return 'R\$ *****';
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
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: FretColors.neutral050,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: FretColors.neutral200),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: FretColors.neutral100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: FretColors.loginFooterLink),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: FretColors.loginFooterLink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: FretColors.neutral700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.arrow_forward_rounded,
                color: FretColors.loginFooterLink,
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

String _formatNumber(double value) {
  return value.toStringAsFixed(1).replaceAll('.', ',');
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
    4 => 'Finalizar corrida',
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

String _formatDateTime(DateTime? value) {
  if (value == null) {
    return '';
  }

  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');

  return '$day/$month $hour:$minute';
}
