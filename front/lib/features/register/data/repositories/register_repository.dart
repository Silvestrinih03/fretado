import '../models/register_user_model.dart';

abstract class RegisterRepository {
  Future<RegisterUserModel> register({
    required String cpf,
    required String email,
    required String password,
    required int userTypeId,
    required String firstName,
    required String lastName,
    String? birthDate,
    String? phone,
  });
}

class RegisterRepositoryException implements Exception {
  final String message;

  const RegisterRepositoryException(this.message);

  @override
  String toString() => 'RegisterRepositoryException: $message';
}
