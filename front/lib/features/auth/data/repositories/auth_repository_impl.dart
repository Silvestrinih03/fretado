import '../datasources/auth_datasource.dart';
import '../models/user_model.dart';
import 'auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthDatasource _datasource;

  const AuthRepositoryImpl(this._datasource);

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      return await _datasource.login(email: email, password: password);
    } on AuthDatasourceException catch (e) {
      throw AuthRepositoryException(e.message);
    }
  }

  @override
  Future<String> forgotPassword({required String email}) async {
    try {
      return await _datasource.forgotPassword(email: email);
    } on AuthDatasourceException catch (e) {
      throw AuthRepositoryException(e.message);
    }
  }

  @override
  Future<String> resetPassword({
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      return await _datasource.resetPassword(
        token: token,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
    } on AuthDatasourceException catch (e) {
      throw AuthRepositoryException(e.message);
    }
  }
}
