import '../../../../core/endpoints.dart';
import '../../../../core/services/http_service.dart';
import '../models/vehicle_catalog_option_model.dart';
import '../models/vehicle_catalog_page_model.dart';

class VehicleCatalogDatasource {
  final HttpService _httpService;
  const VehicleCatalogDatasource(this._httpService);

  Future<VehicleCatalogPageModel> listBrandsPage({int page = 1}) =>
      _page(Endpoints.vehicleCatalogBrandsPage(page: page));

  Future<VehicleCatalogPageModel> listModelsPage({
    required String brandId,
    int page = 1,
  }) => _page(Endpoints.vehicleCatalogModelsPage(brandId: brandId, page: page));

  Future<VehicleCatalogPageModel> listVersionsPage({
    required String brandId,
    required String modelId,
    int page = 1,
  }) => _page(
    Endpoints.vehicleCatalogVersionsPage(
      brandId: brandId,
      modelId: modelId,
      page: page,
    ),
  );

  Future<VehicleCatalogPageModel> _page(String endpoint) async {
    try {
      return VehicleCatalogPageModel.fromJson(await _httpService.get(endpoint));
    } on HttpServiceException catch (e) {
      throw VehicleCatalogDatasourceException(e.message);
    } on FormatException {
      throw const VehicleCatalogDatasourceException(
        'Não foi possível carregar os dados do catálogo.',
      );
    }
  }

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
