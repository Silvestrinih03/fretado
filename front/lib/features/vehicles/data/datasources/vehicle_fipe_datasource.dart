import '../../../../core/endpoints.dart';
import '../../../../core/services/http_service.dart';
import '../models/vehicle_fipe_option_model.dart';

class VehicleFipeDatasource {
  final HttpService _httpService;

  const VehicleFipeDatasource(this._httpService);

  Future<List<VehicleFipeOptionModel>> listBrands({
    required int vehicleTypeId,
    String? search,
  }) async {
    try {
      final Map<String, dynamic> response = await _httpService.get(
        Endpoints.vehicleCatalogBrands(
          vehicleTypeId: vehicleTypeId,
          search: search,
        ),
      );

      return _parseOptions(response, valueKey: 'id');
    } on HttpServiceException catch (e) {
      throw VehicleFipeDatasourceException(
        e.message,
        statusCode: e.statusCode,
      );
    }
  }

  Future<List<VehicleFipeOptionModel>> listModels({
    required int vehicleTypeId,
    required String brandId,
    String? search,
  }) async {
    try {
      final Map<String, dynamic> response = await _httpService.get(
        Endpoints.vehicleCatalogModels(
          vehicleTypeId: vehicleTypeId,
          brandId: brandId,
          search: search,
        ),
      );

      return _parseOptions(response, valueKey: 'id');
    } on HttpServiceException catch (e) {
      throw VehicleFipeDatasourceException(
        e.message,
        statusCode: e.statusCode,
      );
    }
  }

  Future<List<VehicleFipeOptionModel>> listYears({
    required int vehicleTypeId,
    required String brandId,
    required String modelId,
  }) async {
    try {
      final Map<String, dynamic> response = await _httpService.get(
        Endpoints.vehicleCatalogYears(
          vehicleTypeId: vehicleTypeId,
          brandId: brandId,
          modelId: modelId,
        ),
      );

      return _parseOptions(response, valueKey: 'code');
    } on HttpServiceException catch (e) {
      throw VehicleFipeDatasourceException(
        e.message,
        statusCode: e.statusCode,
      );
    }
  }

  List<VehicleFipeOptionModel> _parseOptions(
    Map<String, dynamic> response, {
    required String valueKey,
  }) {
    final dynamic data = response['data'];
    if (data is! List<dynamic>) {
      return <VehicleFipeOptionModel>[];
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(
          (Map<String, dynamic> item) => VehicleFipeOptionModel.fromJson(
            item,
            valueKey: valueKey,
          ),
        )
        .where((VehicleFipeOptionModel item) =>
            item.value.isNotEmpty && item.label.isNotEmpty)
        .toList();
  }

  String? _asString(dynamic value) {
    if (value == null) {
      return null;
    }

    final String text = value.toString().trim();
    if (text.isEmpty) {
      return null;
    }

    return text;
  }
}

class VehicleFipeDatasourceException implements Exception {
  final String message;
  final int? statusCode;

  const VehicleFipeDatasourceException(this.message, {this.statusCode});

  @override
  String toString() => 'VehicleFipeDatasourceException($statusCode): $message';
}