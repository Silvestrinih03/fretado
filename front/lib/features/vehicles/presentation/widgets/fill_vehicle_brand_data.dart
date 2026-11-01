import 'package:flutter/material.dart';
import '../../../../app/design_system/design_system.dart';
import '../../data/models/vehicle_catalog_option_model.dart';
import '../stores/register_vehicle_store.dart';

class FillVehicleBrandData extends StatelessWidget {
  final RegisterVehicleStore store;
  final List<Widget> children;
  const FillVehicleBrandData({
    super.key,
    required this.store,
    this.children = const [],
  });

  @override
  Widget build(BuildContext context) => FretScreenCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dados do veículo',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 14),
        _catalogField(
          'Marca',
          'brands',
          store.selectedBrand,
          true,
          store.selectBrand,
          store.loadBrands,
        ),
        const SizedBox(height: 10),
        _catalogField(
          'Modelo',
          'models',
          store.selectedModel,
          store.selectedBrand != null,
          store.selectModel,
          store.loadModels,
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _catalogField(
                'Versão',
                'versions',
                store.selectedVersion,
                store.selectedModel != null,
                store.selectVersion,
                store.loadVersions,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<int>(
                key: ValueKey(
                  'year:${store.selectedVersion}:${store.selectedYear}',
                ),
                initialValue: store.selectedYear,
                style: const TextStyle(
                  fontSize: 13,
                  color: FretColors.screenDark,
                ),
                isExpanded: true,
                decoration: const InputDecoration(hintText: 'Ano'),
                items: store.years
                    .map(
                      (year) =>
                          DropdownMenuItem(value: year, child: Text('$year')),
                    )
                    .toList(),
                onChanged:
                    store.selectedVersion != null && store.years.isNotEmpty
                    ? store.selectYear
                    : null,
                validator: (value) => value == null ? 'Selecione o ano.' : null,
              ),
            ),
          ],
        ),
        if (store.selectedVersion != null && store.years.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Esta versão não possui anos disponíveis. Selecione outra versão.',
            ),
          ),
        for (final child in children) ...[const SizedBox(height: 14), child],
      ],
    ),
  );

  Widget _catalogField(
    String label,
    String level,
    String? value,
    bool enabled,
    ValueChanged<String?> onChanged,
    VoidCallback onRetry,
  ) {
    final loading = store.isLoading(level);
    final error = store.error(level);
    final options = store.options(level);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey('$level:$value'),
          initialValue: value,
          style: const TextStyle(fontSize: 13, color: FretColors.screenDark),
          isExpanded: true,
          decoration: InputDecoration(hintText: label),
          items: options
              .map(
                (VehicleCatalogOptionModel item) => DropdownMenuItem(
                  value: item.value,
                  child: Text(item.label, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: enabled && !loading && options.isNotEmpty
              ? onChanged
              : null,
          validator: (value) =>
              value == null ? 'Selecione ${label.toLowerCase()}.' : null,
        ),
        if (loading) ...[
          const SizedBox(height: 8),
          const LinearProgressIndicator(minHeight: 3),
        ],
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(error),
          TextButton(
            onPressed: loading ? null : onRetry,
            child: const Text('Tentar novamente'),
          ),
        ],
      ],
    );
  }
}
