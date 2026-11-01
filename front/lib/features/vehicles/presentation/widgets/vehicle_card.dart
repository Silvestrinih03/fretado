import 'package:flutter/material.dart';
import '../../../../app/design_system/design_system.dart';
import '../../data/models/vehicle_list_item_model.dart';

class VehicleCard extends StatelessWidget {
  final VehicleListItemModel vehicle;
  const VehicleCard({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) => FretScreenCard(
    radius: 20,
    padding: EdgeInsets.zero,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 4,
            color: vehicle.isActive
                ? FretColors.screenGold
                : FretColors.screenBorder,
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Row(
                  children: [
                    const FretIconBox(
                      icon: Icons.local_shipping_outlined,
                      size: 54,
                      radius: 16,
                      iconSize: 26,
                      backgroundColor: FretColors.screenDark,
                      iconColor: FretColors.screenGold,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vehicle.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${vehicle.color ?? 'Cor não informada'} · ${vehicle.yearText}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: FretColors.screenMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: vehicle.isActive
                            ? FretColors.screenGold.withValues(alpha: .12)
                            : FretColors.screenBackground,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        vehicle.isActive ? 'ATIVO' : 'INATIVO',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: vehicle.isActive
                              ? const Color(0xFF806515)
                              : FretColors.screenMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: FretColors.screenBackground,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: FretColors.screenBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PLACA',
                        style: TextStyle(
                          fontSize: 9.5,
                          color: FretColors.screenMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        vehicle.plate.isEmpty ? 'Não informada' : vehicle.plate,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
