import '../models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel> login({required String email, required String password});

  Future<String> forgotPassword({required String email});

  Future<String> resetPassword({
    required String token,
    required String newPassword,
    required String confirmPassword,
  });
}

class AuthRepositoryException implements Exception {
  final String message;

  const AuthRepositoryException(this.message);

  @override
  String toString() => 'AuthRepositoryException: $message';
}
