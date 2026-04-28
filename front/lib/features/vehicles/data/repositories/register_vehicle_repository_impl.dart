import '../datasources/register_vehicle_datasource.dart';
import '../models/register_vehicle_model.dart';
import 'register_vehicle_repository.dart';

class RegisterVehicleRepositoryImpl implements RegisterVehicleRepository {
  final RegisterVehicleDatasource _datasource;

  const RegisterVehicleRepositoryImpl(this._datasource);

  @override
  Future<RegisterVehicleModel> registerVehicle(
    RegisterVehicleModel vehicle,
  ) async {
    try {
      return await _datasource.registerVehicle(vehicle);
    } on RegisterVehicleDatasourceException catch (e) {
      throw RegisterVehicleRepositoryException(e.message);
    }
  }
}
