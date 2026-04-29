import '../datasources/profile_datasource.dart';
import '../models/change_password_model.dart';
import 'profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileDatasource _datasource;

  const ProfileRepositoryImpl(this._datasource);

  @override
  Future<void> changePassword({
    required int userId,
    required ChangePasswordModel payload,
  }) async {
    try {
      await _datasource.changePassword(userId: userId, payload: payload);
    } on ProfileDatasourceException catch (e) {
      throw ProfileRepositoryException(e.message);
    }
  }
}

class ProfileRepositoryException implements Exception {
  final String message;

  const ProfileRepositoryException(this.message);

  @override
  String toString() => 'ProfileRepositoryException: $message';
}
