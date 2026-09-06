import '../datasources/vehicle_catalog_datasource.dart';
import '../models/vehicle_catalog_option_model.dart';
import 'vehicle_catalog_repository.dart';

class VehicleCatalogRepositoryImpl implements VehicleCatalogRepository {
  final VehicleCatalogDatasource _datasource;
  const VehicleCatalogRepositoryImpl(this._datasource);

  @override
  Future<List<VehicleCatalogOptionModel>> listBrands() =>
      _fetch(() => _datasource.listBrands());

  @override
  Future<List<VehicleCatalogOptionModel>> listModels({required String brandId}) =>
      _fetch(() => _datasource.listModels(brandId: brandId));

  @override
  Future<List<VehicleCatalogOptionModel>> listVersions({
    required String brandId,
    required String modelId,
  }) => _fetch(() => _datasource.listVersions(brandId: brandId, modelId: modelId));

  Future<List<VehicleCatalogOptionModel>> _fetch(
    Future<List<VehicleCatalogOptionModel>> Function() request,
  ) async {
    try {
      return await request();
    } on VehicleCatalogDatasourceException catch (e) {
      throw VehicleCatalogRepositoryException(e.message);
    }
  }
}
