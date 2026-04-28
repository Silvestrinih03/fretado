import 'package:flutter/material.dart';

import '../../data/models/vehicle_fipe_option_model.dart';

class FillVehicleBrandData extends StatelessWidget {
  final String registerMode;
  final ValueChanged<String> onRegisterModeChanged;
  final String? selectedBrand;
  final String? selectedModel;
  final String? selectedYear;
  final List<VehicleFipeOptionModel> brands;
  final List<VehicleFipeOptionModel> models;
  final List<VehicleFipeOptionModel> years;
  final TextEditingController manualBrandController;
  final TextEditingController manualModelController;
  final TextEditingController manualYearController;
  final ValueChanged<String?> onBrandChanged;
  final ValueChanged<String?> onModelChanged;
  final ValueChanged<String?> onYearChanged;
  final bool isLoadingFipe;
  final String? errorMessage;
  final String? Function(String?, String) requiredValidator;

  const FillVehicleBrandData({
    super.key,
    required this.registerMode,
    required this.onRegisterModeChanged,
    required this.selectedBrand,
    required this.selectedModel,
    required this.selectedYear,
    required this.brands,
    required this.models,
    required this.years,
    required this.manualBrandController,
    required this.manualModelController,
    required this.manualYearController,
    required this.onBrandChanged,
    required this.onModelChanged,
    required this.onYearChanged,
    required this.isLoadingFipe,
    required this.errorMessage,
    required this.requiredValidator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFE7E8ED),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              Expanded(
                child: _ModeButton(
                  label: 'Buscar pelo catálogo\nFIPE',
                  selected: registerMode == 'fipe',
                  onTap: () => onRegisterModeChanged('fipe'),
                ),
              ),
              Expanded(
                child: _ModeButton(
                  label: 'Preencher\nmanualmente',
                  selected: registerMode == 'manual',
                  onTap: () => onRegisterModeChanged('manual'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _formCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dados do veiculo',
                style: TextStyle(
                  color: Color(0xFF0F187C),
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 16),
              if (errorMessage != null) ...[
                Text(
                  errorMessage!,
                  style: const TextStyle(
                    color: Color(0xFFB00020),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
              ],
              if (registerMode == 'fipe') ...[
                _selectField(
                  label: 'Marca',
                  hint: 'Selecione a marca',
                  value: selectedBrand,
                  items: brands,
                  onChanged: onBrandChanged,
                  enabled: !isLoadingFipe && brands.isNotEmpty,
                  validator: (value) =>
                      value == null ? 'Selecione a marca' : null,
                ),
                const SizedBox(height: 12),
                _selectField(
                  label: 'Modelo',
                  hint: 'Selecione o modelo',
                  value: selectedModel,
                  items: models,
                  onChanged: onModelChanged,
                  enabled: !isLoadingFipe && models.isNotEmpty,
                  validator: (value) =>
                      value == null ? 'Selecione o modelo' : null,
                ),
                const SizedBox(height: 12),
                _selectField(
                  label: 'Ano/Versao',
                  hint: 'Selecione o ano',
                  value: selectedYear,
                  items: years,
                  onChanged: onYearChanged,
                  enabled: !isLoadingFipe && years.isNotEmpty,
                  validator: (value) =>
                      value == null ? 'Selecione o ano/versao' : null,
                ),
                if (isLoadingFipe) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(minHeight: 3),
                ],
              ] else ...[
                _filledTextField(
                  label: 'Marca',
                  controller: manualBrandController,
                  validator: (value) => requiredValidator(value, 'a marca'),
                ),
                const SizedBox(height: 12),
                _filledTextField(
                  label: 'Modelo',
                  controller: manualModelController,
                  validator: (value) => requiredValidator(value, 'o modelo'),
                ),
                const SizedBox(height: 12),
                _filledTextField(
                  label: 'Ano',
                  controller: manualYearController,
                  keyboardType: TextInputType.number,
                  validator: (value) => requiredValidator(value, 'o ano'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _formCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EF)),
      ),
      child: child,
    );
  }

  Widget _filledTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF878B9B),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFE2E4EA),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            errorStyle: const TextStyle(height: 0.9),
          ),
        ),
      ],
    );
  }

  Widget _selectField({
    required String label,
    required String hint,
    required String? value,
    required List<VehicleFipeOptionModel> items,
    required ValueChanged<String?> onChanged,
    required bool enabled,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFB6B9C6),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          validator: validator,
          onChanged: enabled ? onChanged : null,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF666C7E)),
          dropdownColor: const Color(0xFFE2E4EA),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF2B2D35), fontSize: 18),
            filled: true,
            fillColor: const Color(0xFFDCDDDF),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
          items: items
              .map(
                (item) =>
                    DropdownMenuItem<String>(
                      value: item.value,
                      child: Text(item.label),
                    ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF7F8FB) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected
                ? const Color(0xFF121C84)
                : const Color(0xFF272A36),
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 16,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}