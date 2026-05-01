import '../data/datasources/myself_datasource.dart';
import '../models/myself_user_model.dart';
import 'myself_repository.dart';

class MyselfRepositoryImpl implements MyselfRepository {
  final MyselfDatasource _datasource;

  const MyselfRepositoryImpl(this._datasource);

  @override
  Future<MyselfUserModel> getUserById(int userId) async {
    try {
      return await _datasource.getUserById(userId);
    } on MyselfDatasourceException catch (e) {
      throw MyselfRepositoryException(e.message);
    }
  }
}