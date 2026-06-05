import 'package:flutter/material.dart';

import '../../../../app/design_system/design_system.dart';
import '../../../../core/endpoints.dart';
import '../../../../core/services/http_service.dart';
import '../../../driver_operations/data/models/driver_operation_models.dart';
import '../../../driver_operations/presentation/pages/driver_operations_page.dart';
import '../../../documents/presentation/pages/my_documents.dart';
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
          'Ola, $firstName!',
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
        _BalanceCard(
          onTap: () => _openOperations(context, initialTabIndex: 2),
        ),
        const SizedBox(height: 14),
        _DriverRideInProgressSection(userId: userId),
        const SizedBox(height: 10),
        _SimpleMetricCard(
          icon: Icons.inbox_outlined,
          title: 'Ofertas de corrida',
          subtitle: 'Aceitar ou recusar ofertas pendentes',
          onTap: () => _openOperations(context),
        ),
        const SizedBox(height: 10),
        _SimpleMetricCard(
          icon: Icons.route_outlined,
          title: 'Corridas em andamento',
          subtitle: 'Ver corridas ativas vinculadas ao motorista',
          onTap: () => _openOperations(context, initialTabIndex: 1),
        ),
        const SizedBox(height: 10),
        _SimpleMetricCard(
          icon: Icons.local_shipping_rounded,
          title: 'Meus veiculos',
          subtitle: 'Gerenciar meus veiculos',
          barColor: FretColors.loginFooterLink,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => MyVehiclesPage(userId: userId),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        _SimpleMetricCard(
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
                  child: _DriverActiveRideCard(ride: ride),
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

  const _DriverActiveRideCard({required this.ride});

  @override
  Widget build(BuildContext context) {
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
        ],
      ),
    );
  }
}

class _DriverRouteText extends StatelessWidget {
  final String label;
  final String value;

  const _DriverRouteText({
    required this.label,
    required this.value,
  });

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

  const _DriverRideInfo({
    required this.label,
    required this.value,
  });

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

class _BalanceCard extends StatelessWidget {
  final VoidCallback onTap;

  const _BalanceCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
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
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'CARTEIRA DO MOTORISTA',
                    style: TextStyle(
                      color: Color(0xFFD1D5FF),
                      letterSpacing: 0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Spacer(),
                  Icon(Icons.account_balance_wallet, color: Color(0xFFAFB6F3)),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'Ver saldo',
                style: TextStyle(
                  color: FretColors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 10),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0xFF313CA3),
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                      Icon(Icons.arrow_forward_rounded, color: FretColors.white),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SimpleMetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? urgencyTag;
  final Color? urgencyColor;
  final Color? urgencyTextColor;
  final Color? barColor;
  final VoidCallback? onTap;

  const _SimpleMetricCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.urgencyTag,
    this.urgencyColor,
    this.urgencyTextColor,
    this.barColor,
    this.onTap,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 10),
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
              const SizedBox(height: 8),
              if (urgencyTag != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: urgencyColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    urgencyTag!,
                    style: TextStyle(
                      color: urgencyTextColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              if (barColor != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    height: 6,
                    color: FretColors.neutral200,
                    child: FractionallySizedBox(
                      widthFactor: 0.38,
                      alignment: Alignment.centerLeft,
                      child: Container(color: barColor),
                    ),
                  ),
                ),
              ],
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
