import '../datasources/vehicle_catalog_datasource.dart';
import '../models/vehicle_catalog_option_model.dart';
import '../models/vehicle_catalog_page_model.dart';
import 'vehicle_catalog_repository.dart';

class VehicleCatalogRepositoryImpl implements VehicleCatalogRepository {
  final VehicleCatalogDatasource _datasource;
  const VehicleCatalogRepositoryImpl(this._datasource);

  @override
  Future<VehicleCatalogPageModel> listBrandsPage({int page = 1}) =>
      _fetch(() => _datasource.listBrandsPage(page: page));

  @override
  Future<VehicleCatalogPageModel> listModelsPage({
    required String brandId,
    int page = 1,
  }) => _fetch(() => _datasource.listModelsPage(brandId: brandId, page: page));

  @override
  Future<VehicleCatalogPageModel> listVersionsPage({
    required String brandId,
    required String modelId,
    int page = 1,
  }) => _fetch(
    () => _datasource.listVersionsPage(
      brandId: brandId,
      modelId: modelId,
      page: page,
    ),
  );

  @override
  Future<List<VehicleCatalogOptionModel>> listBrands() =>
      _fetch(() => _datasource.listBrands());

  @override
  Future<List<VehicleCatalogOptionModel>> listModels({
    required String brandId,
  }) => _fetch(() => _datasource.listModels(brandId: brandId));

  @override
  Future<List<VehicleCatalogOptionModel>> listVersions({
    required String brandId,
    required String modelId,
  }) => _fetch(
    () => _datasource.listVersions(brandId: brandId, modelId: modelId),
  );

  Future<T> _fetch<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on VehicleCatalogDatasourceException catch (e) {
      throw VehicleCatalogRepositoryException(e.message);
    }
  }
}
