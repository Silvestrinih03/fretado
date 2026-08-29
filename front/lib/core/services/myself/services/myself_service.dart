import '../../../services/http_service.dart';
import '../../../services/session/session_storage.dart';
import '../data/datasources/myself_datasource.dart';
import '../models/myself_user_model.dart';
import '../repositories/myself_repository.dart';
import '../repositories/myself_repository_impl.dart';

class MyselfService {
  static MyselfService? _instance;

  final MyselfRepository _repository;
  final SessionStorage _sessionStorage = SessionStorage.instance;

  factory MyselfService({MyselfRepository? repository}) {
    return _instance ??= MyselfService._internal(
      repository ??
          MyselfRepositoryImpl(
            MyselfDatasource(HttpService()),
          ),
    );
  }

  MyselfService._internal(this._repository);

  int? get currentUserId => _sessionStorage.currentUserId;
  int? get currentUserTypeId => _sessionStorage.currentUserTypeId;
  String? get currentAccessToken => _sessionStorage.currentAccessToken;
  bool get hasValidAccessToken => _sessionStorage.hasValidAccessToken;

  set currentUserId(int? value) {
    _sessionStorage.currentUserId = value;
  }

  set currentUserTypeId(int? value) {
    _sessionStorage.currentUserTypeId = value;
  }

  bool get hasCurrentUserId => _sessionStorage.hasCurrentUserId;

  Future<void> loadSavedSession() async {
    await _sessionStorage.loadSavedSession();
  }

  Future<void> saveSession({
    required int userId,
    required int userTypeId,
    String? accessToken,
  }) async {
    await _sessionStorage.saveSession(
      userId: userId,
      userTypeId: userTypeId,
      accessToken: accessToken,
    );
  }

  Future<void> logout() async {
    await _sessionStorage.clearSession();
  }

  Future<MyselfUserModel> getMyself(int userId) {
    return _repository.getUserById(userId);
  }
}
