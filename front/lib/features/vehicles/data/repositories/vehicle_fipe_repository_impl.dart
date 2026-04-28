import '../datasources/vehicle_fipe_datasource.dart';
import '../models/vehicle_fipe_option_model.dart';
import 'vehicle_fipe_repository.dart';

class VehicleFipeRepositoryImpl implements VehicleFipeRepository {
  final VehicleFipeDatasource _datasource;

  const VehicleFipeRepositoryImpl(this._datasource);

  @override
  Future<List<VehicleFipeOptionModel>> listBrands({
    required int vehicleTypeId,
    String? search,
  }) async {
    try {
      return await _datasource.listBrands(
        vehicleTypeId: vehicleTypeId,
        search: search,
      );
    } on VehicleFipeDatasourceException catch (e) {
      throw VehicleFipeRepositoryException(e.message);
    }
  }

  @override
  Future<List<VehicleFipeOptionModel>> listModels({
    required int vehicleTypeId,
    required String brandId,
    String? search,
  }) async {
    try {
      return await _datasource.listModels(
        vehicleTypeId: vehicleTypeId,
        brandId: brandId,
        search: search,
      );
    } on VehicleFipeDatasourceException catch (e) {
      throw VehicleFipeRepositoryException(e.message);
    }
  }

  @override
  Future<List<VehicleFipeOptionModel>> listYears({
    required int vehicleTypeId,
    required String brandId,
    required String modelId,
  }) async {
    try {
      return await _datasource.listYears(
        vehicleTypeId: vehicleTypeId,
        brandId: brandId,
        modelId: modelId,
      );
    } on VehicleFipeDatasourceException catch (e) {
      throw VehicleFipeRepositoryException(e.message);
    }
  }
}