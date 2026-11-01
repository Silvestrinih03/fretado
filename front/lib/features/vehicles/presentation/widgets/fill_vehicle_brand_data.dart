import 'package:flutter/material.dart';

import '../../../../app/design_system/design_system.dart';
import 'vehicle_catalog_select.dart';
import '../stores/register_vehicle_store.dart';

class FillVehicleBrandData extends StatelessWidget {
  final RegisterVehicleStore store;
  const FillVehicleBrandData({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return FretSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dados do veículo',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          _catalogField(
            'Marca',
            'brands',
            store.selectedBrand,
            true,
            store.selectBrand,
          ),
          const SizedBox(height: 16),
          _catalogField(
            'Modelo',
            'models',
            store.selectedModel,
            store.selectedBrand != null,
            store.selectModel,
          ),
          const SizedBox(height: 16),
          _catalogField(
            'Versão',
            'versions',
            store.selectedVersion,
            store.selectedModel != null,
            store.selectVersion,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            key: ValueKey(
              'year:${store.selectedVersion}:${store.selectedYear}',
            ),
            initialValue: store.selectedYear,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Ano'),
            items: store.years
                .map(
                  (year) => DropdownMenuItem(value: year, child: Text('$year')),
                )
                .toList(),
            onChanged: store.selectedVersion != null && store.years.isNotEmpty
                ? store.selectYear
                : null,
            validator: (value) => value == null ? 'Selecione o ano.' : null,
          ),
          if (store.selectedVersion != null && store.years.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Esta versão não possui anos disponíveis. Selecione outra versão.',
              ),
            ),
        ],
      ),
    );
  }

  Widget _catalogField(
    String label,
    String level,
    String? value,
    bool enabled,
    ValueChanged<String?> onChanged,
  ) => VehicleCatalogSelect(
    store: store,
    label: label,
    level: level,
    value: value,
    enabled: enabled,
    onChanged: onChanged,
  );
}
