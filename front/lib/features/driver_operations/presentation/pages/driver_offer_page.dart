import 'package:flutter/material.dart';

import '../../../../app/design_system/design_system.dart';
import '../controllers/driver_offer_controller.dart';

class DriverOfferPage extends StatefulWidget {
  final DriverOfferController controller;
  final int offerId;

  const DriverOfferPage({super.key, required this.controller, required this.offerId});

  @override
  State<DriverOfferPage> createState() => _DriverOfferPageState();
}

class _DriverOfferPageState extends State<DriverOfferPage> {
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  void _onChanged() {
    final controller = widget.controller;
    if (_leaving || !mounted || controller.isActing) return;
    if (controller.pending?.offer.id != widget.offerId) {
      _leaving = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pop(controller.acceptedOfferId == widget.offerId);
        }
      });
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final controller = widget.controller;
      final pending = controller.pending;
      if (pending == null || pending.offer.id != widget.offerId) {
        return const Scaffold(body: Center(child: Text('Oferta encerrada')));
      }
      final offer = pending.offer;
      final ride = pending.ride;
      final seconds = offer.remainingSeconds;
      final timer = '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
      final disabled = controller.isActing || offer.isExpired;
      return PopScope(
        canPop: !controller.isActing,
        child: Scaffold(
          backgroundColor: FretColors.appBackground,
          appBar: AppBar(
            backgroundColor: FretColors.appBackground,
            title: Text('Corrida #${ride.id}'),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 20),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: FretColors.brandBlack,
                  borderRadius: BorderRadius.circular(11)),
                child: Text(timer, style: const TextStyle(
                  color: FretColors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              const Text('NOVA OFERTA PARA VOCÊ', style: TextStyle(
                color: FretColors.brandGoldDark, fontWeight: FontWeight.w800,
                fontSize: 11, letterSpacing: 1.2)),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: offer.remainingFraction, minHeight: 4,
                color: FretColors.brandGold, backgroundColor: FretColors.neutral200),
              const SizedBox(height: 18),
              FretSurfaceCard(
                color: FretColors.brandBlack, radius: 21,
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Valor do frete', style: TextStyle(color: Colors.white60, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('R\$ ${ride.totalPrice.toStringAsFixed(2).replaceAll('.', ',')}',
                    style: const TextStyle(color: FretColors.white, fontSize: 31, fontWeight: FontWeight.w800)),
                  const Divider(color: Colors.white12, height: 30),
                  Row(children: [
                    Expanded(child: _Metric('Carga', ride.details == null
                        ? 'Não informada' : '${ride.packageWeight} kg')),
                    Expanded(child: _Metric('Veículo', ride.vehicleCategoryLabel)),
                  ]),
                ]),
              ),
              const SizedBox(height: 12),
              FretSurfaceCard(
                radius: 17, padding: const EdgeInsets.all(18),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Rota da entrega', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 18),
                  _RoutePoint('COLETA', ride.originLabel, FretColors.brandGold),
                  const SizedBox(height: 20),
                  _RoutePoint('ENTREGA', ride.destinationLabel, FretColors.brandBlack),
                  if (ride.details != null) ...[
                    const Divider(height: 28),
                    Text('Dimensões: ${ride.details!.packageWidth} × ${ride.details!.packageHeight} × ${ride.details!.packageLength} cm',
                      style: const TextStyle(fontSize: 12, color: FretColors.textSecondary)),
                  ],
                ]),
              ),
              const SizedBox(height: 12),
              FretSurfaceCard(
                color: FretColors.brandGoldSoft, radius: 14,
                padding: const EdgeInsets.all(14),
                child: const Text(
                  'Esta oferta foi selecionada para você com base na sua localização e no veículo cadastrado.',
                  style: TextStyle(fontSize: 12, height: 1.5, color: FretColors.brandGoldDark)),
              ),
              if (controller.error != null) ...[
                const SizedBox(height: 12),
                Text(controller.error!, style: const TextStyle(color: FretColors.destructive700)),
                TextButton(onPressed: disabled ? null : controller.refresh,
                  child: const Text('Atualizar oferta')),
              ],
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: disabled ? null : () => controller.respond(accept: false),
                  child: const Text('Recusar'))),
                const SizedBox(width: 10),
                Expanded(flex: 2, child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: FretColors.brandGold, foregroundColor: FretColors.brandBlack),
                  onPressed: disabled ? null : () => controller.respond(accept: true),
                  child: Text(controller.isActing ? 'Confirmando...' : 'Aceitar corrida'))),
              ]),
            ),
          ),
        ),
      );
    },
  );
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  const _Metric(this.label, this.value);
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
    ],
  );
}

class _RoutePoint extends StatelessWidget {
  final String label;
  final String address;
  final Color color;
  const _RoutePoint(this.label, this.address, this.color);
  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Icon(Icons.location_on_rounded, color: color, size: 20),
    const SizedBox(width: 12),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: FretColors.textSecondary, fontSize: 10)),
      const SizedBox(height: 4),
      Text(address, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
    ])),
  ]);
}
