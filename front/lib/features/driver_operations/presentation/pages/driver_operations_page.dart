import 'package:flutter/material.dart';

import '../../../../app/design_system/design_system.dart';
import '../../../../core/services/http_service.dart';
import '../../../../core/services/myself/services/myself_service.dart';
import '../../data/datasources/driver_operations_datasource.dart';
import '../../data/models/driver_operation_models.dart';
import '../../data/repositories/driver_operations_repository_impl.dart';
import '../stores/driver_operations_store.dart';

class DriverOperationsPage extends StatefulWidget {
  final int? userId;
  final int initialTabIndex;

  const DriverOperationsPage({
    super.key,
    this.userId,
    this.initialTabIndex = 0,
  });

  @override
  State<DriverOperationsPage> createState() => _DriverOperationsPageState();
}

class _DriverOperationsPageState extends State<DriverOperationsPage> {
  late final HttpService _httpService;
  late final DriverOperationsStore _store;

  @override
  void initState() {
    super.initState();
    final myselfService = MyselfService();
    if (widget.userId != null) {
      myselfService.currentUserId = widget.userId;
    }

    _httpService = HttpService();
    _store = DriverOperationsStore(
      DriverOperationsRepositoryImpl(
        DriverOperationsDatasource(_httpService),
      ),
      myselfService,
      fallbackUserId: widget.userId,
    );
    _store.load();
  }

  @override
  void dispose() {
    _store.dispose();
    _httpService.dispose();
    super.dispose();
  }

