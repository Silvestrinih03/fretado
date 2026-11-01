import '../models/vehicle_catalog_option_model.dart';
import '../models/vehicle_catalog_page_model.dart';

abstract class VehicleCatalogRepository {
  Future<VehicleCatalogPageModel> listBrandsPage({int page = 1});
  Future<VehicleCatalogPageModel> listModelsPage({
    required String brandId,
    int page = 1,
  });
  Future<VehicleCatalogPageModel> listVersionsPage({
    required String brandId,
    required String modelId,
    int page = 1,
  });
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
