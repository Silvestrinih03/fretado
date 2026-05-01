import '../../../../core/endpoints.dart';
import '../../../../core/services/http_service.dart';
import '../../../../core/services/myself/models/myself_user_model.dart';
import '../models/change_password_model.dart';
import '../models/update_user_model.dart';

class ProfileDatasource {
  final HttpService _httpService;

  const ProfileDatasource(this._httpService);

  Future<void> changePassword({
    required int userId,
    required ChangePasswordModel payload,
  }) async {
    try {
      await _httpService.patch(
        Endpoints.changePassword(userId),
        body: payload.toJson(),
      );
    } on HttpServiceException catch (e) {
      throw ProfileDatasourceException(e.message, statusCode: e.statusCode);
    }
  }

  Future<MyselfUserModel> updateUser({
    required int userId,
    required UpdateUserModel payload,
  }) async {
    try {
      final Map<String, dynamic> response = await _httpService.patch(
        Endpoints.userById(userId),
        body: payload.toJson(),
      );

      return MyselfUserModel.fromJson(response);
    } on HttpServiceException catch (e) {
      throw ProfileDatasourceException(e.message, statusCode: e.statusCode);
    }
  }
}

class ProfileDatasourceException implements Exception {
  final String message;
  final int? statusCode;

  const ProfileDatasourceException(this.message, {this.statusCode});

  @override
  String toString() => 'ProfileDatasourceException($statusCode): $message';
}