  Future<void> _runOfferAction(
    Future<bool> Function() action,
  ) async {
    final ok = await action();
    if (!mounted || _store.actionMessage == null) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_store.actionMessage!),
        backgroundColor:
            ok ? FretColors.success700 : FretColors.destructive600,
      ),
    );
  }

  Future<void> _openWithdrawDialog() async {
    final valueController = TextEditingController();
    final pixController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        bool isSaving = false;

        return StatefulBuilder(
          builder: (dialogBuildContext, setDialogState) {
            return AlertDialog(
              title: const Text('Solicitar saque'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: valueController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Valor',
                      prefixIcon: Icon(Icons.payments_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: pixController,
                    decoration: const InputDecoration(
                      labelText: 'Chave Pix',
                      prefixIcon: Icon(Icons.key_outlined),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.of(dialogContext).maybePop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          setDialogState(() => isSaving = true);
                          final ok = await _store.requestWithdraw(
                            valueText: valueController.text,
                            pixKey: pixController.text,
                          );

                          if (!mounted || !dialogBuildContext.mounted) {
                            return;
                          }

                          setDialogState(() => isSaving = false);
                          if (ok) {
                            Navigator.of(dialogContext).maybePop();
                          }

                          if (_store.actionMessage != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(_store.actionMessage!),
                                backgroundColor: ok
                                    ? FretColors.success700
                                    : FretColors.destructive600,
                              ),
                            );
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Solicitar'),
                ),
              ],
            );
          },
        );
      },
    );

    valueController.dispose();
    pixController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: widget.initialTabIndex.clamp(0, 2).toInt(),
      child: AnimatedBuilder(
        animation: _store,
        builder: (context, _) {
          return Scaffold(
            backgroundColor: const Color(0xFFF3F4F8),
            body: SafeArea(
              child: Column(
                children: [
                  _DriverOperationsHeader(onRefresh: _store.load),
                  Container(
                    color: FretColors.white,
                    child: const TabBar(
                      labelColor: FretColors.loginFooterLink,
                      unselectedLabelColor: FretColors.neutral500,
                      indicatorColor: FretColors.loginFooterLink,
                      tabs: [
                        Tab(text: 'Ofertas'),
                        Tab(text: 'Corridas'),
                        Tab(text: 'Carteira'),
                      ],
                    ),
                  ),
                  Expanded(child: _buildContent()),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    if (_store.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_store.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _StateCard(
            icon: Icons.error_outline_rounded,
            title: 'Nao foi possivel carregar os dados',
            subtitle: _store.errorMessage!,
            actionLabel: 'Tentar novamente',
            onTap: _store.load,
          ),
        ),
      );
    }

    return TabBarView(
      children: [
        _OffersTab(
          store: _store,
          onAccept: (offerId) => _runOfferAction(
            () => _store.acceptOffer(offerId),
          ),
          onReject: (offerId) => _runOfferAction(
            () => _store.rejectOffer(offerId),
          ),
        ),
        _RidesTab(rides: _store.rides),
        _WalletTab(
          store: _store,
          onWithdrawTap: _openWithdrawDialog,
        ),
      ],
    );
  }
}

class _DriverOperationsHeader extends StatelessWidget {
  final VoidCallback onRefresh;

  const _DriverOperationsHeader({required this.onRefresh});

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
              'Operacao do motorista',
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

class _OffersTab extends StatelessWidget {
  final DriverOperationsStore store;
  final ValueChanged<int> onAccept;
  final ValueChanged<int> onReject;

  const _OffersTab({
    required this.store,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final offers = [...store.offers]
      ..sort((a, b) {
        if (a.isPending != b.isPending) {
          return a.isPending ? -1 : 1;
        }
        return b.id.compareTo(a.id);
      });

    if (offers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: _StateCard(
          icon: Icons.inbox_outlined,
          title: 'Nenhuma oferta encontrada',
          subtitle: 'Novas ofertas de corrida aparecem aqui.',
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      itemCount: offers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final offer = offers[index];
        return _OfferCard(
          offer: offer,
          ride: store.offerRides[offer.rideId],
          isBusy: store.offerInActionId == offer.id,
          onAccept: () => onAccept(offer.id),
          onReject: () => onReject(offer.id),
        );
      },
    );
  }
}

class _OfferCard extends StatelessWidget {
  final RideOfferModel offer;
  final DriverRideModel? ride;
  final bool isBusy;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _OfferCard({
    required this.offer,
    required this.ride,
    required this.isBusy,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _IconBox(icon: Icons.local_shipping_outlined),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Corrida #${offer.rideId}',
                  style: const TextStyle(
                    color: FretColors.loginFooterLink,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _StatusBadge(label: offer.statusLabel, color: _offerColor(offer)),
            ],
          ),
          const SizedBox(height: 12),
          _InfoGrid(
            items: [
              _InfoItem('Valor', _formatMoney(ride?.totalPrice ?? 0)),
              _InfoItem('Tentativa', '${offer.attemptOrder}'),
              _InfoItem('Peso', '${_formatNumber(ride?.packageWeight ?? 0)} kg'),
              _InfoItem('Expira', _formatDateTime(offer.expiresAt)),
            ],
          ),
          if (offer.isPending) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isBusy ? null : onReject,
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Recusar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isBusy ? null : onAccept,
                    icon: isBusy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_rounded),
                    label: const Text('Aceitar'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RidesTab extends StatelessWidget {
  final List<DriverRideModel> rides;

  const _RidesTab({required this.rides});

  @override
  Widget build(BuildContext context) {
    if (rides.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: _StateCard(
          icon: Icons.route_outlined,
          title: 'Nenhuma corrida vinculada',
          subtitle: 'Corridas aceitas e finalizadas aparecem aqui.',
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      itemCount: rides.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return _RideCard(ride: rides[index]);
      },
    );
  }
}

class _RideCard extends StatelessWidget {
  final DriverRideModel ride;

  const _RideCard({required this.ride});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _IconBox(icon: Icons.route_rounded),
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
              _StatusBadge(label: ride.statusLabel, color: _rideColor(ride)),
            ],
          ),
          const SizedBox(height: 12),
          _InfoGrid(
            items: [
              _InfoItem('Valor', _formatMoney(ride.totalPrice)),
              _InfoItem('Cliente', '#${ride.clientUserId}'),
              _InfoItem('Pacote', '${_formatNumber(ride.packageWeight)} kg'),
              _InfoItem('Criada em', _formatDateTime(ride.createdAt)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Origem ${_formatNumber(ride.originLatitude)}, ${_formatNumber(ride.originLongitude)}',
            style: const TextStyle(color: FretColors.neutral600, fontSize: 12),
          ),
          const SizedBox(height: 3),
          Text(
            'Destino ${_formatNumber(ride.destinationLatitude)}, ${_formatNumber(ride.destinationLongitude)}',
            style: const TextStyle(color: FretColors.neutral600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _WalletTab extends StatelessWidget {
  final DriverOperationsStore store;
  final VoidCallback onWithdrawTap;

  const _WalletTab({
    required this.store,
    required this.onWithdrawTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      children: [
        _WalletBalanceCard(
          wallet: store.wallet,
          totalNetEarnings: store.totalNetEarnings,
          onWithdrawTap: store.wallet == null ? null : onWithdrawTap,
        ),
        const SizedBox(height: 12),
        _SectionTitle(
          title: 'Ganhos recentes',
          actionLabel: '${store.earnings.length}',
        ),
        const SizedBox(height: 8),
        if (store.earnings.isEmpty)
          const _StateCard(
            icon: Icons.trending_up_rounded,
            title: 'Nenhum ganho registrado',
            subtitle: 'Ganhos criados pelo backend aparecem aqui.',
          )
        else
          ...store.earnings.take(4).map((earning) => _EarningRow(earning)),
        const SizedBox(height: 16),
        _SectionTitle(
          title: 'Transacoes',
          actionLabel: '${store.transactions.length}',
        ),
        const SizedBox(height: 8),
        if (store.transactions.isEmpty)
          const _StateCard(
            icon: Icons.receipt_long_outlined,
            title: 'Nenhuma transacao',
            subtitle: 'Saques solicitados aparecem no historico.',
          )
        else
          ...store.transactions.map(
            (transaction) => _TransactionRow(transaction),
          ),
      ],
    );
  }
}

class _WalletBalanceCard extends StatelessWidget {
  final DriverWalletModel? wallet;
  final double totalNetEarnings;
  final VoidCallback? onWithdrawTap;

  const _WalletBalanceCard({
    required this.wallet,
    required this.totalNetEarnings,
    required this.onWithdrawTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [Color(0xFF1B2397), Color(0xFF151E8C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text(
                'SALDO DISPONIVEL',
                style: TextStyle(
                  color: Color(0xFFD1D5FF),
                  fontWeight: FontWeight.w700,
                ),
              ),
              Spacer(),
              Icon(Icons.account_balance_wallet, color: Color(0xFFAFB6F3)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            wallet == null ? 'Carteira nao encontrada' : _formatMoney(wallet!.availableBalance),
            style: const TextStyle(
              color: FretColors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ganhos liquidos: ${_formatMoney(totalNetEarnings)}',
            style: const TextStyle(color: Color(0xFFD1D5FF), fontSize: 13),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onWithdrawTap,
              icon: const Icon(Icons.payments_outlined),
              label: const Text('Solicitar saque'),
              style: ElevatedButton.styleFrom(
                backgroundColor: FretColors.white,
                foregroundColor: FretColors.loginFooterLink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EarningRow extends StatelessWidget {
  final DriverEarningModel earning;

  const _EarningRow(this.earning);

  @override
  Widget build(BuildContext context) {
    return _ListRow(
      icon: Icons.trending_up_rounded,
      title: 'Corrida #${earning.rideId}',
      subtitle: 'Taxa app ${_formatMoney(earning.appFeeValue)}',
      trailing: _formatMoney(earning.netValue),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final WalletTransactionModel transaction;

  const _TransactionRow(this.transaction);

  @override
  Widget build(BuildContext context) {
    return _ListRow(
      icon: Icons.receipt_long_outlined,
      title: transaction.statusLabel,
      subtitle: [
        _formatDateTime(transaction.createdAt),
        transaction.pixKey,
      ].where((item) => item.isNotEmpty).join(' - '),
      trailing: '-${_formatMoney(transaction.value)}',
    );
  }
}

class _ListRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String trailing;

  const _ListRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _Panel(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            _IconBox(icon: icon),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: FretColors.neutral900,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: FretColors.neutral600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              trailing,
              style: const TextStyle(
                color: FretColors.loginFooterLink,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String actionLabel;

  const _SectionTitle({
    required this.title,
    required this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: FretColors.loginFooterLink,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        _StatusBadge(label: actionLabel, color: FretColors.primary100),
      ],
    );
  }
}

class _InfoGrid extends StatelessWidget {
  final List<_InfoItem> items;

  const _InfoGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 8) / 2;

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items
              .map(
                (item) => SizedBox(
                  width: itemWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.label,
                        style: const TextStyle(
                          color: FretColors.neutral500,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: FretColors.neutral900,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _InfoItem {
  final String label;
  final String value;

  const _InfoItem(this.label, this.value);
}

class _Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _Panel({
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
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
      child: child,
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;

  const _IconBox({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: FretColors.primary100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: FretColors.loginFooterLink, size: 21),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color,
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

class _StateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onTap;

  const _StateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
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

Color _offerColor(RideOfferModel offer) {
  return switch (offer.statusId) {
    1 => FretColors.attention200,
    2 => FretColors.success100,
    3 => FretColors.neutral200,
    4 => FretColors.destructive100,
    _ => FretColors.neutral100,
  };
}

Color _rideColor(DriverRideModel ride) {
  return switch (ride.statusId) {
    2 => FretColors.attention200,
    3 => FretColors.attention200,
    4 => FretColors.attention200,
    5 => FretColors.success100,
    6 => FretColors.destructive100,
    _ => FretColors.neutral200,
  };
}

String _formatMoney(double value) {
  final fixed = value.toStringAsFixed(2).replaceAll('.', ',');
  return 'R\$ $fixed';
}

String _formatNumber(double value) {
  return value.toStringAsFixed(2).replaceAll('.', ',');
}

String _formatDateTime(DateTime? value) {
  if (value == null) {
    return '';
  }

  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');

  return '$day/$month $hour:$minute';
}
