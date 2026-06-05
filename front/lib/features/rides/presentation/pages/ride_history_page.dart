import 'package:flutter/material.dart';

import '../../../../app/design_system/design_system.dart';
import '../../../../core/endpoints.dart';
import '../../../../core/enums/home_profile.dart';
import '../../../../core/services/http_service.dart';
import '../../../driver_operations/data/models/driver_operation_models.dart';

class RideHistoryPage extends StatefulWidget {
  final int userId;
  final HomeProfileEnum profile;

  const RideHistoryPage({
    super.key,
    required this.userId,
    required this.profile,
  });

  @override
  State<RideHistoryPage> createState() => _RideHistoryPageState();
}

class _RideHistoryPageState extends State<RideHistoryPage> {
  late final HttpService _httpService;
  late Future<List<DriverRideModel>> _ridesFuture;

  bool get _isDriver => widget.profile == HomeProfileEnum.driver;

  @override
  void initState() {
    super.initState();
    _httpService = HttpService();
    _ridesFuture = _loadRides();
  }

  @override
  void didUpdateWidget(covariant RideHistoryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.profile != widget.profile) {
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
      _isDriver
          ? Endpoints.ridesByDriver(widget.userId)
          : Endpoints.ridesByClient(widget.userId),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F8),
      body: SafeArea(
        child: Column(
          children: [
            _HistoryHeader(onRefresh: _reload),
            Expanded(
              child: FutureBuilder<List<DriverRideModel>>(
                future: _ridesFuture,
                builder: (context, snapshot) {
                  final bool isLoading =
                      snapshot.connectionState != ConnectionState.done;
                  final List<DriverRideModel> rides =
                      snapshot.data ?? <DriverRideModel>[];

                  if (isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: _HistoryStateCard(
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
                      child: _HistoryStateCard(
                        icon: Icons.route_outlined,
                        title: 'Nenhuma corrida encontrada',
                        subtitle: 'Seu historico aparecera aqui.',
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                    itemCount: rides.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      return _HistoryRideCard(
                        ride: rides[index],
                        isDriver: _isDriver,
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

class _HistoryHeader extends StatelessWidget {
  final VoidCallback onRefresh;

  const _HistoryHeader({required this.onRefresh});

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
              'Historico de corridas',
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

class _HistoryRideCard extends StatelessWidget {
  final DriverRideModel ride;
  final bool isDriver;

  const _HistoryRideCard({
    required this.ride,
    required this.isDriver,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FretColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FretColors.neutral200),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F1A4A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: FretColors.primary100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.route_rounded,
                  color: FretColors.loginFooterLink,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Corrida #${ride.id}',
                  style: const TextStyle(
                    color: FretColors.loginFooterLink,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _StatusBadge(label: ride.statusLabel),
            ],
          ),
          const SizedBox(height: 12),
          _RouteText(label: 'Coleta', value: ride.originLabel),
          const SizedBox(height: 7),
          _RouteText(label: 'Entrega', value: ride.destinationLabel),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _InfoChip(
                icon: Icons.payments_outlined,
                label: _formatMoney(ride.totalPrice),
              ),
              _InfoChip(
                icon: Icons.inventory_2_outlined,
                label: '${_formatNumber(ride.packageWeight)} kg',
              ),
              _InfoChip(
                icon: isDriver
                    ? Icons.person_outline_rounded
                    : Icons.local_shipping_outlined,
                label: isDriver
                    ? 'Cliente #${ride.clientUserId}'
                    : ride.driverUserId == null
                        ? 'Sem motorista'
                        : 'Motorista #${ride.driverUserId}',
              ),
              if (ride.createdAt != null)
                _InfoChip(
                  icon: Icons.event_outlined,
                  label: _formatDateTime(ride.createdAt),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RouteText extends StatelessWidget {
  final String label;
  final String value;

  const _RouteText({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 58,
          child: Text(
            label,
            style: const TextStyle(
              color: FretColors.neutral500,
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
              height: 1.25,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F2F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: FretColors.neutral600),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: FretColors.neutral800,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;

  const _StatusBadge({required this.label});

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

class _HistoryStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onTap;

  const _HistoryStateCard({
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: FretColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FretColors.neutral200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 34, color: FretColors.loginFooterLink),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: FretColors.loginFooterLink,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
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
            ElevatedButton(
              onPressed: onTap,
              child: Text(actionLabel!),
            ),
          ],
        ],
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

String _formatDateTime(DateTime? value) {
  if (value == null) {
    return '';
  }

  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final year = local.year.toString();

  return '$day/$month/$year';
}
