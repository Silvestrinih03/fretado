import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../app/design_system/design_system.dart';
import 'fret_map.dart';
import 'geocoding_credit.dart';

class AddressPointConfirmation extends StatefulWidget {
  final String title;
  final String address;
  final LatLng initialPoint;
  final bool exactMatch;
  const AddressPointConfirmation({
    super.key,
    required this.title,
    required this.address,
    required this.initialPoint,
    required this.exactMatch,
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
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(widget.address),
          const SizedBox(height: 8),
          Text(
            widget.exactMatch
                ? 'Confira o ponto de acesso. Toque no mapa para ajustar.'
                : 'Não localizamos esse número com precisão. Ajuste o ponto no mapa antes de confirmar.',
            style: const TextStyle(color: FretColors.textSecondary),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: MediaQuery.sizeOf(context).height * .36,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: FretMap(
                controller: _map,
                initialCenter: _point,
                delivery: _point,
                onReady: () => _map.move(_point, 17),
                onTap: (point) => setState(() => _point = point),
              ),
            ),
          ),
          const GeocodingCredit(),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_point),
            style: FilledButton.styleFrom(
              backgroundColor: FretColors.brandGraphite,
              minimumSize: const Size.fromHeight(50),
            ),
            child: const Text('Confirmar endereço e ponto'),
          ),
        ],
      ),
    ),
  );
}
