import 'dart:async';

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
  final ValueChanged<String> onBrandSearchChanged;
  final ValueChanged<String> onModelSearchChanged;
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
    required this.onBrandSearchChanged,
    required this.onModelSearchChanged,
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
        const SizedBox(height: 12),
        _formCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dados do veiculo',
                style: TextStyle(
                  color: Color(0xFF0F187C),
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              if (errorMessage != null) ...[
                Text(
                  errorMessage!,
                  style: const TextStyle(
                    color: Color(0xFFB00020),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (registerMode == 'fipe') ...[
                _autocompleteField(
                  label: 'Marca',
                  hint: 'Digite para buscar a marca',
                  value: selectedBrand,
                  items: brands,
                  onSelected: onBrandChanged,
                  onSearchChanged: onBrandSearchChanged,
                  enabled: !isLoadingFipe,
                  validator: (value) =>
                      value == null ? 'Selecione a marca' : null,
                ),
                const SizedBox(height: 8),
                _autocompleteField(
                  label: 'Modelo',
                  hint: 'Digite para buscar o modelo',
                  value: selectedModel,
                  items: models,
                  onSelected: onModelChanged,
                  onSearchChanged: onModelSearchChanged,
                  enabled: !isLoadingFipe && selectedBrand != null,
                  validator: (value) =>
                      value == null ? 'Selecione o modelo' : null,
                ),
                const SizedBox(height: 8),
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
                  const SizedBox(height: 8),
                  const LinearProgressIndicator(minHeight: 3),
                ],
              ] else ...[
                _filledTextField(
                  label: 'Marca',
                  controller: manualBrandController,
                  validator: (value) => requiredValidator(value, 'a marca'),
                ),
                const SizedBox(height: 8),
                _filledTextField(
                  label: 'Modelo',
                  controller: manualModelController,
                  validator: (value) => requiredValidator(value, 'o modelo'),
                ),
                const SizedBox(height: 8),
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

  Widget _autocompleteField({
    required String label,
    required String hint,
    required String? value,
    required List<VehicleFipeOptionModel> items,
    required ValueChanged<String?> onSelected,
    required ValueChanged<String> onSearchChanged,
    required bool enabled,
    required String? Function(String?) validator,
  }) {
    return _FipeAutocompleteField(
      label: label,
      hint: hint,
      value: value,
      items: items,
      enabled: enabled,
      onSelected: onSelected,
      onSearchChanged: onSearchChanged,
      validator: validator,
    );
  }

  Widget _formCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(12),
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
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFE2E4EA),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
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
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: value,
          validator: validator,
          onChanged: enabled ? onChanged : null,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF666C7E)),
          dropdownColor: const Color(0xFFE2E4EA),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF2B2D35), fontSize: 14),
            filled: true,
            fillColor: const Color(0xFFDCDDDF),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
            fontSize: 12,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}

class _FipeAutocompleteField extends StatefulWidget {
  final String label;
  final String hint;
  final String? value;
  final List<VehicleFipeOptionModel> items;
  final bool enabled;
  final ValueChanged<String?> onSelected;
  final ValueChanged<String> onSearchChanged;
  final String? Function(String?) validator;

  const _FipeAutocompleteField({
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.enabled,
    required this.onSelected,
    required this.onSearchChanged,
    required this.validator,
  });

  @override
  State<_FipeAutocompleteField> createState() => _FipeAutocompleteFieldState();
}

class _FipeAutocompleteFieldState extends State<_FipeAutocompleteField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  String? _lastAppliedValue;

  @override
  void initState() {
    super.initState();
    _applySelectedValue();
  }

  @override
  void didUpdateWidget(covariant _FipeAutocompleteField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value || oldWidget.items != widget.items) {
      _applySelectedValue();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _applySelectedValue() {
    if (_lastAppliedValue == widget.value) {
      return;
    }

    _lastAppliedValue = widget.value;
    final String label = _selectedLabel(widget.value) ?? '';
    if (_controller.text != label) {
      _controller.text = label;
    }
  }

  String? _selectedLabel(String? value) {
    if (value == null) {
      return null;
    }

    for (final item in widget.items) {
      if (item.value == value) {
        return item.label;
      }
    }

    return null;
  }

  void _scheduleSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      widget.onSearchChanged(value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<VehicleFipeOptionModel>(
      textEditingController: _controller,
      focusNode: _focusNode,
      displayStringForOption: (option) => option.label,
      optionsBuilder: (textEditingValue) {
        final String query = textEditingValue.text.trim().toLowerCase();
        if (query.isEmpty) {
          return widget.items;
        }

        return widget.items.where(
          (item) => item.label.toLowerCase().contains(query),
        );
      },
      onSelected: (option) {
        _debounce?.cancel();
        _lastAppliedValue = option.value;
        widget.onSelected(option.value);
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.label,
              style: const TextStyle(
                color: Color(0xFFB6B9C6),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            TextFormField(
              controller: controller,
              focusNode: focusNode,
              enabled: widget.enabled,
              validator: (_) => widget.validator(widget.value),
              onChanged: (value) {
                if (widget.value != null && value != _selectedLabel(widget.value)) {
                  _lastAppliedValue = null;
                  widget.onSelected(null);
                }
                _scheduleSearch(value);
              },
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: const TextStyle(
                  color: Color(0xFF2B2D35),
                  fontSize: 14,
                ),
                suffixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF666C7E),
                ),
                filled: true,
                fillColor: const Color(0xFFDCDDDF),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        final List<VehicleFipeOptionModel> visibleOptions =
            options.take(20).toList();

        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240, maxWidth: 360),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: visibleOptions.length,
                itemBuilder: (context, index) {
                  final option = visibleOptions[index];
                  return ListTile(
                    dense: true,
                    title: Text(
                      option.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
