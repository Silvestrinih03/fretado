import 'package:flutter/material.dart';
import '../../../../app/design_system/design_system.dart';

class FillVehicleDetailedData extends StatelessWidget {
  final TextEditingController colorController;
  final bool enabled;
  final bool showCard;
  const FillVehicleDetailedData({
    super.key,
    required this.colorController,
    this.enabled = true,
    this.showCard = true,
  });

  @override
  Widget build(BuildContext context) {
    final field = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'COR',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: colorController,
          enabled: enabled,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'Ex.: Prata',
            fillColor: FretColors.white,
          ),
          validator: (value) => (value ?? '').trim().length > 50
              ? 'Informe uma cor com até 50 caracteres.'
              : null,
        ),
      ],
    );
    return showCard ? FretScreenCard(child: field) : field;
  }
}
