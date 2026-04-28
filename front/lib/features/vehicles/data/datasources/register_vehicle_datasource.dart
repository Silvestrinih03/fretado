import '../../../../core/endpoints.dart';
import '../../../../core/services/http_service.dart';
import '../models/register_vehicle_model.dart';

class RegisterVehicleDatasource {
  final HttpService _httpService;

  const RegisterVehicleDatasource(this._httpService);

  Future<RegisterVehicleModel> registerVehicle(
    RegisterVehicleModel vehicle,
  ) async {
    try {
      final Map<String, dynamic> response = await _httpService.post(
        Endpoints.vehicles,
        body: vehicle.toJson(),
      );

      return RegisterVehicleModel.fromJson(response);
    } on HttpServiceException catch (e) {
      throw RegisterVehicleDatasourceException(
        e.message,
        statusCode: e.statusCode,
      );
    }
  }
}

class RegisterVehicleDatasourceException implements Exception {
  final String message;
  final int? statusCode;

  const RegisterVehicleDatasourceException(this.message, {this.statusCode});

  @override
  String toString() =>
      'RegisterVehicleDatasourceException($statusCode): $message';
}
