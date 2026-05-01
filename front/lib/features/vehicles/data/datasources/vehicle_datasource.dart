import '../../../../core/endpoints.dart';
import '../../../../core/services/http_service.dart';
import '../models/vehicle_list_item_model.dart';

class VehicleDatasource {
  final HttpService _httpService;

  const VehicleDatasource(this._httpService);

  Future<List<VehicleListItemModel>> listVehiclesByUser(int userId) async {
    try {
      final Map<String, dynamic> response = await _httpService.get(
        Endpoints.vehiclesByUser(userId),
      );

      final dynamic data = response['data'];
      if (data is! List<dynamic>) {
        return <VehicleListItemModel>[];
      }

      return data
          .whereType<Map<String, dynamic>>()
          .map(VehicleListItemModel.fromJson)
          .toList();
    } on HttpServiceException catch (e) {
      throw VehicleDatasourceException(e.message, statusCode: e.statusCode);
    }
  }
}

class VehicleDatasourceException implements Exception {
  final String message;
  final int? statusCode;

  const VehicleDatasourceException(this.message, {this.statusCode});

  @override
  String toString() => 'VehicleDatasourceException($statusCode): $message';
}