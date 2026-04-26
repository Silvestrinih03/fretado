import '../models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel> login({required String email, required String password});
}

class AuthRepositoryException implements Exception {
  final String message;

  const AuthRepositoryException(this.message);

  @override
  String toString() => 'AuthRepositoryException: $message';
}
