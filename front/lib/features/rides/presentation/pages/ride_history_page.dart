import 'package:flutter/material.dart';

import '../../../../app/design_system/design_system.dart';
import '../../../../core/endpoints.dart';
import '../../../../core/services/http_service.dart';
import '../../../driver_operations/data/models/driver_operation_models.dart';
import '../../../ride_cancellation/presentation/widgets/cancellation_log_timeline.dart';
import '../../../ride_chat/presentation/widgets/ride_chat_access_button.dart';
import '../../../ride_rating/data/models/ride_rating_models.dart';
import '../../../ride_rating/data/ride_rating_repository.dart';
import '../../../ride_rating/presentation/widgets/ride_rating_access_button.dart';
import '../../data/models/ride_history_page_model.dart';

class RideHistoryPage extends StatefulWidget {
  final bool showBackButton;
  final int refreshVersion;

  const RideHistoryPage({
    super.key,
    this.showBackButton = true,
    this.refreshVersion = 0,
  });

  @override
  State<RideHistoryPage> createState() => _RideHistoryPageState();
}

class _RideHistoryPageState extends State<RideHistoryPage> {
  static const int _pageSize = 20;

  late final HttpService _httpService;
  late final ScrollController _scrollController;
  late final RideRatingRepository _ratingRepository;
  final List<DriverRideModel> _rides = <DriverRideModel>[];
  final Map<int, PendingRideRatingModel> _pendingRatings =
      <int, PendingRideRatingModel>{};
  final Set<int> _submittedRatingRideIds = <int>{};

  int _selectedFilterIndex = 0;
  int _requestVersion = 0;
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _nextCursor;
  String? _initialError;
  String? _loadMoreError;

  @override
  void initState() {
    super.initState();
    _httpService = HttpService();
    _ratingRepository = RideRatingRepository(_httpService);
    _scrollController = ScrollController()..addListener(_onScroll);
    _loadFirstPage();
  }

