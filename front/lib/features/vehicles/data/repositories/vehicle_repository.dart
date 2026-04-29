import '../models/vehicle_list_item_model.dart';

abstract class VehicleRepository {
  Future<List<VehicleListItemModel>> listVehiclesByUser(int userId);
}

class VehicleRepositoryException implements Exception {
  final String message;

  const VehicleRepositoryException(this.message);

  @override
  String toString() => 'VehicleRepositoryException: $message';
}