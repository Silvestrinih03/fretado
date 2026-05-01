import '../../../../core/endpoints.dart';
import '../../../../core/services/http_service.dart';
import '../models/user_model.dart';

class AuthDatasource {
  final HttpService _httpService;

  const AuthDatasource(this._httpService);

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final Map<String, dynamic> response = await _httpService.post(
        Endpoints.auth,
        body: {'email': email.trim(), 'password': password},
      );

      final dynamic userData = response['user'];
      if (userData is! Map<String, dynamic>) {
        throw const AuthDatasourceException('Resposta inválida da API.');
      }

      return UserModel.fromJson(userData);
    } on HttpServiceException catch (e) {
      throw AuthDatasourceException(e.message, statusCode: e.statusCode);
    }
  }
}

class AuthDatasourceException implements Exception {
  final String message;
  final int? statusCode;

  const AuthDatasourceException(this.message, {this.statusCode});

  @override
  String toString() => 'AuthDatasourceException($statusCode): $message';
}
