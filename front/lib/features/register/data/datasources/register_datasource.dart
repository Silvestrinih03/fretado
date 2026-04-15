import '../../../../core/services/http_service.dart';
import '../models/register_user_model.dart';

class RegisterDatasource {
  final HttpService _httpService;

  const RegisterDatasource(this._httpService);

  Future<RegisterUserModel> register({
    required String cpf,
    required String email,
    required String password,
    required int userTypeId,
    required String firstName,
    required String lastName,
    String? birthDate,
    String? phone,
  }) async {
    try {
      final Map<String, dynamic> response = await _httpService.post(
        '/register',
        body: {
          'cpf': cpf,
          'email': email.trim(),
          'password': password,
          'user_type_id': userTypeId,
          'first_name': firstName.trim(),
          'last_name': lastName.trim(),
          'birth_date': birthDate,
          'phone': phone,
        },
      );

      return RegisterUserModel.fromJson(response);
    } on HttpServiceException catch (e) {
      throw RegisterDatasourceException(e.message, statusCode: e.statusCode);
    }
  }
}

class RegisterDatasourceException implements Exception {
  final String message;
  final int? statusCode;

  const RegisterDatasourceException(this.message, {this.statusCode});

  @override
  String toString() => 'RegisterDatasourceException($statusCode): $message';
}
