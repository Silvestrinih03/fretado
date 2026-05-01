import 'package:flutter/material.dart';

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
            color: Color(0xFF6D7080),
            fontWeight: FontWeight.w700,
            letterSpacing: 1.6,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 12),
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
            style: const TextStyle(color: Color(0xFFB15D16)),
          )
        else if (vehicleTypes.isEmpty)
          const Text(
            'Nenhum tipo de veículo encontrado.',
            style: TextStyle(color: Color(0xFF7C8090)),
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: vehicleTypes.map((vehicleType) {
              final bool isSelected = selectedVehicleTypeId == vehicleType.id;
              return ChoiceChip(
                selected: isSelected,
                label: Text(vehicleType.label),
                onSelected: (_) => onSelected(vehicleType.id),
                backgroundColor: const Color(0xFFF1F2F6),
                selectedColor: const Color(0xFF0E1788),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF0E1788)
                      : const Color(0xFFB8BDCC),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF2C2F3A),
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
                showCheckmark: false,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}