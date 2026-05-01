import '../models/vehicle_fipe_option_model.dart';

abstract class VehicleFipeRepository {
  Future<List<VehicleFipeOptionModel>> listBrands({
    required int vehicleTypeId,
    String? search,
  });

  Future<List<VehicleFipeOptionModel>> listModels({
    required int vehicleTypeId,
    required String brandId,
    String? search,
  });

  Future<List<VehicleFipeOptionModel>> listYears({
    required int vehicleTypeId,
    required String brandId,
    required String modelId,
  });
}

class VehicleFipeRepositoryException implements Exception {
  final String message;

  const VehicleFipeRepositoryException(this.message);

  @override
  String toString() => 'VehicleFipeRepositoryException: $message';
}