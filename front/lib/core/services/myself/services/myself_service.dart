import 'package:flutter/foundation.dart';

import '../../../services/http_service.dart';
import '../../../services/session/session_storage.dart';
import '../../../services/push_notifications/push_notification_service.dart';
import '../data/datasources/myself_datasource.dart';
import '../models/myself_user_model.dart';
import '../repositories/myself_repository.dart';
import '../repositories/myself_repository_impl.dart';

class MyselfService {
  static MyselfService? _instance;

  final MyselfRepository _repository;
  final SessionStorage _sessionStorage = SessionStorage.instance;
  final ValueNotifier<MyselfUserModel?> _currentProfile = ValueNotifier(null);
  int? _observedUserId;
  int _profileVersion = 0;

  ValueListenable<MyselfUserModel?> get currentProfile => _currentProfile;

  factory MyselfService({MyselfRepository? repository}) {
    return _instance ??= MyselfService._internal(
      repository ?? MyselfRepositoryImpl(MyselfDatasource(HttpService())),
    );
  }

  MyselfService._internal(this._repository) {
    _observedUserId = currentUserId;
    _sessionStorage.addListener(_onSessionChanged);
  }

  void _onSessionChanged() {
    if (_observedUserId != currentUserId) {
      _profileVersion++;
      _observedUserId = currentUserId;
      _currentProfile.value = null;
    }
  }

  void updateCachedProfile(int userId, MyselfUserModel user) {
    if (currentUserId != userId) return;
    _profileVersion++;
    _currentProfile.value = user;
  }

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
    try {
      await PushNotificationService.instance.unregisterForLogout();
    } finally {
      await _sessionStorage.clearSession();
    }
  }

  Future<MyselfUserModel> getMyself(int userId) async {
    final version = _profileVersion;
    final user = await _repository.getUserById(userId);
    // A read that started before an upload must not restore the previous photo.
    if (currentUserId == userId && version == _profileVersion) {
      _currentProfile.value = user;
    }
    return user;
  }
}
