import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/design_system/design_system.dart';
import '../stores/register_vehicle_store.dart';

class FillVehiclePlate extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final bool showCard;

  const FillVehiclePlate({
    super.key,
    required this.controller,
    this.enabled = true,
    this.showCard = true,
  });

  @override
  Widget build(BuildContext context) {
    final field = TextFormField(
      controller: controller,
      enabled: enabled,
      textCapitalization: TextCapitalization.characters,
      autocorrect: false,
      inputFormatters: [
        TextInputFormatter.withFunction((oldValue, newValue) {
          final text = RegisterVehicleStore.normalizePlate(newValue.text);
          final offset = newValue.selection.baseOffset;
          final normalizedOffset = offset < 0
              ? text.length
              : RegisterVehicleStore.normalizePlate(
                  newValue.text.substring(0, offset),
                ).length;
          return TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: normalizedOffset),
          );
        }),
      ],
      validator: RegisterVehicleStore.validatePlate,
      decoration: const InputDecoration(
        hintText: 'ABC1D23',
        fillColor: FretColors.white,
      ),
    );
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PLACA',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 7),
        field,
      ],
    );
    return showCard ? FretScreenCard(child: content) : content;
  }
}
