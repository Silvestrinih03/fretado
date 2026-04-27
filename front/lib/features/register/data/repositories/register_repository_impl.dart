import '../datasources/register_datasource.dart';
import '../models/register_user_model.dart';
import 'register_repository.dart';

class RegisterRepositoryImpl implements RegisterRepository {
  final RegisterDatasource _datasource;

  const RegisterRepositoryImpl(this._datasource);

  @override
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
      return await _datasource.register(
        cpf: cpf,
        email: email,
        password: password,
        userTypeId: userTypeId,
        firstName: firstName,
        lastName: lastName,
        birthDate: birthDate,
        phone: phone,
      );
    } on RegisterDatasourceException catch (e) {
      throw RegisterRepositoryException(e.message);
    }
  }
}
