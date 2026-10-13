import '../../endpoints.dart';
import '../http_service.dart';

class PushTokenRepository {
  final HttpService _http;

  PushTokenRepository(this._http);

  Future<void> register(String token) async {
    await _http.post(Endpoints.fcmTokens, body: {'token': token});
  }

  Future<void> update({String? oldToken, required String newToken}) async {
    await _http.put(
      Endpoints.fcmTokens,
      body: {'old_token': oldToken, 'new_token': newToken},
    );
  }

  Future<void> remove(String token) async {
    await _http.delete(Endpoints.fcmTokens, body: {'token': token});
  }

  void dispose() => _http.dispose();
}
