import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../app/design_system/design_system.dart';
import 'fret_map.dart';
import 'geocoding_credit.dart';

/// Confirms the customer's access point, before route and price calculation.
class AddressPointConfirmation extends StatefulWidget {
  final String title;
  final String address;
  final LatLng initialPoint;
  final bool exactMatch;
  final bool isPickup;
  final String? source;

  const AddressPointConfirmation({
    super.key,
    required this.title,
    required this.address,
    required this.initialPoint,
    required this.exactMatch,
    required this.isPickup,
    this.source,
  });

  @override
  State<AddressPointConfirmation> createState() =>
      _AddressPointConfirmationState();
}

class _AddressPointConfirmationState extends State<AddressPointConfirmation> {
  late LatLng _point = widget.initialPoint;
  final _map = FretMapController();

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.isPickup ? 'PONTO DE COLETA' : 'PONTO DE ENTREGA',
            style: const TextStyle(
              color: FretColors.brandGoldDark,
              fontSize: 11,
              letterSpacing: 1,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.title,
            style: const TextStyle(
              color: FretColors.brandGraphite,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(widget.address, style: const TextStyle(height: 1.5)),
          const SizedBox(height: 8),
          Text(
            widget.exactMatch
                ? 'Confira o ponto de acesso. Toque no mapa para ajustar.'
                : 'Não localizamos esse número com precisão. Confira e ajuste o ponto no mapa antes de confirmar.',
            style: const TextStyle(color: FretColors.neutral600, height: 1.5),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: MediaQuery.sizeOf(context).height * .36,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: FretMap(
                controller: _map,
                initialCenter: _point,
                pickup: widget.isPickup ? _point : null,
                delivery: widget.isPickup ? null : _point,
                onReady: () => _map.move(_point, 17),
                onTap: (point) => setState(() => _point = point),
              ),
            ),
          ),
          const SizedBox(height: 8),
          GeocodingCredit(source: widget.source),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(_point),
            style: FilledButton.styleFrom(
              backgroundColor: FretColors.brandGraphite,
              foregroundColor: FretColors.white,
              minimumSize: const Size.fromHeight(52),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.check_rounded, color: FretColors.brandGold),
            label: const Text(
              'Confirmar endereço e ponto',
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: FretColors.brandGraphite,
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Voltar aos detalhes'),
          ),
        ],
      ),
    ),
  );
}
