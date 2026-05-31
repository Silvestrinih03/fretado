import 'package:flutter/material.dart';

class VehicleCard extends StatelessWidget {
  final String plate;
  final String year;
  final String brand;
  final String model;
  final String statusLabel;
  final Color statusBackgroundColor;
  final Color statusTextColor;

  const VehicleCard({
    super.key,
    required this.plate,
    required this.year,
    required this.brand,
    required this.model,
    required this.statusLabel,
    required this.statusBackgroundColor,
    required this.statusTextColor,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint(
      'Dados do veiculo: marca: $brand, modelo: $model, placa: $plate, ano: $year, status: $statusLabel',
    );
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E6EE)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F1A4A),
            blurRadius: 9,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFF0F1F4),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.local_shipping_rounded,
                  size: 36,
                  color: Color(0xFF9CA0C8),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            brand,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF121E84),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusBackgroundColor,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              color: statusTextColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _VehicleMetaItem(label: 'PLACA', value: plate),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _VehicleMetaItem(label: 'ANO', value: year),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const _VehicleMetaItem(label: 'MODELO'),
                    const SizedBox(height: 4),
                    Text(
                      model,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF101114),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleMetaItem extends StatelessWidget {
  final String label;
  final String? value;

  const _VehicleMetaItem({required this.label, this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFF9296A5),
            letterSpacing: 0,
          ),
        ),
        if (value != null) ...[
          const SizedBox(height: 2),
          Text(
            value!,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0E1015),
            ),
          ),
        ],
      ],
    );
  }
}
