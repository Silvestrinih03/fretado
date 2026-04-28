import '../models/myself_user_model.dart';

abstract class MyselfRepository {
  Future<MyselfUserModel> getUserById(int userId);
}

class MyselfRepositoryException implements Exception {
  final String message;

  const MyselfRepositoryException(this.message);

  @override
  String toString() => 'MyselfRepositoryException: $message';
}