  @override
  void didUpdateWidget(covariant RideHistoryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshVersion != widget.refreshVersion) {
      _loadFirstPage();
    }
  }

  @override
  void dispose() {
    _requestVersion++;
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _httpService.dispose();
    super.dispose();
  }

  RideHistoryStatusGroup get _selectedStatusGroup =>
      RideHistoryStatusGroup.values[_selectedFilterIndex];

  Future<RideHistoryPageModel> _loadPage(String? cursor) async {
    final response = await _httpService.get(
      Endpoints.ridesMe(
        statusGroup: _selectedStatusGroup.apiValue,
        limit: _pageSize,
        cursor: cursor,
      ),
    );
    return RideHistoryPageModel.fromJson(response);
  }

  Future<void> _loadFirstPage() async {
    final int requestVersion = ++_requestVersion;
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
    setState(() {
      _rides.clear();
      _nextCursor = null;
      _hasMore = true;
      _isInitialLoading = true;
      _isLoadingMore = false;
      _initialError = null;
      _loadMoreError = null;
    });

    try {
      final page = await _loadPage(null);
      PendingRideRatingsPageModel? pendingPage;
      try {
        pendingPage = await _ratingRepository.pending();
      } catch (_) {
        pendingPage = null;
      }
      if (!mounted || requestVersion != _requestVersion) return;
      final loadedPendingPage = pendingPage;

      setState(() {
        _rides.addAll(page.items);
        if (loadedPendingPage != null) {
          _pendingRatings
            ..clear()
            ..addEntries(
              loadedPendingPage.items.map(
                (item) => MapEntry(item.rideId, item),
              ),
            );
        }
        _nextCursor = page.nextCursor;
        _hasMore = page.hasMore;
        _isInitialLoading = false;
      });
    } catch (_) {
      if (!mounted || requestVersion != _requestVersion) return;
      setState(() {
        _initialError = 'Não foi possível carregar';
        _isInitialLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isInitialLoading || _isLoadingMore || !_hasMore) return;

    final int requestVersion = _requestVersion;
    final String? cursor = _nextCursor;
    setState(() {
      _isLoadingMore = true;
      _loadMoreError = null;
    });

    try {
      final page = await _loadPage(cursor);
      if (!mounted || requestVersion != _requestVersion) return;

      setState(() {
        _rides.addAll(page.items);
        _nextCursor = page.nextCursor;
        _hasMore = page.hasMore;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (!mounted || requestVersion != _requestVersion) return;
      setState(() {
        _loadMoreError = 'Não foi possível carregar mais corridas.';
        _isLoadingMore = false;
      });
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter < 300) {
      _loadMore();
    }
  }

  void _selectFilter(int index) {
    if (_selectedFilterIndex == index) return;
    _selectedFilterIndex = index;
    _loadFirstPage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FretColors.screenBackground,
      body: SafeArea(
        child: Column(
          children: [
            _HistoryHeader(
              onRefresh: _loadFirstPage,
              showBackButton: widget.showBackButton,
            ),
            _HistoryFilters(
              selectedIndex: _selectedFilterIndex,
              onSelected: _selectFilter,
            ),
            Expanded(child: _buildHistoryContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryContent() {
    if (_isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_initialError != null) {
      return Padding(
        padding: const EdgeInsets.all(FretSpacements.spacement06),
        child: _HistoryStateCard(
          icon: Icons.error_outline_rounded,
          title: _initialError!,
          subtitle: 'Verifique sua conexão e tente novamente.',
          actionLabel: 'Tentar novamente',
          onTap: _loadFirstPage,
        ),
      );
    }

    if (_rides.isEmpty) {
      final bool isShowingAll = _selectedFilterIndex == 0;
      return RefreshIndicator(
        onRefresh: _loadFirstPage,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            _HistoryStateCard(
              icon: Icons.route_outlined,
              title: 'Nenhum resultado',
              subtitle: 'Não há corridas com o\nfiltro selecionado.',
              onTap: isShowingAll ? _loadFirstPage : () => _selectFilter(0),
            ),
          ],
        ),
      );
    }

    final bool showFooter = _isLoadingMore || _loadMoreError != null;
    return RefreshIndicator(
      onRefresh: _loadFirstPage,
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        itemCount: _rides.length + (showFooter ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index < _rides.length) {
            final ride = _rides[index];
            final ratingRideId = _ratingRideId(ride);
            return _HistoryRideCard(
              ride: ride,
              ratingRideId: ratingRideId,
              ratingPending:
                  ratingRideId != null && _pendingRatings.containsKey(ratingRideId),
              ratingSubmitted:
                  ratingRideId != null &&
                  _submittedRatingRideIds.contains(ratingRideId),
              onRatingChanged: ratingRideId == null
                  ? null
                  : () {
                      setState(() {
                        _pendingRatings.remove(ratingRideId);
                        _submittedRatingRideIds.add(ratingRideId);
                      });
                    },
            );
          }
          if (_isLoadingMore) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: TextButton.icon(
                onPressed: _loadMore,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(_loadMoreError!),
              ),
            ),
          );
        },
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
    'Pendentes',
    'Concluídas',
    'Interrompidas',
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

int? _ratingRideId(DriverRideModel ride) {
  final linkedReturn = ride.linkedReturnRide;
  if (linkedReturn != null && linkedReturn.statusId == 5) {
    return linkedReturn.id;
  }
  return ride.statusId == 5 ? ride.id : null;
}

class _HistoryRideCard extends StatelessWidget {
  final DriverRideModel ride;
  final int? ratingRideId;
  final bool ratingPending;
  final bool ratingSubmitted;
  final VoidCallback? onRatingChanged;

  const _HistoryRideCard({
    required this.ride,
    required this.ratingRideId,
    required this.ratingPending,
    required this.ratingSubmitted,
    required this.onRatingChanged,
  });

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
      cancellation: ride.cancellation,
      linkedReturnRide: ride.linkedReturnRide,
      ratingRideId: ratingRideId,
      ratingPending: ratingPending,
      ratingSubmitted: ratingSubmitted,
      onRatingChanged: onRatingChanged,
      assignmentLabel: ride.wasDriverWithdrawal
          ? 'Desistência do motorista'
          : null,
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
  final RideActiveCancellationModel? cancellation;
  final RideLinkedReturnModel? linkedReturnRide;
  final String? assignmentLabel;
  final int? ratingRideId;
  final bool ratingPending;
  final bool ratingSubmitted;
  final VoidCallback? onRatingChanged;

  const _HistorySummaryCard({
    required this.rideId,
    required this.statusId,
    required this.createdAt,
    required this.origin,
    required this.destination,
    required this.totalPrice,
    required this.packageWeight,
    required this.cancellation,
    required this.linkedReturnRide,
    required this.assignmentLabel,
    required this.ratingRideId,
    required this.ratingPending,
    required this.ratingSubmitted,
    required this.onRatingChanged,
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
              _HistoryStatusPill(
                statusId: statusId,
                label: linkedReturnRide == null
                    ? assignmentLabel
                    : linkedReturnRide!.statusId == 5
                    ? 'Cancelada · devolução concluída'
                    : 'Cancelada · devolução em andamento',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _HistoryRouteTimeline(origin: origin, destination: destination),
          if (linkedReturnRide != null) ...[
            const SizedBox(height: 12),
            _LinkedReturnSummary(
              originalRideId: rideId,
              linkedReturn: linkedReturnRide!,
              cancellation: cancellation,
            ),
          ],
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
                          _HistoryStatusPill(
                            statusId: statusId,
                            label: linkedReturnRide == null
                                ? assignmentLabel
                                : linkedReturnRide!.statusId == 5
                                ? 'Cancelada · devolução concluída'
                                : 'Cancelada · devolução em andamento',
                          ),
                          const SizedBox(height: 16),
                          Text('Data: ${_formatDate(createdAt)}'),
                          const SizedBox(height: 12),
                          Text('Origem: $origin'),
                          const SizedBox(height: 12),
                          Text('Destino: $destination'),
                          const SizedBox(height: 12),
                          Text('Valor: ${_formatMoney(totalPrice)}'),
                          Text('Peso: ${_formatNumber(packageWeight)} kg'),
                          if (linkedReturnRide != null) ...[
                            const SizedBox(height: 18),
                            _LinkedReturnDetails(
                              originalRideId: rideId,
                              linkedReturn: linkedReturnRide!,
                              cancellation: cancellation,
                            ),
                          ],
                          const SizedBox(height: 16),
                          RideChatAccessButton(
                            rideId: rideId,
                            labelOverride: linkedReturnRide == null
                                ? null
                                : 'Ver conversa da corrida original',
                          ),
                          if (linkedReturnRide != null) ...[
                            const SizedBox(height: 8),
                            RideChatAccessButton(
                              rideId: linkedReturnRide!.id,
                              labelOverride: 'Ver conversa da devolução',
                            ),
                          ],
                          if (ratingRideId != null) ...[
                            const SizedBox(height: 8),
                            RideRatingAccessButton(
                              rideId: ratingRideId!,
                              knownPending: ratingPending,
                              submitted: ratingSubmitted,
                              onChanged: onRatingChanged,
                            ),
                          ],
                          const SizedBox(height: 8),
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
          if (ratingRideId != null &&
              (ratingPending || ratingSubmitted)) ...[
            const SizedBox(height: 10),
            RideRatingAccessButton(
              rideId: ratingRideId!,
              knownPending: ratingPending,
              submitted: ratingSubmitted,
              onChanged: onRatingChanged,
            ),
          ],
        ],
      ),
    );
  }
}

class _HistoryStatusPill extends StatelessWidget {
  final int statusId;
  final String? label;

  const _HistoryStatusPill({required this.statusId, this.label});

  @override
  Widget build(BuildContext context) {
    final style = _HistoryRideStatusVisualStyle.fromStatusId(statusId);

    return Container(
      constraints: const BoxConstraints(minHeight: 24, maxWidth: 220),
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
              label ?? style.label,
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

class _LinkedReturnSummary extends StatelessWidget {
  final int originalRideId;
  final RideLinkedReturnModel linkedReturn;
  final RideActiveCancellationModel? cancellation;

  const _LinkedReturnSummary({
    required this.originalRideId,
    required this.linkedReturn,
    required this.cancellation,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: FretColors.attention050,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: FretColors.attention200),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Corrida #$originalRideId · devolução #${linkedReturn.id}',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Destino da devolução: ${linkedReturn.destination}',
          style: const TextStyle(fontSize: 10, height: 1.35),
        ),
        if (cancellation != null) ...[
          const SizedBox(height: 6),
          Text(
            'Percorrido: ${_formatDistance(cancellation!.traveledDistanceKm)} · '
            'devolução: ${_formatDistance(cancellation!.returnDistanceKm)}',
            style: const TextStyle(color: FretColors.screenMuted, fontSize: 9),
          ),
        ],
      ],
    ),
  );
}

class _LinkedReturnDetails extends StatelessWidget {
  final int originalRideId;
  final RideLinkedReturnModel linkedReturn;
  final RideActiveCancellationModel? cancellation;

  const _LinkedReturnDetails({
    required this.originalRideId,
    required this.linkedReturn,
    required this.cancellation,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: FretColors.attention050,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: FretColors.attention200),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'JORNADA DO CANCELAMENTO',
          style: TextStyle(
            color: FretColors.attention800,
            fontSize: 9,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 9),
        Text('Corrida original: #$originalRideId'),
        Text('Corrida de devolução: #${linkedReturn.id}'),
        const SizedBox(height: 8),
        Text(
          'Entrega original: ${_cancellationAddress(cancellation, original: true)}',
        ),
        Text('Destino da devolução: ${linkedReturn.destination}'),
        const SizedBox(height: 8),
        Text(
          'Distância até o cancelamento: '
          '${_formatDistance(cancellation?.traveledDistanceKm)}',
        ),
        Text(
          'Distância da devolução: '
          '${_formatDistance(cancellation?.returnDistanceKm)}',
        ),
        const SizedBox(height: 8),
        Text('Valor da devolução: ${_formatMoney(linkedReturn.totalPrice)}'),
        if (cancellation != null) ...[
          Text(
            'Valor retido: ${_formatMoney(cancellation!.cancellationCharge)}',
          ),
          Text('Reembolso: ${_formatMoney(cancellation!.refundAmount)}'),
          Text(
            'Cobrança adicional: '
            '${_formatMoney(cancellation!.additionalChargeAmount)}',
          ),
          const SizedBox(height: 12),
          const Text(
            'EVENTOS',
            style: TextStyle(
              color: FretColors.screenMuted,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          CancellationLogTimeline(rideId: originalRideId),
        ],
      ],
    ),
  );
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
      7 => const _HistoryRideStatusVisualStyle(
        label: 'Nao atendida',
        backgroundColor: Color(0x0D000000),
        borderColor: Color(0x1A000000),
        foregroundColor: Color(0xFF7A7A7A),
        dotColor: Color(0xFF7A7A7A),
        icon: Icons.search_off_rounded,
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

String _formatDistance(double? value) => value == null
    ? 'Indisponível'
    : '${value.toStringAsFixed(1).replaceAll('.', ',')} km';

String _cancellationAddress(
  RideActiveCancellationModel? cancellation, {
  required bool original,
}) {
  if (cancellation == null) return 'Não informada';
  final values = original
      ? [
          cancellation.originalDestinationAddress,
          cancellation.originalDestinationAddressComplement,
          cancellation.originalDestinationReferencePoint,
        ]
      : [
          cancellation.returnAddress,
          cancellation.returnAddressComplement,
          cancellation.returnReferencePoint,
        ];
  final result = values
      .whereType<String>()
      .where((value) => value.trim().isNotEmpty)
      .join(' · ');
  return result.isEmpty ? 'Não informada' : result;
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
