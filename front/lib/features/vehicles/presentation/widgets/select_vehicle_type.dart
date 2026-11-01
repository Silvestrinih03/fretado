import 'package:flutter/material.dart';
import '../../../../app/design_system/design_system.dart';

import '../../data/models/vehicle_type_model.dart';

class SelectVehicleType extends StatelessWidget {
  final bool isLoading;
  final String? errorMessage;
  final List<VehicleTypeModel> vehicleTypes;
  final int? selectedVehicleTypeId;
  final ValueChanged<int> onSelected;

  const SelectVehicleType({
    super.key,
    required this.isLoading,
    required this.errorMessage,
    required this.vehicleTypes,
    required this.selectedVehicleTypeId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TIPO DE VEÍCULO',
          style: TextStyle(
            color: FretColors.screenMuted,
            fontWeight: FontWeight.w700,
            letterSpacing: .7,
            fontSize: 11.5,
          ),
        ),
        const SizedBox(height: 8),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else if (errorMessage != null)
          Text(
            errorMessage!,
            style: const TextStyle(color: FretColors.screenMuted),
          )
        else if (vehicleTypes.isEmpty)
          const Text(
            'Nenhum tipo de veículo encontrado.',
            style: TextStyle(color: FretColors.screenMuted),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: vehicleTypes.map((vehicleType) {
              final bool isSelected = selectedVehicleTypeId == vehicleType.id;
              return ChoiceChip(
                selected: isSelected,
                label: Text(vehicleType.label),
                onSelected: (_) => onSelected(vehicleType.id),
                backgroundColor: FretColors.screenBackground,
                selectedColor: FretColors.screenGold.withValues(alpha: .11),
                side: BorderSide(
                  color: isSelected
                      ? FretColors.screenGold
                      : FretColors.screenBorder,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                labelStyle: TextStyle(
                  color: FretColors.screenDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                showCheckmark: false,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}
