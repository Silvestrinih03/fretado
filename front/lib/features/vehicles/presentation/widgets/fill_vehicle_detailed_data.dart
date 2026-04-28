import 'package:flutter/material.dart';

class FillVehicleDetailedData extends StatelessWidget {
  final TextEditingController colorController;
  final TextEditingController widthController;
  final TextEditingController heightController;
  final TextEditingController lengthController;

  const FillVehicleDetailedData({
    super.key,
    required this.colorController,
    required this.widthController,
    required this.heightController,
    required this.lengthController,
  });

  @override
  Widget build(BuildContext context) {
    return _FormCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text(
                'Detalhes',
                style: TextStyle(
                  color: Color(0xFF0F187C),
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
              SizedBox(width: 8),
              Text(
                '(opcional)',
                style: TextStyle(
                  color: Color(0xFFB2B5C4),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Spacer(),
              Icon(Icons.straighten, color: Color(0xFFB2B5C4)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _FilledTextField(
                  label: 'COR',
                  hint: 'Ex: Branco',
                  controller: colorController,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FilledTextField(
                  label: 'LARGURA (CM)',
                  hint: '0',
                  controller: widthController,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _FilledTextField(
                  label: 'ALTURA (CM)',
                  hint: '0',
                  controller: heightController,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FilledTextField(
                  label: 'COMP. (CM)',
                  hint: '0',
                  controller: lengthController,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  final Widget child;

  const _FormCard({required this.child});

  @override
  Widget build(BuildContext context) {
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
}

class _FilledTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType keyboardType;

  const _FilledTextField({
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
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
}