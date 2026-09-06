import '../models/vehicle_catalog_option_model.dart';

abstract class VehicleCatalogRepository {
  Future<List<VehicleCatalogOptionModel>> listBrands();
  Future<List<VehicleCatalogOptionModel>> listModels({required String brandId});
  Future<List<VehicleCatalogOptionModel>> listVersions({
    required String brandId,
    required String modelId,
  });
}

class VehicleCatalogRepositoryException implements Exception {
  final String message;
  const VehicleCatalogRepositoryException(this.message);
}
