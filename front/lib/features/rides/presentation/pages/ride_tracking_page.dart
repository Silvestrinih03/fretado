import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/design_system/design_system.dart';
import '../../../../core/enums/home_profile.dart';
import '../../../../core/services/http_service.dart';
import '../../../driver_operations/data/datasources/driver_operations_datasource.dart';
import '../../../driver_operations/data/models/driver_operation_models.dart';
import '../../../driver_reassignment/presentation/widgets/driver_reassignment_flow.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../../ride_cancellation/data/datasources/ride_cancellation_datasource.dart';
import '../../../ride_cancellation/data/models/ride_cancellation_models.dart';
import '../../../ride_cancellation/data/repositories/ride_cancellation_repository_impl.dart';
import '../../../ride_cancellation/domain/repositories/ride_cancellation_repository.dart';
import '../../../ride_cancellation/presentation/widgets/client_cancellation_sheet.dart';
import '../../../ride_chat/presentation/widgets/ride_chat_access_button.dart';
import '../widgets/active_ride_details_sheet.dart';

class RideTrackingPage extends StatefulWidget {
  final int rideId;
  final int userId;
  final String vehicleCategory;
  final HomeProfileEnum profile;
  final bool startCancellationFlow;

  const RideTrackingPage({
    super.key,
    required this.rideId,
    required this.userId,
    required this.vehicleCategory,
    this.profile = HomeProfileEnum.client,
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
  RidePickupEstimateModel? _pickupEstimate;
  RideCancellationModel? _cancellation;
  DateTime? _lastEstimateLoad;
  String? _error;
  bool _isCancellationAction = false;
  bool _didHandleInitialCancellation = false;
  bool _acknowledgedDriverFound = false;

  bool get _isClient => widget.profile == HomeProfileEnum.client;

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
      RideCancellationModel? cancellation = _cancellation;
      bool cancellationLoaded = false;
      if (_isClient) {
        try {
          cancellation = await _cancellationRepository.latest(widget.rideId);
          cancellationLoaded = true;
        } catch (_) {
          cancellationLoaded = false;
        }
      }
      if (!mounted) return;
      setState(() {
        _ride = ride;
        _cancellation = cancellation;
        _error = null;
      });

      await _refreshPickupEstimateIfNeeded(ride);
      if (!mounted) return;

      if (ride.statusId >= 5) _timer?.cancel();
      if (_isClient &&
          widget.startCancellationFlow &&
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
        setState(() => _error = 'Não foi possível atualizar a corrida.');
      }
    }
  }

  Future<void> _refreshPickupEstimateIfNeeded(DriverRideModel ride) async {
    if (!_isClient || (ride.statusId != 2 && ride.statusId != 3)) return;
    final now = DateTime.now();
    if (_lastEstimateLoad != null &&
        now.difference(_lastEstimateLoad!) < const Duration(seconds: 45)) {
      return;
    }
    _lastEstimateLoad = now;
    try {
      final estimate = await _datasource.getPickupEstimate(ride.id);
      if (mounted) setState(() => _pickupEstimate = estimate);
    } catch (_) {
      if (mounted) setState(() => _pickupEstimate = null);
    }
  }

