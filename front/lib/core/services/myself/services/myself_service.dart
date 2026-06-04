import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/http_service.dart';
import '../data/datasources/myself_datasource.dart';
import '../models/myself_user_model.dart';
import '../repositories/myself_repository.dart';
import '../repositories/myself_repository_impl.dart';

class MyselfService {
  static const String _sessionUserIdKey = 'fretado_session_user_id';
  static const String _sessionUserTypeIdKey = 'fretado_session_user_type_id';

  static MyselfService? _instance;

  final MyselfRepository _repository;
  int? _currentUserId;
  int? _currentUserTypeId;
  bool _hasLoadedSavedSession = false;

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

  Future<void> loadSavedSession() async {
    if (_hasLoadedSavedSession) {
      return;
    }

    final SharedPreferences preferences = await SharedPreferences.getInstance();
    _currentUserId = preferences.getInt(_sessionUserIdKey);
    _currentUserTypeId = preferences.getInt(_sessionUserTypeIdKey);
    _hasLoadedSavedSession = true;
  }

  Future<void> saveSession({
    required int userId,
    required int userTypeId,
  }) async {
    _currentUserId = userId;
    _currentUserTypeId = userTypeId;
    _hasLoadedSavedSession = true;

    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_sessionUserIdKey, userId);
    await preferences.setInt(_sessionUserTypeIdKey, userTypeId);
  }

  Future<void> logout() async {
    _currentUserId = null;
    _currentUserTypeId = null;
    _hasLoadedSavedSession = true;

    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.remove(_sessionUserIdKey);
    await preferences.remove(_sessionUserTypeIdKey);
  }

  Future<MyselfUserModel> getMyself(int userId) {
    return _repository.getUserById(userId);
  }
}
