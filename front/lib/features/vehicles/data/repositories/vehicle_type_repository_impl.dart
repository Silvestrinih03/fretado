import '../datasources/vehicle_type_datasource.dart';
import '../models/vehicle_type_model.dart';
import 'vehicle_type_repository.dart';

class VehicleTypeRepositoryImpl implements VehicleTypeRepository {
  final VehicleTypeDatasource _datasource;

  const VehicleTypeRepositoryImpl(this._datasource);

  @override
  Future<List<VehicleTypeModel>> listVehicleTypes() async {
    try {
      return await _datasource.listVehicleTypes();
    } on VehicleTypeDatasourceException catch (e) {
      throw VehicleTypeRepositoryException(e.message);
    }
  }
}
