import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/design_system/design_system.dart';
import '../../../../core/endpoints.dart';
import '../../../../core/enums/home_profile.dart';
import '../../../../core/services/http_service.dart';
import '../../../driver_operations/data/models/driver_operation_models.dart';
import '../../../payments/presentation/pages/my_payment_methods_page.dart';
import '../../../ride_cancellation/data/datasources/ride_cancellation_datasource.dart';
import '../../../ride_cancellation/data/repositories/ride_cancellation_repository_impl.dart';
import '../../../ride_cancellation/presentation/widgets/client_cancellation_sheet.dart';
import '../../../rides/presentation/pages/ride_history_page.dart';
import '../../../rides/presentation/pages/ride_tracking_page.dart';
import '../../../rides/presentation/widgets/active_ride_details_sheet.dart';
import '../../../shipping_request/presentation/pages/address_map_page.dart';

class ClientHomeContent extends StatelessWidget {
  final String userName;
  final int userId;
  final int refreshVersion;
  final VoidCallback? onHomeRefreshRequested;
  final VoidCallback? onHistoryTap;
  final VoidCallback? onPaymentMethodsTap;

  const ClientHomeContent({
    super.key,
    required this.userName,
    required this.userId,
    this.refreshVersion = 0,
    this.onHomeRefreshRequested,
    this.onHistoryTap,
    this.onPaymentMethodsTap,
  });

  @override
  Widget build(BuildContext context) {
    final String greetingName = userName.trim().isEmpty ? 'Cliente' : userName;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      children: [
        RichText(
          text: TextSpan(
            text: 'Ol\u00e1, ',
            style: const TextStyle(
              fontSize: 28,
              height: 1.15,
              fontWeight: FontWeight.w900,
              color: FretColors.brandBlack,
              letterSpacing: 0,
            ),
            children: [
              TextSpan(
                text: '$greetingName!',
                style: const TextStyle(color: FretColors.brandGold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Para onde vamos hoje? Encontre fretes r\u00e1pidos e seguros.',
          style: TextStyle(
            fontSize: 13,
            height: 1.35,
            fontWeight: FontWeight.w500,
            color: FretColors.textSecondary,
          ),
        ),
        const SizedBox(height: 20),
        _FreightRequestCard(userId: userId, onReturn: onHomeRefreshRequested),
        const SizedBox(height: 14),
        FretShortcutTile(
          icon: Icons.history_rounded,
          title: 'Hist\u00f3rico de corridas',
          subtitle: 'Ver corridas anteriores e finalizadas',
          onTap:
              onHistoryTap ??
              () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const RideHistoryPage(),
                  ),
                );
              },
        ),
        const SizedBox(height: 10),
        FretShortcutTile(
          icon: Icons.credit_card_outlined,
          title: 'M\u00e9todos de pagamento',
          subtitle: 'Gerenciar cart\u00f5es para seus fretes',
          onTap:
              onPaymentMethodsTap ??
              () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => MyPaymentMethodsPage(userId: userId),
                  ),
                );
              },
        ),
        const SizedBox(height: 22),
        _ClientRideInProgressSection(
          userId: userId,
          refreshVersion: refreshVersion,
        ),
      ],
    );
  }
}

class _FreightRequestCard extends StatelessWidget {
  final int userId;
  final VoidCallback? onReturn;

  const _FreightRequestCard({required this.userId, this.onReturn});

  @override
  Widget build(BuildContext context) {
    return FretSurfaceCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      color: FretColors.brandBlack,
      radius: 14,
      border: Border.all(color: FretColors.brandGraphiteSoft),
      boxShadow: const [
        BoxShadow(
          color: Color(0x18181818),
          blurRadius: 18,
          offset: Offset(0, 8),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              FretIconBox(
                icon: Icons.inventory_2_outlined,
                backgroundColor: Color(0xFF29261A),
                iconColor: FretColors.brandGold,
                border: Border.fromBorderSide(
                  BorderSide(color: FretColors.brandGoldDark),
                ),
              ),
              Spacer(),
              Icon(
                Icons.chevron_right_rounded,
                color: FretColors.brandGraphiteSoft,
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Solicitar Frete',
            style: TextStyle(
              color: FretColors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Precisando de algu\u00e9m para transportar um produto? Nos fretamos para voc\u00ea.',
            style: TextStyle(
              color: Color(0xFF8E8E8E),
              fontSize: 12,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          FretPrimaryButton(
            label: 'SOLICITAR AGORA',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => AddressMapPage(userId: userId),
                ),
              );
              onReturn?.call();
            },
          ),
        ],
      ),
    );
  }
}

class _ClientRideInProgressSection extends StatefulWidget {
  final int userId;
  final int refreshVersion;

  const _ClientRideInProgressSection({
    required this.userId,
    required this.refreshVersion,
  });

  @override
  State<_ClientRideInProgressSection> createState() =>
      _ClientRideInProgressSectionState();
}

