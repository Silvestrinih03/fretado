import '../models/vehicle_type_model.dart';

abstract class VehicleTypeRepository {
  Future<List<VehicleTypeModel>> listVehicleTypes();
}

class VehicleTypeRepositoryException implements Exception {
  final String message;

  const VehicleTypeRepositoryException(this.message);

  @override
  String toString() => 'VehicleTypeRepositoryException: $message';
}
