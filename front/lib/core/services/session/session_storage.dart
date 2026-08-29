import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SessionStorage {
  static const String sessionUserIdKey = 'fretado_session_user_id';
  static const String sessionUserTypeIdKey = 'fretado_session_user_type_id';
  static const String sessionAccessTokenKey = 'fretado_session_access_token';

  static final SessionStorage instance = SessionStorage._();

  int? _currentUserId;
  int? _currentUserTypeId;
  String? _currentAccessToken;
  bool _hasLoadedSavedSession = false;

  SessionStorage._();

  int? get currentUserId => _currentUserId;
  int? get currentUserTypeId => _currentUserTypeId;
  String? get currentAccessToken => _currentAccessToken;
  bool get hasCurrentUserId => _currentUserId != null;

  set currentUserId(int? value) {
    _currentUserId = value;
  }

  set currentUserTypeId(int? value) {
    _currentUserTypeId = value;
  }

  Future<void> loadSavedSession() async {
    if (_hasLoadedSavedSession) {
      return;
    }

    final SharedPreferences preferences = await SharedPreferences.getInstance();
    _currentUserId = preferences.getInt(sessionUserIdKey);
    _currentUserTypeId = preferences.getInt(sessionUserTypeIdKey);
    _currentAccessToken = preferences.getString(sessionAccessTokenKey);
    _hasLoadedSavedSession = true;
  }

  Future<void> saveSession({
    required int userId,
    required int userTypeId,
    String? accessToken,
  }) async {
    _currentUserId = userId;
    _currentUserTypeId = userTypeId;
    _currentAccessToken = accessToken;
    _hasLoadedSavedSession = true;

    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setInt(sessionUserIdKey, userId);
    await preferences.setInt(sessionUserTypeIdKey, userTypeId);
    if (accessToken != null && accessToken.isNotEmpty) {
      await preferences.setString(sessionAccessTokenKey, accessToken);
    } else {
      await preferences.remove(sessionAccessTokenKey);
    }
  }

  Future<void> clearSession() async {
    _currentUserId = null;
    _currentUserTypeId = null;
    _currentAccessToken = null;
    _hasLoadedSavedSession = true;

    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.remove(sessionUserIdKey);
    await preferences.remove(sessionUserTypeIdKey);
    await preferences.remove(sessionAccessTokenKey);
  }

  bool get hasValidAccessToken {
    final token = _currentAccessToken;
    return token != null && token.isNotEmpty && !_isJwtExpired(token);
  }

  bool _isJwtExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        return true;
      }

      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      if (payload is! Map<String, dynamic>) {
        return true;
      }

      final exp = payload['exp'];
      final int? expiresAt = exp is int ? exp : int.tryParse('$exp');
      if (expiresAt == null) {
        return true;
      }

      final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return expiresAt <= now;
    } catch (_) {
      return true;
    }
  }
}
