import 'package:flutter/material.dart';
import '../../../../app/design_system/design_system.dart';

class FillVehicleDetailedData extends StatelessWidget {
  final TextEditingController colorController;
  final bool enabled;

  const FillVehicleDetailedData({
    super.key,
    required this.colorController,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return FretSurfaceCard(
      child: TextFormField(
        controller: colorController,
        enabled: enabled,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(labelText: 'Cor', hintText: 'Branco'),
        validator: (value) => (value ?? '').trim().length > 50
            ? 'Informe uma cor com at? 50 caracteres.' : null,
      ),
    );
  }
}
