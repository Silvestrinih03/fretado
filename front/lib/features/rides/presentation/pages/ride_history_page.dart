import 'package:flutter/material.dart';

import '../../../../app/design_system/design_system.dart';
import '../../../../core/endpoints.dart';
import '../../../../core/enums/home_profile.dart';
import '../../../../core/services/http_service.dart';
import '../../../driver_operations/data/models/driver_operation_models.dart';

class RideHistoryPage extends StatefulWidget {
  final int userId;
  final HomeProfileEnum profile;
  final bool showBackButton;

  const RideHistoryPage({
    super.key,
    required this.userId,
    required this.profile,
    this.showBackButton = true,
  });

  @override
  State<RideHistoryPage> createState() => _RideHistoryPageState();
}

class _RideHistoryPageState extends State<RideHistoryPage> {
  late final HttpService _httpService;
  late Future<List<DriverRideModel>> _ridesFuture;
  int _selectedFilterIndex = 0;

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
      backgroundColor: FretColors.screenBackground,
      body: SafeArea(
        child: Column(
          children: [
            _HistoryHeader(
              onRefresh: _reload,
              showBackButton: widget.showBackButton,
            ),
            _HistoryFilters(
              selectedIndex: _selectedFilterIndex,
              onSelected: (index) {
                setState(() => _selectedFilterIndex = index);
              },
            ),
            Expanded(
              child: FutureBuilder<List<DriverRideModel>>(
                future: _ridesFuture,
                builder: (context, snapshot) {
                  final bool isLoading =
                      snapshot.connectionState != ConnectionState.done;
                  final List<DriverRideModel> rides =
                      (snapshot.data ?? <DriverRideModel>[]).where((ride) {
                        return switch (_selectedFilterIndex) {
                          1 => ride.statusId >= 1 && ride.statusId <= 4,
                          2 => ride.statusId == 5,
                          3 => ride.statusId == 6,
                          _ => true,
                        };
                      }).toList();

                  if (isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(FretSpacements.spacement06),
                      child: _HistoryStateCard(
                        icon: Icons.error_outline_rounded,
                        title: 'N?o foi poss?vel carregar',
                        subtitle: 'Verifique sua conex?o e tente novamente.',
                        actionLabel: 'Tentar novamente',
                        onTap: _reload,
                      ),
                    );
                  }

                  if (rides.isEmpty) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _HistoryStateCard(
                        icon: Icons.route_outlined,
                        title: 'Nenhum resultado',
                        subtitle: 'Não há corridas com o\nfiltro selecionado.',
                        actionLabel: 'Ver todas',
                        onTap: () => setState(() => _selectedFilterIndex = 0),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    itemCount: rides.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _HistoryRideCard(ride: rides[index]);
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
  final bool showBackButton;

  const _HistoryHeader({required this.onRefresh, required this.showBackButton});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: EdgeInsets.fromLTRB(showBackButton ? 6 : 20, 4, 20, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (showBackButton)
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: FretColors.screenDark,
                  size: 21,
                ),
              )
            else
              const SizedBox.shrink(),
            if (showBackButton) const SizedBox(width: 2),
            const Expanded(
              child: Text(
                'Corridas',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: FretColors.screenDark,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Atualizar',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: onRefresh,
              icon: const Icon(
                Icons.refresh_rounded,
                color: FretColors.screenGold,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryFilters extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _HistoryFilters({
    required this.selectedIndex,
    required this.onSelected,
  });

  static const List<String> _filters = [
    'Todas',
    'Em andamento',
    'Finalizadas',
    'Canceladas',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return _HistoryFilterChip(
            label: _filters[index],
            selected: selectedIndex == index,
            onTap: () => onSelected(index),
          );
        },
      ),
    );
  }
}

class _HistoryFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _HistoryFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? FretColors.screenGold : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          border: selected
              ? null
              : Border.all(color: const Color(0xFFEBEBEA), width: 1),
        ),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          style: TextStyle(
            color: selected ? FretColors.screenDark : const Color(0xFF8A8A8A),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.5,
            letterSpacing: 0,
          ),
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ),
    );
  }
}

