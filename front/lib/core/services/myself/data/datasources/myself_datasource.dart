import '../../../../../core/endpoints.dart';
import '../../../../../core/services/http_service.dart';
import '../../models/myself_user_model.dart';

class MyselfDatasource {
  final HttpService _httpService;

  const MyselfDatasource(this._httpService);

  Future<MyselfUserModel> getUserById(int userId) async {
    try {
      final Map<String, dynamic> response = await _httpService.get(
        Endpoints.userById(userId),
      );

      return MyselfUserModel.fromJson(response);
    } on HttpServiceException catch (e) {
      throw MyselfDatasourceException(e.message, statusCode: e.statusCode);
    }
  }
}

class MyselfDatasourceException implements Exception {
  final String message;
  final int? statusCode;

  const MyselfDatasourceException(this.message, {this.statusCode});

  @override
  String toString() => 'MyselfDatasourceException($statusCode): $message';
}