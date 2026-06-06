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

  Future<String> forgotPassword({required String email}) async {
    try {
      final Map<String, dynamic> response = await _httpService.post(
        Endpoints.forgotPassword,
        body: {'email': email.trim()},
      );

      return _readMessage(response);
    } on HttpServiceException catch (e) {
      throw AuthDatasourceException(e.message, statusCode: e.statusCode);
    }
  }

  Future<String> resetPassword({
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final Map<String, dynamic> response = await _httpService.post(
        Endpoints.resetPassword,
        body: {
          'token': token,
          'new_password': newPassword,
          'confirm_password': confirmPassword,
        },
      );

      return _readMessage(response);
    } on HttpServiceException catch (e) {
      throw AuthDatasourceException(e.message, statusCode: e.statusCode);
    }
  }

  String _readMessage(Map<String, dynamic> response) {
    final dynamic message = response['message'];
    if (message is String && message.isNotEmpty) {
      return message;
    }

    return 'Operacao realizada com sucesso.';
  }
}

class AuthDatasourceException implements Exception {
  final String message;
  final int? statusCode;

  const AuthDatasourceException(this.message, {this.statusCode});

  @override
  String toString() => 'AuthDatasourceException($statusCode): $message';
}
