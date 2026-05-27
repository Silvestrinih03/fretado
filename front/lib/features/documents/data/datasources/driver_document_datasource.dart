import '../../../../core/endpoints.dart';
import '../../../../core/services/http_service.dart';
import '../models/driver_document_model.dart';

class DriverDocumentDatasource {
  final HttpService _httpService;

  const DriverDocumentDatasource(this._httpService);

  Future<DriverDocumentModel?> getDriverDocumentByUser(int userId) async {
    try {
      final response = await _httpService.get(
        Endpoints.driverDocumentByUserId(userId),
      );

      return DriverDocumentModel.fromJson(response);
    } on HttpServiceException catch (e) {
      if (e.statusCode == 404) {
        return null;
      }

      throw DriverDocumentDatasourceException(
        e.message,
        statusCode: e.statusCode,
      );
    }
  }

  Future<DriverDocumentModel> createDriverDocument({
    required int userId,
    required DriverDocumentModel document,
  }) async {
    try {
      final response = await _httpService.post(
        Endpoints.createDriverDocumentForUser(userId),
        body: document.toJson(),
      );

      return DriverDocumentModel.fromJson(response);
    } on HttpServiceException catch (e) {
      throw DriverDocumentDatasourceException(
        e.message,
        statusCode: e.statusCode,
      );
    }
  }

  Future<DriverDocumentModel> updateDriverDocument({
    required int documentId,
    required DriverDocumentModel document,
  }) async {
    try {
      final response = await _httpService.put(
        Endpoints.updateDriverDocument(documentId),
        body: document.toJson(),
      );

      return DriverDocumentModel.fromJson(response);
    } on HttpServiceException catch (e) {
      throw DriverDocumentDatasourceException(
        e.message,
        statusCode: e.statusCode,
      );
    }
  }
}

class DriverDocumentDatasourceException implements Exception {
  final String message;
  final int? statusCode;

  const DriverDocumentDatasourceException(this.message, {this.statusCode});

  @override
  String toString() {
    return 'DriverDocumentDatasourceException($statusCode): $message';
  }
}