class _HistoryRideCard extends StatelessWidget {
  final DriverRideModel ride;

  const _HistoryRideCard({required this.ride});

  @override
  Widget build(BuildContext context) {
    return _HistorySummaryCard(
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 44),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: FretColors.white,
              shape: BoxShape.circle,
              border: Border.all(color: FretColors.screenBorder),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 6,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: icon == Icons.route_outlined
                ? const Center(
                    child: CustomPaint(
                      size: Size(26, 26),
                      painter: _EmptyRoutePainter(),
                    ),
                  )
                : Icon(icon, size: 26, color: FretColors.screenGold),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: FretColors.screenDark,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: FretColors.screenMuted,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          if (actionLabel != null && onTap != null) ...[
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: FretColors.screenDark,
                foregroundColor: FretColors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 11,
                ),
                minimumSize: Size.zero,
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class _HistorySummaryCard extends StatelessWidget {
  final int rideId;
  final int statusId;
  final DateTime? createdAt;
  final String origin;
  final String destination;
  final double totalPrice;
  final double packageWeight;

  const _HistorySummaryCard({
    required this.rideId,
    required this.statusId,
    required this.createdAt,
    required this.origin,
    required this.destination,
    required this.totalPrice,
    required this.packageWeight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FretColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBEBEA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 6,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Corrida #$rideId',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FretColors.screenDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(createdAt),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF8A8A8A),
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _HistoryStatusPill(statusId: statusId),
            ],
          ),
          const SizedBox(height: 12),
          _HistoryRouteTimeline(origin: origin, destination: destination),
          const SizedBox(height: 12),
          Row(
            children: [
              _HistoryRideMetricChip(
                label: _formatMoney(totalPrice),
                emphasized: true,
              ),
              const SizedBox(width: 6),
              _HistoryRideMetricChip(
                label: '${_formatNumber(packageWeight)} kg',
              ),
              const Spacer(),
              TextButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: FretColors.screenBackground,
                  builder: (context) => SafeArea(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Corrida #$rideId',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _HistoryStatusPill(statusId: statusId),
                          const SizedBox(height: 16),
                          Text('Data: ${_formatDate(createdAt)}'),
                          const SizedBox(height: 12),
                          Text('Origem: $origin'),
                          const SizedBox(height: 12),
                          Text('Destino: $destination'),
                          const SizedBox(height: 12),
                          Text('Valor: ${_formatMoney(totalPrice)}'),
                          Text('Peso: ${_formatNumber(packageWeight)} kg'),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Fechar'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 34),
                  foregroundColor: FretColors.screenGold,
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Detalhes'),
                    SizedBox(width: 2),
                    Icon(Icons.chevron_right_rounded, size: 12),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryStatusPill extends StatelessWidget {
  final int statusId;

  const _HistoryStatusPill({required this.statusId});

  @override
  Widget build(BuildContext context) {
    final style = _HistoryRideStatusVisualStyle.fromStatusId(statusId);

    return Container(
      constraints: const BoxConstraints(minHeight: 24, maxWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: style.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: style.borderColor == null
            ? null
            : Border.all(color: style.borderColor!, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (style.icon != null) ...[
            Icon(style.icon, color: style.foregroundColor, size: 10),
            const SizedBox(width: 5),
          ] else ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: style.dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              style.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: style.foregroundColor,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                height: 1,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryRideStatusVisualStyle {
  final String label;
  final Color backgroundColor;
  final Color? borderColor;
  final Color foregroundColor;
  final Color dotColor;
  final IconData? icon;

  const _HistoryRideStatusVisualStyle({
    required this.label,
    required this.backgroundColor,
    required this.borderColor,
    required this.foregroundColor,
    required this.dotColor,
    this.icon,
  });

  static _HistoryRideStatusVisualStyle fromStatusId(int statusId) {
    return switch (statusId) {
      1 => const _HistoryRideStatusVisualStyle(
        label: 'Aguardando aceite',
        backgroundColor: Color(0x1AC9A227),
        borderColor: Color(0x47C9A227),
        foregroundColor: Color(0xFF9A7810),
        dotColor: FretColors.screenGold,
      ),
      2 => const _HistoryRideStatusVisualStyle(
        label: 'Aguardando início',
        backgroundColor: Color(0x121A1A1A),
        borderColor: Color(0x261A1A1A),
        foregroundColor: Color(0xFF3A3A3A),
        dotColor: FretColors.screenDark,
      ),
      3 => const _HistoryRideStatusVisualStyle(
        label: 'Em coleta',
        backgroundColor: FretColors.screenGold,
        borderColor: null,
        foregroundColor: FretColors.screenDark,
        dotColor: FretColors.white,
      ),
      4 => const _HistoryRideStatusVisualStyle(
        label: 'Em entrega',
        backgroundColor: FretColors.screenGold,
        borderColor: null,
        foregroundColor: FretColors.screenDark,
        dotColor: FretColors.white,
      ),
      5 => const _HistoryRideStatusVisualStyle(
        label: 'Finalizada',
        backgroundColor: FretColors.screenDark,
        borderColor: null,
        foregroundColor: FretColors.white,
        dotColor: FretColors.white,
        icon: Icons.check_rounded,
      ),
      6 => const _HistoryRideStatusVisualStyle(
        label: 'Cancelada',
        backgroundColor: Color(0x0D000000),
        borderColor: Color(0x1A000000),
        foregroundColor: Color(0xFF7A7A7A),
        dotColor: Color(0xFF7A7A7A),
        icon: Icons.close_rounded,
      ),
      _ => const _HistoryRideStatusVisualStyle(
        label: 'Status',
        backgroundColor: FretColors.neutral100,
        borderColor: FretColors.neutral300,
        foregroundColor: FretColors.neutral700,
        dotColor: FretColors.neutral700,
      ),
    };
  }
}

class _HistoryRouteTimeline extends StatelessWidget {
  final String origin;
  final String destination;

  const _HistoryRouteTimeline({
    required this.origin,
    required this.destination,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              children: [
                const _HistoryRouteDot(color: FretColors.screenGold),
                Expanded(
                  child: Container(
                    width: 1,
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    color: const Color(0x1F1A1A1A),
                  ),
                ),
                const _HistoryRouteDot(color: FretColors.screenDark),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HistoryRouteAddress(
                  value: origin,
                  color: FretColors.screenDark,
                ),
                const SizedBox(height: 10),
                _HistoryRouteAddress(
                  value: destination,
                  color: FretColors.screenMuted,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryRouteDot extends StatelessWidget {
  final Color color;

  const _HistoryRouteDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _HistoryRouteAddress extends StatelessWidget {
  final String value;
  final Color color;

  const _HistoryRouteAddress({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: TextStyle(
        color: color,
        fontSize: 12,
        height: 1.4,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      ),
    );
  }
}

class _HistoryRideMetricChip extends StatelessWidget {
  final String label;
  final bool emphasized;

  const _HistoryRideMetricChip({required this.label, this.emphasized = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F6F3),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFEBEBEA), width: 1),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: emphasized ? FretColors.screenDark : const Color(0xFF8A8A8A),
          fontSize: 11,
          fontWeight: emphasized ? FontWeight.w600 : FontWeight.w400,
          height: 1,
          letterSpacing: 0,
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

String _formatDate(DateTime? value) {
  if (value == null) return '';

  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final year = local.year.toString();

  return '$day/$month/$year';
}

class _EmptyRoutePainter extends CustomPainter {
  const _EmptyRoutePainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    final paint = Paint()..color = FretColors.screenGold;
    canvas.drawCircle(const Offset(5, 18), 2.5, paint);
    canvas.drawCircle(const Offset(19, 6), 2.5, paint);
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(5, 15.5)
        ..lineTo(5, 9)
        ..quadraticBezierTo(5, 5, 9, 5)
        ..lineTo(15.5, 5)
        ..moveTo(19, 8.5)
        ..lineTo(19, 15.5)
        ..quadraticBezierTo(19, 19.5, 15, 19.5)
        ..lineTo(8.5, 19.5),
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _EmptyRoutePainter oldDelegate) => false;
}
