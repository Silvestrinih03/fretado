import 'package:flutter/material.dart';

import '../../../../app/design_system/design_system.dart';
import '../../../../core/endpoints.dart';
import '../../../../core/enums/home_profile.dart';
import '../../../../core/services/http_service.dart';
import '../../../driver_operations/data/models/driver_operation_models.dart';
import '../../../payments/presentation/pages/my_payment_methods_page.dart';
import '../../../rides/presentation/pages/ride_history_page.dart';
import '../../../shipping_request/presentation/pages/address_map_page.dart';

class ClientHomeContent extends StatelessWidget {
  final String userName;
  final int userId;
  final VoidCallback? onHistoryTap;
  final VoidCallback? onPaymentMethodsTap;

  const ClientHomeContent({
    super.key,
    required this.userName,
    required this.userId,
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
        _FreightRequestCard(userId: userId),
        const SizedBox(height: 14),
        FretShortcutTile(
          icon: Icons.history_rounded,
          title: 'Hist\u00f3rico de corridas',
          subtitle: 'Ver corridas anteriores e finalizadas',
          onTap: onHistoryTap ?? () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => RideHistoryPage(
                  userId: userId,
                  profile: HomeProfileEnum.client,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        FretShortcutTile(
          icon: Icons.credit_card_outlined,
          title: 'M\u00e9todos de pagamento',
          subtitle: 'Gerenciar cart\u00f5es para seus fretes',
          onTap: onPaymentMethodsTap ?? () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => MyPaymentMethodsPage(userId: userId),
              ),
            );
          },
        ),
        const SizedBox(height: 22),
        _ClientRideInProgressSection(userId: userId),
      ],
    );
  }
}

class _FreightRequestCard extends StatelessWidget {
  final int userId;

  const _FreightRequestCard({required this.userId});

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
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => AddressMapPage(userId: userId),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ClientRideInProgressSection extends StatefulWidget {
  final int userId;

  const _ClientRideInProgressSection({required this.userId});

  @override
  State<_ClientRideInProgressSection> createState() =>
      _ClientRideInProgressSectionState();
}

class _ClientRideInProgressSectionState
    extends State<_ClientRideInProgressSection> {
  late final HttpService _httpService;
  late Future<List<DriverRideModel>> _ridesFuture;

  @override
  void initState() {
    super.initState();
    _httpService = HttpService();
    _ridesFuture = _loadRides();
  }

  @override
  void didUpdateWidget(covariant _ClientRideInProgressSection oldWidget) {
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
            _ClientRideHistoryHeader(onRefresh: isLoading ? null : _reload),
            const SizedBox(height: 12),
            if (isLoading)
              const _RideHistoryStateCard(
                icon: Icons.hourglass_top_rounded,
                title: 'Carregando corridas',
                subtitle: 'Buscando suas corridas em andamento.',
              )
            else if (snapshot.hasError)
              _RideHistoryStateCard(
                icon: Icons.error_outline_rounded,
                title: 'Nao foi possivel carregar',
                subtitle: 'Verifique sua conexao e tente novamente.',
                actionLabel: 'Tentar novamente',
                onTap: _reload,
              )
            else if (rides.isEmpty)
              const _RideHistoryStateCard(
                icon: Icons.route_outlined,
                title: 'Nenhuma corrida em andamento',
                subtitle: 'Quando seu frete estiver ativo, ele aparecera aqui.',
              )
            else
              ...rides.map(
                (ride) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ClientRideHistoryCard(ride: ride),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ClientRideHistoryHeader extends StatelessWidget {
  final VoidCallback? onRefresh;

  const _ClientRideHistoryHeader({this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Corridas em andamento',
            maxLines: 2,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: FretColors.textPrimary,
            ),
          ),
        ),
        TextButton.icon(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh_rounded, size: 14),
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

  const _ClientRideHistoryCard({required this.ride});

  @override
  Widget build(BuildContext context) {
    return FretRideSummaryCard(
      rideId: ride.id,
      statusId: ride.statusId,
      createdAt: ride.createdAt,
      origin: ride.originLabel,
      destination: ride.destinationLabel,
      totalPrice: ride.totalPrice,
      packageWeight: ride.packageWeight,
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
