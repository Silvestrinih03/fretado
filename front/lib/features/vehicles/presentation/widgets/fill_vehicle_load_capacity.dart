import 'package:flutter/material.dart';

class FillVehicleLoadCapacity extends StatelessWidget {
  final TextEditingController controller;
  final String? Function(String?, String) requiredValidator;

  const FillVehicleLoadCapacity({
    super.key,
    required this.controller,
    required this.requiredValidator,
  });

  @override
  Widget build(BuildContext context) {
    return _UnderlineInputCard(
      label: 'CAPACIDADE DE CARGA (KG)',
      hint: '0',
      controller: controller,
      keyboardType: TextInputType.number,
      validator: (value) {
        final String? required = requiredValidator(
          value,
          'a capacidade de carga',
        );
        if (required != null) {
          return required;
        }

        final int? parsed = int.tryParse(value!.trim());
        if (parsed == null || parsed <= 0) {
          return 'Informe um valor maior que 0';
        }

        return null;
      },
    );
  }
}

class _UnderlineInputCard extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _UnderlineInputCard({
    required this.label,
    required this.hint,
    required this.controller,
    required this.keyboardType,
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