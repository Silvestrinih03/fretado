import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/design_system/design_system.dart';
import '../../../../core/enums/home_profile.dart';
import '../../../../core/services/http_service.dart';
import '../../../driver_operations/data/datasources/driver_operations_datasource.dart';
import '../../../driver_operations/data/models/driver_operation_models.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../../ride_cancellation/data/datasources/ride_cancellation_datasource.dart';
import '../../../ride_cancellation/data/models/ride_cancellation_models.dart';
import '../../../ride_cancellation/data/repositories/ride_cancellation_repository_impl.dart';
import '../../../ride_cancellation/domain/repositories/ride_cancellation_repository.dart';
import '../../../ride_cancellation/presentation/widgets/client_cancellation_sheet.dart';

class RideTrackingPage extends StatefulWidget {
  final int rideId;
  final int userId;
  final String vehicleCategory;
  final bool startCancellationFlow;

  const RideTrackingPage({
    super.key,
    required this.rideId,
    required this.userId,
    required this.vehicleCategory,
    this.startCancellationFlow = false,
  });

  @override
  State<RideTrackingPage> createState() => _RideTrackingPageState();
}

class _RideTrackingPageState extends State<RideTrackingPage> {
  late final HttpService _httpService;
  late final DriverOperationsDatasource _datasource;
  late final RideCancellationRepository _cancellationRepository;
  Timer? _timer;
  DriverRideModel? _ride;
  String? _error;
  RideCancellationModel? _cancellation;
  bool _isCancellationAction = false;
  bool _didHandleInitialCancellation = false;

  @override
  void initState() {
    super.initState();
    _httpService = HttpService();
    _datasource = DriverOperationsDatasource(_httpService);
    _cancellationRepository = RideCancellationRepositoryImpl(
      RideCancellationDatasource(_httpService),
    );
    _load();
    _timer = Timer.periodic(const Duration(seconds: 6), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _httpService.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final ride = await _datasource.getRideById(widget.rideId);
      RideCancellationModel? cancellation;
      bool cancellationLoaded = true;
      try {
        cancellation = await _cancellationRepository.latest(widget.rideId);
      } catch (_) {
        cancellationLoaded = false;
        cancellation = _cancellation;
      }
      if (!mounted) return;
      setState(() {
        _ride = ride;
        _cancellation = cancellation;
        _error = null;
      });
      if (ride.statusId == 5 || ride.statusId == 6 || ride.statusId == 7) {
        _timer?.cancel();
      }
      if (widget.startCancellationFlow &&
          !_didHandleInitialCancellation &&
          cancellationLoaded) {
        _didHandleInitialCancellation = true;
        final hasPendingCancellation =
            cancellation?.isAwaitingDriver == true ||
            cancellation?.isAwaitingClient == true;
        if (!ride.isCancellationReturn &&
            ((ride.statusId >= 1 && ride.statusId <= 4) ||
                hasPendingCancellation)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _openCancellationFlow(initialCancellation: cancellation);
            }
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Nao foi possivel atualizar a corrida.');
      }
    }
  }

