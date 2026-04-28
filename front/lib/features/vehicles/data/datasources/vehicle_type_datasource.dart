import '../../../../core/endpoints.dart';
import '../../../../core/services/http_service.dart';
import '../models/vehicle_type_model.dart';

class VehicleTypeDatasource {
  final HttpService _httpService;

  const VehicleTypeDatasource(this._httpService);

  Future<List<VehicleTypeModel>> listVehicleTypes() async {
    try {
      final Map<String, dynamic> response = await _httpService.get(
        Endpoints.vehicleTypes,
      );

      final dynamic data = response['data'];
      if (data is! List<dynamic>) {
        return <VehicleTypeModel>[];
      }

      return data
          .whereType<Map<String, dynamic>>()
          .map(VehicleTypeModel.fromJson)
          .toList();
    } on HttpServiceException catch (e) {
      throw VehicleTypeDatasourceException(e.message, statusCode: e.statusCode);
    }
  }
}

class VehicleTypeDatasourceException implements Exception {
  final String message;
  final int? statusCode;

  const VehicleTypeDatasourceException(this.message, {this.statusCode});

  @override
  String toString() => 'VehicleTypeDatasourceException($statusCode): $message';
}
