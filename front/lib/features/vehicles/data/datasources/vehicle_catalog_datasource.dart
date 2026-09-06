import '../../../../core/endpoints.dart';
import '../../../../core/services/http_service.dart';
import '../models/vehicle_catalog_option_model.dart';

class VehicleCatalogDatasource {
  final HttpService _httpService;
  const VehicleCatalogDatasource(this._httpService);

  Future<List<VehicleCatalogOptionModel>> listBrands() =>
      _list(Endpoints.vehicleCatalogBrands());

  Future<List<VehicleCatalogOptionModel>> listModels({
    required String brandId,
  }) => _list(Endpoints.vehicleCatalogModels(brandId: brandId));

  Future<List<VehicleCatalogOptionModel>> listVersions({
    required String brandId,
    required String modelId,
  }) => _list(
    Endpoints.vehicleCatalogVersions(brandId: brandId, modelId: modelId),
  );

  Future<List<VehicleCatalogOptionModel>> _list(String endpoint) async {
    try {
      final response = await _httpService.get(endpoint);
      final data = response['data'];
      if (data is! List) {
        throw const FormatException('Resposta inválida do catálogo.');
      }
      return data
          .map(
            (item) => VehicleCatalogOptionModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } on HttpServiceException catch (e) {
      throw VehicleCatalogDatasourceException(e.message);
    }
  }
}

class VehicleCatalogDatasourceException implements Exception {
  final String message;
  const VehicleCatalogDatasourceException(this.message);
}
