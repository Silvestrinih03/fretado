import 'package:flutter/material.dart';

import '../../../../app/design_system/design_system.dart';
import '../controllers/driver_offer_controller.dart';

class DriverOfferPage extends StatelessWidget {
  final DriverOfferController controller;
  final ValueChanged<bool>? onResolved;

  const DriverOfferPage({super.key, required this.controller, this.onResolved});

  Future<void> _respond(bool accept) async {
    final success = await controller.respond(accept: accept);
    if (success) onResolved?.call(accept);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final pending = controller.pending;
      if (pending == null) {
        return const ColoredBox(
          color: FretColors.appBackground,
          child: Center(
            child: CircularProgressIndicator(color: FretColors.brandGold),
          ),
        );
      }

      final ride = pending.ride;
      final isTransfer = pending.offer.isCargoTransfer;
      final reassignment = pending.offer.reassignment;
      final isActing = controller.isActing;

      return PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: FretColors.appBackground,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isTransfer
                            ? 'TRANSFERÊNCIA DE CARGA'
                            : 'NOVA SOLICITAÇÃO',
                        style: const TextStyle(
                          color: FretColors.brandGoldDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Corrida #${ride.id}',
                              style: const TextStyle(
                                color: FretColors.brandBlack,
                                fontSize: 24,
                                height: 1,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Container(
                            constraints: const BoxConstraints(minWidth: 52),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: FretColors.brandBlack,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _formatElapsed(controller.elapsed),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: FretColors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: const LinearProgressIndicator(
                          minHeight: 5,
                          color: FretColors.brandGold,
                          backgroundColor: FretColors.neutral200,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                    children: [
                      _EarningsCard(
                        value: isTransfer
                            ? reassignment?.incomingNetValue ?? 0
                            : ride.driverNetValue,
                        distanceKm: pending.distanceKm,
                        approximate: pending.distanceIsApproximate,
                        weightKg: ride.packageWeight,
                        vehicle: ride.vehicleCategoryLabel,
                      ),
                      const SizedBox(height: 16),
                      _RouteCard(
                        origin: isTransfer
                            ? reassignment?.handoffAddress ??
                                  'Ponto de transferência definido pelo motorista'
                            : ride.originLabel,
                        destination: ride.destinationLabel,
                        title: isTransfer
                            ? 'Trecho após a transferência'
                            : 'Rota da entrega',
                      ),
                      const SizedBox(height: 16),
                      const _SelectionNotice(),
                      if (controller.error != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: FretColors.destructive050,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: FretColors.destructive200,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: FretColors.destructive700,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  controller.error!,
                                  style: const TextStyle(
                                    color: FretColors.destructive700,
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              color: FretColors.appBackground,
              border: Border(top: BorderSide(color: FretColors.neutral200)),
            ),
            child: SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(24, 10, 24, 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: FretColors.textSecondary,
                          side: const BorderSide(color: FretColors.neutral200),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: isActing ? null : () => _respond(false),
                        child: const Text(
                          'Recusar',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 6,
                    child: SizedBox(
                      height: 52,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: FretColors.brandGold,
                          foregroundColor: FretColors.brandBlack,
                          disabledBackgroundColor: FretColors.brandGold,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: isActing ? null : () => _respond(true),
                        child: isActing
                            ? const SizedBox.square(
                                dimension: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: FretColors.brandBlack,
                                ),
                              )
                            : Text(
                                isTransfer
                                    ? 'Aceitar transferência'
                                    : 'Aceitar corrida',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _EarningsCard extends StatelessWidget {
  final double value;
  final double distanceKm;
  final bool approximate;
  final double weightKg;
  final String vehicle;

  const _EarningsCard({
    required this.value,
    required this.distanceKm,
    required this.approximate,
    required this.weightKg,
    required this.vehicle,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 19),
    decoration: BoxDecoration(
      color: FretColors.brandBlack,
      borderRadius: BorderRadius.circular(23),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Você receberá',
          style: TextStyle(color: Colors.white54, fontSize: 13),
        ),
        const SizedBox(height: 7),
        Text(
          _formatCurrency(value),
          style: const TextStyle(
            color: FretColors.white,
            fontSize: 31,
            height: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Divider(height: 1, color: Colors.white12),
        ),
        Row(
          children: [
            Expanded(
              child: _OfferMetric(
                label: 'Distância',
                value:
                    '${approximate ? '~' : ''}${_formatNumber(distanceKm)} km',
              ),
            ),
            Expanded(
              child: _OfferMetric(
                label: 'Carga',
                value: '${_formatNumber(weightKg)} kg',
              ),
            ),
            Expanded(
              child: _OfferMetric(label: 'Veículo', value: vehicle),
            ),
          ],
        ),
      ],
    ),
  );
}

class _OfferMetric extends StatelessWidget {
  final String label;
  final String value;

  const _OfferMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.white38, fontSize: 11),
      ),
      const SizedBox(height: 7),
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: FretColors.white,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );
}

class _RouteCard extends StatelessWidget {
  final String origin;
  final String destination;
  final String title;

  const _RouteCard({
    required this.origin,
    required this.destination,
    required this.title,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(18, 18, 18, 19),
    decoration: BoxDecoration(
      color: FretColors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: FretColors.neutral200),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 12,
                child: Column(
                  children: [
                    const _RouteDot(color: FretColors.brandGold),
                    Expanded(
                      child: Container(
                        width: 1,
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        color: FretColors.neutral300,
                      ),
                    ),
                    const _RouteDot(color: FretColors.brandBlack),
                  ],
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Address(label: 'COLETA', value: origin),
                    const SizedBox(height: 18),
                    _Address(label: 'ENTREGA', value: destination),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _RouteDot extends StatelessWidget {
  final Color color;

  const _RouteDot({required this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _Address extends StatelessWidget {
  final String label;
  final String value;

  const _Address({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(color: FretColors.textSecondary, fontSize: 11),
      ),
      const SizedBox(height: 7),
      Text(
        value,
        style: const TextStyle(
          color: FretColors.brandBlack,
          fontSize: 14,
          height: 1.3,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _SelectionNotice extends StatelessWidget {
  const _SelectionNotice();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: FretColors.brandGoldSoft,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: FretColors.primary200),
    ),
    child: const Text(
      'Esta oferta foi selecionada para você com base na sua localização '
      'e no veículo cadastrado.',
      style: TextStyle(
        color: FretColors.brandGoldDark,
        fontSize: 12,
        height: 1.45,
      ),
    ),
  );
}

String _formatElapsed(Duration duration) {
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  if (duration.inHours > 0) return '${duration.inHours}:$minutes:$seconds';
  return '$minutes:$seconds';
}

String _formatCurrency(double value) {
  final parts = value.toStringAsFixed(2).split('.');
  final digits = parts.first;
  final grouped = digits.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  return 'R\$ $grouped,${parts.last}';
}

String _formatNumber(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(1).replaceAll('.', ',');
}
