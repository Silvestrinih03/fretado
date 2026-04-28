import '../models/register_vehicle_model.dart';

abstract class RegisterVehicleRepository {
  Future<RegisterVehicleModel> registerVehicle(RegisterVehicleModel vehicle);
}

class RegisterVehicleRepositoryException implements Exception {
  final String message;

  const RegisterVehicleRepositoryException(this.message);

  @override
  String toString() => 'RegisterVehicleRepositoryException: $message';
}
