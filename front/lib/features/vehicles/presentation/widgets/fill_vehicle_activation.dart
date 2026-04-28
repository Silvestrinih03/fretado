import 'package:flutter/material.dart';

class FillVehicleActivation extends StatelessWidget {
  final bool isActive;
  final ValueChanged<bool> onChanged;

  const FillVehicleActivation({
    super.key,
    required this.isActive,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _FormCard(
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Veículo Ativo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF20222B),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Este veículo estará disponível para novas corridas.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF7C8090),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isActive,
            onChanged: onChanged,
            activeTrackColor: const Color(0xFFB85D07),
            inactiveTrackColor: const Color(0xFFC9CCD7),
            activeColor: Colors.white,
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