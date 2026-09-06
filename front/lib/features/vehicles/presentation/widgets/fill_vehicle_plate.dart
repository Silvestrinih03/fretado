import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/design_system/design_system.dart';
import '../stores/register_vehicle_store.dart';

class FillVehiclePlate extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;

  const FillVehiclePlate({super.key, required this.controller, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return FretSurfaceCard(
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        textCapitalization: TextCapitalization.characters,
        autocorrect: false,
        inputFormatters: [
          TextInputFormatter.withFunction((oldValue, newValue) {
            final text = RegisterVehicleStore.normalizePlate(newValue.text);
            final offset = newValue.selection.baseOffset;
            final normalizedOffset = offset < 0 ? text.length
                : RegisterVehicleStore.normalizePlate(
                    newValue.text.substring(0, offset)).length;
            return TextEditingValue(text: text,
                selection: TextSelection.collapsed(offset: normalizedOffset));
          }),
        ],
        validator: RegisterVehicleStore.validatePlate,
        decoration: const InputDecoration(labelText: 'Placa', hintText: 'ABC1D23'),
      ),
    );
  }
}
