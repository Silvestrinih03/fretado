import '../../../services/http_service.dart';
import '../data/datasources/myself_datasource.dart';
import '../models/myself_user_model.dart';
import '../repositories/myself_repository.dart';
import '../repositories/myself_repository_impl.dart';

class MyselfService {
  final MyselfRepository _repository;

  MyselfService({MyselfRepository? repository})
      : _repository = repository ??
            MyselfRepositoryImpl(
              MyselfDatasource(HttpService()),
            );

  Future<MyselfUserModel> getMyself(int userId) {
    return _repository.getUserById(userId);
  }
}