  void _goHome() {
    _timer?.cancel();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => HomePage(
          profile: HomeProfileEnum.client,
          userId: widget.userId,
          userTypeId: 1,
        ),
      ),
      (route) => false,
    );
  }

  Future<void> _openCancellationFlow({
    RideCancellationModel? initialCancellation,
  }) async {
    final ride = _ride;
    if (ride == null || _isCancellationAction) return;
    setState(() => _isCancellationAction = true);
    final result = await showClientCancellationFlow(
      context,
      ride: ride,
      repository: _cancellationRepository,
      initialCancellation: initialCancellation ?? _cancellation,
    );
    if (!mounted) return;
    setState(() => _isCancellationAction = false);
    if (result == ClientCancellationResult.completed) {
      _goHome();
      return;
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final ride = _ride;
    final state = _TrackingVisual.fromStatus(ride?.statusId);

    return Scaffold(
      backgroundColor: FretColors.appBackground,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 20, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _goHome,
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                  const Text(
                    'Acompanhar corrida',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: FretColors.brandGraphite,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            state.icon,
                            color: FretColors.brandGold,
                            size: 42,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            state.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: FretColors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            state.subtitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0x99FFFFFF),
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                          if (ride?.statusId == 1) ...[
                            const SizedBox(height: 18),
                            const LinearProgressIndicator(
                              color: FretColors.brandGold,
                              backgroundColor: Color(0x22FFFFFF),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (ride != null)
                      FretSurfaceCard(
                        padding: const EdgeInsets.all(18),
                        radius: 18,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Corrida #${ride.id}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: FretColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _RouteLine(
                              icon: Icons.radio_button_checked,
                              label: ride.originLabel,
                            ),
                            const SizedBox(height: 10),
                            _RouteLine(
                              icon: Icons.location_on_rounded,
                              label: ride.destinationLabel,
                            ),
                            const Divider(height: 28),
                            Row(
                              children: [
                                Expanded(
                                  child: _Metric(
                                    label: 'Valor',
                                    value:
                                        'R\$ ${ride.totalPrice.toStringAsFixed(2)}',
                                  ),
                                ),
                                Expanded(
                                  child: _Metric(
                                    label: 'Categoria',
                                    value: widget.vehicleCategory,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: FretColors.destructive700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    if (ride != null &&
                        !ride.isCancellationReturn &&
                        ride.statusId >= 1 &&
                        ride.statusId <= 4) ...[
                      OutlinedButton.icon(
                        onPressed: _isCancellationAction
                            ? null
                            : _openCancellationFlow,
                        icon: const Icon(Icons.cancel_outlined),
                        label: Text(
                          (_cancellation?.isAwaitingDriver ?? false) ||
                                  (_cancellation?.isAwaitingClient ?? false)
                              ? 'Ver cancelamento'
                              : 'Cancelar corrida',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: FretColors.destructive700,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    OutlinedButton(
                      onPressed: _goHome,
                      child: const Text('Voltar para o inicio'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteLine extends StatelessWidget {
  final IconData icon;
  final String label;
  const _RouteLine({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 18, color: FretColors.brandGoldDark),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),
    ],
  );
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 11, color: FretColors.textSecondary),
      ),
      const SizedBox(height: 4),
      Text(
        value,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
      ),
    ],
  );
}

class _TrackingVisual {
  final IconData icon;
  final String title;
  final String subtitle;
  const _TrackingVisual(this.icon, this.title, this.subtitle);

  factory _TrackingVisual.fromStatus(int? status) => switch (status) {
    1 => const _TrackingVisual(
      Icons.hourglass_top_rounded,
      'Aguardando motorista',
      'Encontramos um motorista compatível e enviamos a oferta. Aguardando a resposta.',
    ),
    2 => const _TrackingVisual(
      Icons.check_circle_outline_rounded,
      'Motorista encontrado',
      'Sua corrida foi aceita e aguarda o inicio.',
    ),
    3 => const _TrackingVisual(
      Icons.local_shipping_outlined,
      'Motorista a caminho',
      'O motorista esta indo ate o local de coleta.',
    ),
    4 => const _TrackingVisual(
      Icons.route_rounded,
      'Entrega em andamento',
      'Sua carga esta a caminho do destino.',
    ),
    5 => const _TrackingVisual(
      Icons.task_alt_rounded,
      'Corrida finalizada',
      'A entrega foi concluida com sucesso.',
    ),
    6 => const _TrackingVisual(
      Icons.cancel_outlined,
      'Corrida cancelada',
      'Esta corrida foi cancelada.',
    ),
    7 => const _TrackingVisual(
      Icons.search_off_rounded,
      'Corrida nao atendida',
      'Nao encontramos um motorista disponivel para esta corrida.',
    ),
    _ => const _TrackingVisual(
      Icons.hourglass_top_rounded,
      'Carregando corrida',
      'Consultando o status mais recente.',
    ),
  };
}
