import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../../app/design_system/design_system.dart';
import '../stores/register_vehicle_store.dart';

class VehicleCatalogSelect extends StatelessWidget {
  final RegisterVehicleStore store;
  final String level;
  final String label;
  final String? value;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  const VehicleCatalogSelect({
    super.key,
    required this.store,
    required this.level,
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    String? selectedLabel;
    for (final option in store.options(level)) {
      if (option.value == value) selectedLabel = option.label;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormField<String>(
          key: ValueKey('$level:$value'),
          initialValue: value,
          validator: (selected) =>
              selected == null ? 'Selecione ${label.toLowerCase()}.' : null,
          builder: (field) => InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: !enabled || store.isRegisteringVehicle
                ? null
                : () async {
                    final result = await showDialog<String>(
                      context: context,
                      builder: (_) => _CatalogOptionsDialog(
                        store: store,
                        level: level,
                        label: label,
                        selected: value,
                      ),
                    );
                    if (!context.mounted || result == null) return;
                    field.didChange(result);
                    onChanged(result);
                  },
            child: InputDecorator(
              isEmpty: selectedLabel == null,
              decoration: InputDecoration(
                labelText: label,
                enabled: enabled,
                errorText: field.errorText,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedLabel ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 22,
                    color: FretColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (store.isLoading(level)) ...[
          const SizedBox(height: 8),
          const LinearProgressIndicator(minHeight: 3),
        ],
        if (store.error(level) != null) ...[
          const SizedBox(height: 8),
          Text(store.error(level)!),
          TextButton(
            onPressed: store.isLoading(level) ? null : () => store.retry(level),
            child: const Text('Tentar novamente'),
          ),
        ],
      ],
    );
  }
}

class _CatalogOptionsDialog extends StatefulWidget {
  final RegisterVehicleStore store;
  final String level;
  final String label;
  final String? selected;
  const _CatalogOptionsDialog({
    required this.store,
    required this.level,
    required this.label,
    required this.selected,
  });

  @override
  State<_CatalogOptionsDialog> createState() => _CatalogOptionsDialogState();
}

class _CatalogOptionsDialogState extends State<_CatalogOptionsDialog> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static String _normalize(String text) => text
      .toLowerCase()
      .replaceAll(RegExp(r'[áàâãäå]'), 'a')
      .replaceAll(RegExp(r'[éèêë]'), 'e')
      .replaceAll(RegExp(r'[íìîï]'), 'i')
      .replaceAll(RegExp(r'[óòôõö]'), 'o')
      .replaceAll(RegExp(r'[úùûü]'), 'u')
      .replaceAll('ç', 'c')
      .trim();

  bool _onScroll(ScrollNotification notification) {
    if (notification.depth != 0 || notification.metrics.axis != Axis.vertical) {
      return false;
    }
    // Load in response to scrolling, never by scanning the whole catalog on open
    // or issuing a provider request for every character typed in the search box.
    final scrollingDown =
        notification is ScrollUpdateNotification &&
            (notification.scrollDelta ?? 0) > 0 ||
        notification is OverscrollNotification && notification.overscroll > 0 ||
        notification is UserScrollNotification &&
            notification.direction == ScrollDirection.reverse;
    final store = widget.store;
    if (scrollingDown &&
        notification.metrics.extentAfter < 120 &&
        store.hasMore(widget.level) &&
        !store.isLoading(widget.level) &&
        store.error(widget.level) == null) {
      store.loadMore(widget.level);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
    backgroundColor: FretColors.appSurface,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    child: SizedBox(
      width: 440,
      height: MediaQuery.sizeOf(context).height * .65,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: AnimatedBuilder(
          animation: widget.store,
          builder: (context, _) {
            final store = widget.store;
            final query = _normalize(
              _searchController.text,
            ).split(RegExp(r'\s+'));
            final options = store.options(widget.level).where((option) {
              final text = _normalize(option.label);
              return query.every(text.contains);
            }).toList();
            final loading = store.isLoading(widget.level);
            final error = store.error(widget.level);
            final hasMore = store.hasMore(widget.level);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Selecionar ${widget.label.toLowerCase()}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Fechar',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, size: 20),
                    ),
                  ],
                ),
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Digite para buscar',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Limpar busca',
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () => setState(_searchController.clear),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: _onScroll,
                    child: ListView(
                      padding: EdgeInsets.zero,
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: ClampingScrollPhysics(),
                      ),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      children: [
                        if (options.isEmpty && !loading && error == null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              hasMore
                                  ? 'Nenhuma correspondência nas opções carregadas. Role a lista para continuar a busca.'
                                  : 'Nenhuma opção encontrada.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                color: FretColors.textSecondary,
                              ),
                            ),
                          ),
                        for (final option in options)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              option.label,
                              style: const TextStyle(fontSize: 14),
                            ),
                            trailing: option.value == widget.selected
                                ? const Icon(
                                    Icons.check_rounded,
                                    color: FretColors.brandGold,
                                  )
                                : null,
                            onTap: () =>
                                Navigator.of(context).pop(option.value),
                          ),
                        if (loading)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          ),
                        if (error != null) ...[
                          const SizedBox(height: 8),
                          Text(error, style: const TextStyle(fontSize: 13)),
                          TextButton(
                            onPressed: loading
                                ? null
                                : () => store.retry(widget.level),
                            child: const Text('Tentar novamente'),
                          ),
                        ] else if (hasMore && !loading && options.isNotEmpty)
                          const Padding(
                            padding: EdgeInsets.all(12),
                            child: Text(
                              'Role para ver mais opções',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: FretColors.textSecondary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}
