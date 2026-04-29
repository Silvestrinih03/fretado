import '../datasources/vehicle_datasource.dart';
import '../models/vehicle_list_item_model.dart';
import 'vehicle_repository.dart';

class VehicleRepositoryImpl implements VehicleRepository {
  final VehicleDatasource _datasource;

  const VehicleRepositoryImpl(this._datasource);

  @override
  Future<List<VehicleListItemModel>> listVehiclesByUser(int userId) async {
    try {
      return await _datasource.listVehiclesByUser(userId);
    } on VehicleDatasourceException catch (e) {
      throw VehicleRepositoryException(e.message);
    }
  }
}