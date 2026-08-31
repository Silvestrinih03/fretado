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
      backgroundColor: FretColors.appBackground,
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
                      snapshot.data ?? <DriverRideModel>[];

                  if (isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(FretSpacements.spacement06),
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
                      padding: EdgeInsets.all(FretSpacements.spacement06),
                      child: _HistoryStateCard(
                        icon: Icons.route_outlined,
                        title: 'Nenhuma corrida encontrada',
                        subtitle: 'Seu historico aparecera aqui.',
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    itemCount: rides.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 26),
                    itemBuilder: (context, index) {
                      return _HistoryRideCard(
                        ride: rides[index],
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
  final bool showBackButton;

  const _HistoryHeader({
    required this.onRefresh,
    required this.showBackButton,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          showBackButton ? 6 : 24,
          20,
          24,
          14,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (showBackButton)
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: FretColors.brandBlack,
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
                  color: FretColors.brandBlack,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Atualizar',
              onPressed: onRefresh,
              icon: const Icon(
                Icons.refresh_rounded,
                color: FretColors.brandGoldDark,
                size: 31,
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
      height: 70,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 14),
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
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
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 23),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? FretColors.brandGold : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          border: selected
              ? null
              : Border.all(
                  color: const Color(0xFFE9E9E9),
                  width: 1.4,
                ),
        ),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          style: TextStyle(
            color: selected ? FretColors.brandBlack : const Color(0xFF8E8E8E),
            fontSize: 18,
            fontWeight: FontWeight.w800,
            height: 1,
            letterSpacing: 0,
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

class _HistoryRideCard extends StatelessWidget {
  final DriverRideModel ride;

  const _HistoryRideCard({
    required this.ride,
  });

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
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEFEFEF)),
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
