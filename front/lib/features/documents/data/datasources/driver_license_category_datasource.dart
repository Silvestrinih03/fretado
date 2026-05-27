import '../../../../core/endpoints.dart';
import '../../../../core/services/http_service.dart';
import '../models/driver_license_category_model.dart';

class DriverLicenseCategoryDatasource {
  final HttpService _httpService;

  const DriverLicenseCategoryDatasource(this._httpService);

  Future<List<DriverLicenseCategoryModel>> listDriverLicenseCategories() async {
    try {
      final response = await _httpService.get(
        Endpoints.driverLicenseCategories,
      );

      final data = response['data'];
      if (data is! List<dynamic>) {
        return <DriverLicenseCategoryModel>[];
      }

      return data
          .whereType<Map<String, dynamic>>()
          .map(DriverLicenseCategoryModel.fromJson)
          .toList();
    } on HttpServiceException catch (e) {
      throw DriverLicenseCategoryDatasourceException(
        e.message,
        statusCode: e.statusCode,
      );
    }
  }
}

class DriverLicenseCategoryDatasourceException implements Exception {
  final String message;
  final int? statusCode;

  const DriverLicenseCategoryDatasourceException(
    this.message, {
    this.statusCode,
  });

  @override
  String toString() {
    return 'DriverLicenseCategoryDatasourceException($statusCode): $message';
  }
}
