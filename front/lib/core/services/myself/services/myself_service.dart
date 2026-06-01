import '../../../services/http_service.dart';
import '../data/datasources/myself_datasource.dart';
import '../models/myself_user_model.dart';
import '../repositories/myself_repository.dart';
import '../repositories/myself_repository_impl.dart';

class MyselfService {
  static MyselfService? _instance;

  final MyselfRepository _repository;
  int? _currentUserId;
  int? _currentUserTypeId;

  factory MyselfService({MyselfRepository? repository}) {
    return _instance ??= MyselfService._internal(
      repository ??
          MyselfRepositoryImpl(
            MyselfDatasource(HttpService()),
          ),
    );
  }

  MyselfService._internal(this._repository);

  int? get currentUserId => _currentUserId;
  int? get currentUserTypeId => _currentUserTypeId;

  set currentUserId(int? value) {
    _currentUserId = value;
  }

  set currentUserTypeId(int? value) {
    _currentUserTypeId = value;
  }

  bool get hasCurrentUserId => _currentUserId != null;

  void logout() {
    _currentUserId = null;
    _currentUserTypeId = null;
  }

  Future<MyselfUserModel> getMyself(int userId) {
    return _repository.getUserById(userId);
  }
}