class _ClientRideInProgressSectionState
    extends State<_ClientRideInProgressSection> {
  late final HttpService _httpService;
  late final RideCancellationRepositoryImpl _cancellationRepository;
  List<DriverRideModel> _rides = <DriverRideModel>[];
  bool _initialLoading = true;
  bool _refreshing = false;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _httpService = HttpService();
    _cancellationRepository = RideCancellationRepositoryImpl(
      RideCancellationDatasource(_httpService),
    );
    unawaited(_loadRides(initial: true));
  }

  @override
  void didUpdateWidget(covariant _ClientRideInProgressSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      unawaited(_loadRides(initial: true));
    } else if (oldWidget.refreshVersion != widget.refreshVersion) {
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

  Future<void> _openCancellation(DriverRideModel ride) async {
    final result = await showClientCancellationFlow(
      context,
      ride: ride,
      repository: _cancellationRepository,
    );
    if (!mounted) return;
    if (result != null) await _loadRides();
  }

  Future<void> _openTracking(DriverRideModel ride) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RideTrackingPage(
          rideId: ride.id,
          userId: widget.userId,
          vehicleCategory: ride.vehicleCategoryLabel,
          profile: HomeProfileEnum.client,
        ),
      ),
    );
    if (mounted) await _loadRides();
  }

  void _openDetails(DriverRideModel ride) {
    showActiveRideDetailsSheet(
      context,
      ride: ride,
      profile: HomeProfileEnum.client,
      onTrack: () => _openTracking(ride),
      onCancel: ride.isCancellationReturn
          ? null
          : () => _openCancellation(ride),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ClientRideHistoryHeader(
          activeCount: _rides.length,
          refreshing: _refreshing,
          onRefresh: _refreshing ? null : () => _loadRides(),
        ),
        const SizedBox(height: 12),
        if (_loadError != null && _rides.isNotEmpty) ...[
          const Text(
            'Não foi possível atualizar agora. Os dados anteriores foram mantidos.',
            style: TextStyle(color: FretColors.destructive700, fontSize: 11),
          ),
          const SizedBox(height: 8),
        ],
        if (_initialLoading && _rides.isEmpty)
          const _RideHistoryStateCard(
            icon: Icons.hourglass_top_rounded,
            title: 'Carregando corridas',
            subtitle: 'Buscando suas corridas em andamento.',
          )
        else if (_loadError != null && _rides.isEmpty)
          _RideHistoryStateCard(
            icon: Icons.error_outline_rounded,
            title: 'Nao foi possivel carregar',
            subtitle: 'Verifique sua conexao e tente novamente.',
            actionLabel: 'Tentar novamente',
            onTap: () => _loadRides(),
          )
        else if (_rides.isEmpty)
          const _RideHistoryStateCard(
            icon: Icons.route_outlined,
            title: 'Nenhuma corrida em andamento',
            subtitle: 'Quando seu frete estiver ativo, ele aparecera aqui.',
          )
        else
          ..._rides.map(
            (ride) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ClientRideHistoryCard(
                ride: ride,
                onTrack: () => _openTracking(ride),
                onDetails: () => _openDetails(ride),
              ),
            ),
          ),
      ],
    );
  }
}

class _ClientRideHistoryHeader extends StatelessWidget {
  final int activeCount;
  final VoidCallback? onRefresh;
  final bool refreshing;

  const _ClientRideHistoryHeader({
    required this.activeCount,
    required this.refreshing,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Corridas em andamento',
                maxLines: 2,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: FretColors.textPrimary,
                ),
              ),
              if (activeCount > 0)
                Text(
                  '$activeCount ${activeCount == 1 ? 'corrida ativa' : 'corridas ativas'}',
                  style: const TextStyle(
                    color: FretColors.screenMuted,
                    fontSize: 10,
                  ),
                ),
            ],
          ),
        ),
        TextButton.icon(
          onPressed: onRefresh,
          icon: refreshing
              ? const SizedBox.square(
                  dimension: 13,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh_rounded, size: 14),
          label: const Text(
            'Atualizar',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
          ),
          style: TextButton.styleFrom(
            foregroundColor: FretColors.brandGoldDark,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }
}

class _ClientRideHistoryCard extends StatelessWidget {
  final DriverRideModel ride;
  final VoidCallback onTrack;
  final VoidCallback onDetails;

  const _ClientRideHistoryCard({
    required this.ride,
    required this.onTrack,
    required this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    final driver = ride.driver;
    final vehicle = ride.assignedVehicle;
    return FretRideSummaryCard(
      rideId: ride.id,
      statusId: ride.statusId,
      createdAt: ride.createdAt,
      origin: ride.originLabel,
      destination: ride.destinationLabel,
      totalPrice: ride.totalPrice,
      packageWeight: ride.packageWeight,
      participantName: driver?.fullName,
      participantInitials: driver?.initials,
      participantRidesCount: driver?.completedRidesCount,
      activeCancellationStatus: ride.activeCancellation?.status,
      cancellationNotice: fretCancellationNotice(
        ride.activeCancellation?.status,
        isDriver: false,
      ),
      participantSubtitle: vehicle == null
          ? null
          : '${vehicle.displayName} · ${vehicle.plate}',
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                  'Acompanhar corrida',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded, size: 16),
              ],
            ),
          ),
          TextButton(
            onPressed: onDetails,
            style: TextButton.styleFrom(
              foregroundColor: FretColors.screenGold,
              minimumSize: const Size.fromHeight(38),
            ),
            child: Text(
              ride.hasPendingCancellation
                  ? 'Ver detalhes e cancelamento'
                  : 'Ver todos os detalhes',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _RideHistoryStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onTap;

  const _RideHistoryStateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FretSurfaceCard(
      padding: const EdgeInsets.fromLTRB(18, 26, 18, 26),
      radius: 14,
      child: Column(
        children: [
          FretIconBox(
            icon: icon,
            size: 48,
            iconSize: 22,
            backgroundColor: FretColors.brandGoldSoft,
            iconColor: FretColors.brandGoldDark,
            radius: 24,
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: FretColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: FretColors.textSecondary,
              fontSize: 12,
              height: 1.3,
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
