import 'vehicle_catalog_option_model.dart';

class VehicleCatalogPageModel {
  final List<VehicleCatalogOptionModel> items;
  final int page;
  final bool hasMore;

  const VehicleCatalogPageModel({
    required this.items,
    required this.page,
    required this.hasMore,
  });

  factory VehicleCatalogPageModel.fromJson(Map<String, dynamic> json) {
    final items = json['items'];
    final page = json['page'];
    if (items is! List ||
        page is! int ||
        page < 1 ||
        json['has_more'] is! bool) {
      throw const FormatException('Resposta inválida do catálogo.');
    }
    return VehicleCatalogPageModel(
      items: List.unmodifiable(
        items.map(
          (item) => VehicleCatalogOptionModel.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        ),
      ),
      page: page,
      hasMore: json['has_more'] as bool,
    );
  }
}