  void _exit() {
    _timer?.cancel();
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    navigator.pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => HomePage(
          profile: widget.profile,
          userId: widget.userId,
          userTypeId: _isClient ? 1 : 2,
        ),
      ),
      (_) => false,
    );
  }

  Future<void> _openCancellationFlow({
    RideCancellationModel? initialCancellation,
  }) async {
    final ride = _ride;
    if (!_isClient || ride == null || _isCancellationAction) return;
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
      _exit();
      return;
    }
    await _load();
  }

  void _openDetails() {
    final ride = _ride;
    if (ride == null) return;
    showActiveRideDetailsSheet(
      context,
      ride: ride,
      profile: widget.profile,
      onTrack: () {},
      onCancel:
          _isClient &&
              !ride.isCancellationReturn &&
              !ride.hasActiveDriverReassignment
          ? () => _openCancellationFlow()
          : null,
      onDriverReassignment:
          !_isClient &&
              !ride.isCancellationReturn &&
              (ride.statusId == 2 || ride.statusId == 3 || ride.statusId == 4)
          ? () => _openDriverReassignment(ride)
          : null,
    );
  }

  Future<void> _openDriverReassignment(DriverRideModel ride) async {
    if (ride.hasActiveDriverReassignment) {
      await showDriverReassignmentStatusSheet(
        context,
        reassignment: ride.activeDriverReassignment!,
        userId: widget.userId,
      );
    } else {
      await showDriverReassignmentRequestSheet(context, ride: ride);
    }
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final ride = _ride;
    final showDriverFound =
        _isClient && ride?.statusId == 2 && !_acknowledgedDriverFound;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exit();
      },
      child: Scaffold(
        backgroundColor: FretColors.screenBackground,
        body: SafeArea(
          child: showDriverFound
              ? _DriverFoundView(
                  ride: ride!,
                  estimate: _pickupEstimate,
                  onContinue: () =>
                      setState(() => _acknowledgedDriverFound = true),
                )
              : Column(
                  children: [
                    _TrackingHeader(onBack: _exit),
                    if (ride != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                        child: RideChatAccessButton(rideId: ride.id),
                      ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _load,
                        child: _buildBody(ride),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildBody(DriverRideModel? ride) {
    if (ride == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 220),
          Center(
            child: CircularProgressIndicator(color: FretColors.screenGold),
          ),
        ],
      );
    }

    final party = _isClient ? ride.driver : ride.client;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 24),
      children: [
        _TrackingHero(ride: ride, profile: widget.profile),
        const SizedBox(height: 11),
        _RideSteps(ride: ride, profile: widget.profile),
        if (party != null) ...[
          const SizedBox(height: 11),
          _TrackingPartyCard(
            title: _isClient ? 'MOTORISTA' : 'CLIENTE',
            party: party,
            subtitle: _isClient
                ? _vehicleLabel(ride.assignedVehicle)
                : 'Cliente verificado',
          ),
        ],
        const SizedBox(height: 11),
        FretRideSummaryCard(
          rideId: ride.id,
          eyebrow: ride.isCancellationReturn
              ? 'DEVOLUÇÃO EM ANDAMENTO'
              : 'CORRIDA EM ANDAMENTO',
          title: ride.isCancellationReturn
              ? 'Devolução da corrida #${ride.sourceRideId ?? ride.activeCancellation?.originalRideId ?? ride.id}'
              : null,
          statusId: ride.statusId,
          createdAt: ride.createdAt,
          origin: ride.originLabel,
          destination: ride.destinationLabel,
          totalPrice: _isClient ? ride.totalPrice : ride.driverNetValue,
          valueLabel: _isClient ? 'VALOR' : 'VOCÊ RECEBE',
          packageWeight: ride.packageWeight,
          activeCancellationStatus: ride.activeCancellation?.phase,
          cancellationNotice:
              fretCancellationNotice(
                ride.activeCancellation?.phase,
                isDriver: !_isClient,
              ) ??
              _trackingReassignmentNotice(
                ride.activeDriverReassignment,
                isDriver: !_isClient,
              ),
          footer: OutlinedButton(
            onPressed: _openDetails,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(42),
              foregroundColor: FretColors.screenGold,
              side: const BorderSide(color: FretColors.screenBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            child: const Text(
              'Ver todos os detalhes',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: FretColors.destructive700),
          ),
        ],
        if (_isClient &&
            !ride.isCancellationReturn &&
            ride.statusId >= 1 &&
            ride.statusId <= 4) ...[
          const SizedBox(height: 11),
          OutlinedButton(
            onPressed: _isCancellationAction
                ? null
                : () => _openCancellationFlow(),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              foregroundColor: FretColors.destructive700,
              side: const BorderSide(color: FretColors.destructive200),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            child: Text(
              ride.hasPendingCancellation
                  ? 'Ver cancelamento'
                  : 'Cancelar corrida',
            ),
          ),
        ],
      ],
    );
  }
}

class _TrackingHeader extends StatelessWidget {
  final VoidCallback onBack;
  const _TrackingHeader({required this.onBack});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(10, 6, 20, 8),
    child: Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        const Text(
          'Acompanhar corrida',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
      ],
    ),
  );
}

