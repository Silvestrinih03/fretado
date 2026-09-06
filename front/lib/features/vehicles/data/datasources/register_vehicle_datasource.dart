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

      return RegisterVehicleModel.fromJson({...vehicle.toJson(), ...response});
    } on HttpServiceException catch (e) {
      final detail = e.data?['detail'];
      final validationMessages = detail is List
          ? detail
                .whereType<Map>()
                .map((item) {
                  final location = item['loc'];
                  final field = location is List && location.isNotEmpty
                      ? location.last.toString()
                      : 'veículo';
                  return '$field: ${item['msg'] ?? 'Valor inválido.'}';
                })
                .join('\n')
          : '';
      throw RegisterVehicleDatasourceException(
        validationMessages.isEmpty ? e.message : validationMessages,
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
