import 'package:flutter/material.dart';

import '../../../../app/design_system/design_system.dart';
import '../../../../core/endpoints.dart';
import '../../../../core/services/http_service.dart';
import '../../../driver_operations/data/models/driver_operation_models.dart';
import '../../../shipping_request/presentation/pages/address_map_page.dart';

class ClientHomeContent extends StatelessWidget {
  final String userName;
  final int userId;

  const ClientHomeContent({
    super.key,
    required this.userName,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final String greetingName = userName.trim().isEmpty ? 'Cliente' : userName;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 18),
      children: [
        Text(
          'Ola, $greetingName!',
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: FretColors.loginFooterLink,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Para onde vamos hoje? Encontre fretes rapidos e seguros.',
          style: TextStyle(
            fontSize: 16,
            height: 1.35,
            fontWeight: FontWeight.w500,
            color: Color(0xFF656671),
          ),
        ),
        const SizedBox(height: 20),
        _FreightRequestCard(userId: userId),
        const SizedBox(height: 22),
        _ClientRideHistorySection(userId: userId),
      ],
    );
  }
}

class _FreightRequestCard extends StatelessWidget {
  final int userId;

  const _FreightRequestCard({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        color: const Color(0xFF080A73),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14080A73),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Solicitacao de frete',
            style: TextStyle(
              color: FretColors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Precisando de alguem para transportar um produto? Nos fretamos para voce.',
            style: TextStyle(
              color: Color(0xFFE2E5FF),
              fontSize: 15,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => AddressMapPage(userId: userId),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: const Color(0xFFFFE16D),
                foregroundColor: const Color(0xFF080A73),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'SOLICITAR AGORA',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientRideHistorySection extends StatefulWidget {
  final int userId;

  const _ClientRideHistorySection({required this.userId});

  @override
  State<_ClientRideHistorySection> createState() =>
      _ClientRideHistorySectionState();
}

class _ClientRideHistorySectionState extends State<_ClientRideHistorySection> {
  late final HttpService _httpService;
  late Future<List<DriverRideModel>> _ridesFuture;

  @override
  void initState() {
    super.initState();
    _httpService = HttpService();
    _ridesFuture = _loadRides();
  }

  @override
  void didUpdateWidget(covariant _ClientRideHistorySection oldWidget) {
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
      Endpoints.ridesByClient(widget.userId),
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
                title: 'Carregando historico',
                subtitle: 'Buscando suas corridas mais recentes.',
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
                title: 'Nenhuma corrida encontrada',
                subtitle: 'Quando voce solicitar um frete, ele aparecera aqui.',
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
            'Historico de corridas',
            maxLines: 2,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: FretColors.loginFooterLink,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Atualizar historico',
          onPressed: onRefresh,
          icon: const Icon(
            Icons.refresh_rounded,
            color: FretColors.secondaryVariation700,
            size: 22,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: FretColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatusPill(label: ride.statusLabel),
              const Spacer(),
              Text(
                '#FR-${ride.id}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF4C4B55),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _RouteLine(
            origin: _formatCoordinates(
              ride.originLatitude,
              ride.originLongitude,
            ),
            destination: _formatCoordinates(
              ride.destinationLatitude,
              ride.destinationLongitude,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE8E8EC)),
          const SizedBox(height: 10),
          _FreightInfo(
            icon: Icons.payments_outlined,
            label: 'VALOR',
            value: _formatMoney(ride.totalPrice),
          ),
          const SizedBox(height: 8),
          _FreightInfo(
            icon: Icons.inventory_2_outlined,
            label: 'CARGA',
            value: '${_formatMetric(ride.packageWeight)} kg',
          ),
          const SizedBox(height: 8),
          _FreightInfo(
            icon: Icons.person_outline_rounded,
            label: 'MOTORISTA',
            value: ride.driverUserId == null
                ? 'Aguardando aceite'
                : '#${ride.driverUserId}',
          ),
          if (ride.createdAt != null) ...[
            const SizedBox(height: 8),
            _FreightInfo(
              icon: Icons.event_outlined,
              label: 'DATA',
              value: _formatDate(ride.createdAt!),
            ),
          ],
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: FretColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E4EB)),
      ),
      child: Column(
        children: [
          Icon(icon, color: FretColors.loginFooterLink, size: 32),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: FretColors.neutral900,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF656671),
              fontSize: 13,
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

class _StatusPill extends StatelessWidget {
  final String label;

  const _StatusPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 32),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF4EDC8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFF3D3312),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _RouteLine extends StatelessWidget {
  final String origin;
  final String destination;

  const _RouteLine({
    required this.origin,
    required this.destination,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _RoutePoint(
          color: FretColors.secondaryVariation700,
          text: origin,
          showConnector: true,
        ),
        _RoutePoint(
          color: FretColors.loginFooterLink,
          text: destination,
        ),
      ],
    );
  }
}

class _RoutePoint extends StatelessWidget {
  final Color color;
  final String text;
  final bool showConnector;

  const _RoutePoint({
    required this.color,
    required this.text,
    this.showConnector = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 20,
          child: Column(
            children: [
              const SizedBox(height: 6),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              if (showConnector)
                Container(
                  width: 1,
                  height: 24,
                  color: const Color(0xFFE0E2EA),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: showConnector ? 22 : 0),
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: FretColors.neutral900,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FreightInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _FreightInfo({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF0F2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF5E606A), size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  letterSpacing: 0,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF5E606A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: FretColors.neutral900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _formatCoordinates(double latitude, double longitude) {
  return '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
}

String _formatDate(DateTime value) {
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final year = local.year.toString();
  return '$day/$month/$year';
}

String _formatMetric(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }

  return value.toStringAsFixed(1).replaceAll('.', ',');
}

String _formatMoney(double value) {
  final fixed = value.toStringAsFixed(2);
  final parts = fixed.split('.');
  final integer = parts.first;
  final decimals = parts.last;
  final buffer = StringBuffer();

  for (int i = 0; i < integer.length; i++) {
    final reverseIndex = integer.length - i;
    buffer.write(integer[i]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write('.');
    }
  }

  return 'R\$ ${buffer.toString()},$decimals';
}
