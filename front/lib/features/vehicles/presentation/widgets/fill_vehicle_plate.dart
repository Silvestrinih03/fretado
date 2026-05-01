import 'package:flutter/material.dart';

class FillVehiclePlate extends StatelessWidget {
  final TextEditingController controller;
  final String? Function(String?, String) requiredValidator;

  const FillVehiclePlate({
    super.key,
    required this.controller,
    required this.requiredValidator,
  });

  @override
  Widget build(BuildContext context) {
    return _UnderlineInputCard(
      label: 'PLACA',
      hint: 'ABC1D23',
      controller: controller,
      keyboardType: TextInputType.text,
      textCapitalization: TextCapitalization.characters,
      validator: (value) => requiredValidator(value, 'a placa'),
    );
  }
}

class _UnderlineInputCard extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;

  const _UnderlineInputCard({
    required this.label,
    required this.hint,
    required this.controller,
    required this.keyboardType,
    required this.textCapitalization,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFB2B5C4),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            textCapitalization: textCapitalization,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: Color(0xFFDBDDE5),
              letterSpacing: 0.4,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: hint,
              hintStyle: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                color: Color(0xFFD8DAE3),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const Divider(color: Color(0xFFD6D8E2), thickness: 2),
        ],
      ),
    );
  }
}