class _TrackingHero extends StatelessWidget {
  final DriverRideModel ride;
  final HomeProfileEnum profile;
  const _TrackingHero({required this.ride, required this.profile});
  @override
  Widget build(BuildContext context) {
    final isClient = profile == HomeProfileEnum.client;
    final waiting = ride.statusId == 1;
    final cancellationStatus = ride.activeCancellation?.phase;
    final cancellationNotice =
        fretCancellationNotice(cancellationStatus, isDriver: !isClient) ??
        _trackingReassignmentNotice(
          ride.activeDriverReassignment,
          isDriver: !isClient,
        );
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: FretColors.screenDark,
        borderRadius: BorderRadius.circular(21),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -55,
            top: -62,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0x2EC9A227)),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FretRideStatusPill(
                statusId: ride.statusId,
                cancellationStatus: cancellationStatus,
              ),
              if (cancellationNotice != null) ...[
                const SizedBox(height: 10),
                FretCancellationNotice(message: cancellationNotice),
              ],
              const SizedBox(height: 13),
              Text(
                waiting
                    ? 'Buscando um motorista para você'
                    : ride.isCancellationReturn
                    ? 'Devolução em andamento'
                    : isClient
                    ? 'Seu frete está em andamento'
                    : 'Entrega em andamento',
                style: const TextStyle(
                  color: FretColors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                waiting
                    ? 'A oferta foi enviada. Atualizaremos esta tela assim que um motorista aceitar.'
                    : isClient
                    ? 'Acompanhe os próximos passos e consulte todas as informações da corrida.'
                    : 'Acompanhe a rota, consulte o cliente e mantenha a corrida atualizada pela home.',
                style: const TextStyle(
                  color: Color(0x88FFFFFF),
                  fontSize: 11,
                  height: 1.5,
                ),
              ),
              if (waiting) ...[
                const SizedBox(height: 14),
                const LinearProgressIndicator(
                  color: FretColors.screenGold,
                  backgroundColor: Color(0x22FFFFFF),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _RideSteps extends StatelessWidget {
  final DriverRideModel ride;
  final HomeProfileEnum profile;
  const _RideSteps({required this.ride, required this.profile});

  @override
  Widget build(BuildContext context) {
    final isClient = profile == HomeProfileEnum.client;
    final steps = isClient
        ? [
            _StepData(
              'Motorista contratado',
              ride.driver == null
                  ? 'Aguardando aceite'
                  : '${ride.driver!.fullName} aceitou sua corrida',
              ride.statusId >= 2,
            ),
            _StepData(
              'A caminho da coleta',
              ride.statusId == 2
                  ? 'Aguardando o motorista iniciar'
                  : ride.statusId >= 3
                  ? 'Motorista em deslocamento'
                  : 'Próxima etapa',
              ride.statusId >= 3,
            ),
            _StepData(
              'A caminho da entrega',
              ride.statusId >= 4
                  ? 'Carga a caminho do destino'
                  : 'Próxima etapa',
              ride.statusId >= 4,
            ),
          ]
        : [
            _StepData('Corrida aceita', 'Você assumiu esta entrega', true),
            _StepData(
              'Carga coletada',
              ride.statusId >= 4
                  ? 'Carga sob sua responsabilidade'
                  : 'Confirme a coleta pela home',
              ride.statusId >= 4,
            ),
            _StepData(
              'Entrega ao destinatário',
              'Confirme somente após entregar a carga',
              ride.statusId >= 5,
            ),
          ];
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: FretColors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: FretColors.screenBorder),
      ),
      child: Column(
        children: List.generate(steps.length, (index) {
          final step = steps[index];
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == steps.length - 1 ? 0 : 13,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 25,
                  height: 25,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: step.done
                        ? FretColors.screenGold
                        : FretColors.screenBackground,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: step.done
                          ? FretColors.screenGold
                          : FretColors.screenBorder,
                    ),
                  ),
                  child: step.done
                      ? const Icon(Icons.check_rounded, size: 12)
                      : Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: FretColors.screenMuted,
                            shape: BoxShape.circle,
                          ),
                        ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.title,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        step.subtitle,
                        style: const TextStyle(
                          color: FretColors.screenMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _StepData {
  final String title;
  final String subtitle;
  final bool done;
  const _StepData(this.title, this.subtitle, this.done);
}

class _TrackingPartyCard extends StatelessWidget {
  final String title;
  final RidePartyModel party;
  final String? subtitle;
  const _TrackingPartyCard({
    required this.title,
    required this.party,
    required this.subtitle,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: FretColors.white,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: FretColors.screenBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _Avatar(initials: party.initials, size: 48),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    party.fullName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: FretColors.screenMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: FretColors.screenGold,
                        size: 12,
                      ),
                      const SizedBox(width: 3),
                      const Text(
                        fretTemporaryRatingLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        ' · ${party.completedRidesCount} corridas',
                        style: const TextStyle(
                          color: FretColors.screenMuted,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _DriverFoundView extends StatelessWidget {
  final DriverRideModel ride;
  final RidePickupEstimateModel? estimate;
  final VoidCallback onContinue;
  const _DriverFoundView({
    required this.ride,
    required this.estimate,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final driver = ride.driver;
    final vehicle = ride.assignedVehicle;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
      children: [
        Container(
          width: 76,
          height: 76,
          alignment: Alignment.center,
          margin: const EdgeInsets.symmetric(horizontal: 120),
          decoration: BoxDecoration(
            color: FretColors.screenDark,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0x59C9A227), width: 2),
          ),
          child: const Icon(
            Icons.check_rounded,
            color: FretColors.screenGold,
            size: 32,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'MOTORISTA ENCONTRADO',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: FretColors.screenGold,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'Sua corrida foi aceita!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 7),
        Text(
          driver == null
              ? 'O motorista está se preparando para iniciar o deslocamento até a coleta.'
              : '${driver.fullName} está se preparando para iniciar o deslocamento até a coleta.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: FretColors.screenMuted,
            fontSize: 12,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 22),
        if (driver != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: FretColors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: FretColors.screenBorder),
            ),
            child: Row(
              children: [
                _Avatar(initials: driver.initials, size: 54),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driver.fullName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (vehicle != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          '${vehicle.displayName} · ${vehicle.plate}',
                          style: const TextStyle(
                            color: FretColors.screenMuted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: FretColors.screenGold,
                            size: 12,
                          ),
                          const SizedBox(width: 3),
                          const Text(
                            fretTemporaryRatingLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            ' · ${driver.completedRidesCount} corridas',
                            style: const TextStyle(
                              color: FretColors.screenMuted,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x1AC9A227),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: const Color(0x33C9A227)),
                  ),
                  child: const Text(
                    'A caminho',
                    style: TextStyle(
                      color: Color(0xFF806515),
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _FoundMetric(
                dark: true,
                label: 'Previsão para coleta',
                value: estimate == null
                    ? 'Indisponível'
                    : '${estimate!.estimatedTimeMinutes} min',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _FoundMetric(
                label: 'Valor confirmado',
                value: _formatMoney(ride.totalPrice),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        RideChatAccessButton(rideId: ride.id),
        const SizedBox(height: 9),
        FilledButton(
          onPressed: onContinue,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            backgroundColor: FretColors.screenGold,
            foregroundColor: FretColors.screenDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text(
            'Acompanhar corrida',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}

class _FoundMetric extends StatelessWidget {
  final String label;
  final String value;
  final bool dark;
  const _FoundMetric({
    required this.label,
    required this.value,
    this.dark = false,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: dark ? FretColors.screenDark : FretColors.white,
      borderRadius: BorderRadius.circular(16),
      border: dark ? null : Border.all(color: FretColors.screenBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: dark ? const Color(0x66FFFFFF) : FretColors.screenMuted,
            fontSize: 9,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: dark ? FretColors.white : FretColors.screenDark,
            fontSize: value == 'Indisponível' ? 13 : 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _Avatar extends StatelessWidget {
  final String initials;
  final double size;
  const _Avatar({required this.initials, required this.size});
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: FretColors.screenDark,
      shape: BoxShape.circle,
      border: Border.all(color: const Color(0x885C4B15)),
    ),
    child: Text(
      initials,
      style: const TextStyle(
        color: FretColors.screenGold,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

String? _vehicleLabel(RideAssignedVehicleModel? vehicle) =>
    vehicle == null ? null : '${vehicle.displayName} · ${vehicle.plate}';

String _formatMoney(double value) =>
    'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';

String? _trackingReassignmentNotice(
  DriverReassignmentModel? reassignment, {
  required bool isDriver,
}) {
  if (reassignment == null) return null;
  final isPrePickup = reassignment.isPrePickupWithdrawal;
  return switch (reassignment.status) {
    'searching' || 'awaiting_replacement' =>
      isDriver
          ? isPrePickup
                ? 'Estamos procurando outro motorista. Esta corrida continua com você.'
                : 'Estamos procurando outro motorista. Você continua responsável pela carga.'
          : isPrePickup
          ? 'A corrida permanece com o motorista atual até uma nova oferta ser criada.'
          : 'Estamos buscando outro motorista para continuar a entrega.',
    'awaiting_handoff' =>
      isDriver
          ? 'O motorista substituto está a caminho do ponto de transferência.'
          : 'A transferência está em andamento; o motorista atual segue responsável até a confirmação.',
    'replacement_unavailable' =>
      isDriver
          ? isPrePickup
                ? 'Nenhum motorista disponível. Você continua responsável pela corrida.'
                : 'Nenhum motorista disponível. Você continua responsável pela entrega.'
          : isPrePickup
          ? 'Nenhum substituto disponível. A corrida permanece com o motorista atual.'
          : 'A busca por outro motorista continuará assim que houver disponibilidade.',
    _ => null,
  };
}
