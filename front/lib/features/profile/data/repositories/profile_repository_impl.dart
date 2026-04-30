import '../../../../core/services/myself/models/myself_user_model.dart';
import '../datasources/profile_datasource.dart';
import '../models/change_password_model.dart';
import '../models/update_user_model.dart';
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

  @override
  Future<MyselfUserModel> updateUser({
    required int userId,
    required UpdateUserModel payload,
  }) async {
    try {
      return await _datasource.updateUser(userId: userId, payload: payload);
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
