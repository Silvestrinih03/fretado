import 'package:flutter/material.dart';

import '../../../../app/design_system/design_system.dart';
import '../../data/models/vehicle_list_item_model.dart';

class VehicleCard extends StatelessWidget {
  final VehicleListItemModel vehicle;
  const VehicleCard({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return FretSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FretIconBox(
                icon: Icons.local_shipping_outlined,
                size: 48,
                iconSize: 26,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  vehicle.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: vehicle.isActive
                  ? FretColors.brandGoldSoft
                  : FretColors.appSurfaceSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              vehicle.isActive ? 'Ativo' : 'Inativo',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: vehicle.isActive
                    ? FretColors.brandBlack
                    : FretColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Wrap(
            spacing: 24,
            runSpacing: 16,
            children: [
              _VehicleMetaItem(label: 'Placa', value: vehicle.plate),
              _VehicleMetaItem(label: 'Ano', value: vehicle.yearText),
              _VehicleMetaItem(
                label: 'Cor',
                value: vehicle.color ?? 'N?o informada',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VehicleMetaItem extends StatelessWidget {
  final String label;
  final String value;
  const _VehicleMetaItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: FretColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          value.isEmpty ? 'Não informado' : value,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
