import '../../../core/endpoints.dart';
import '../../../core/services/http_service.dart';
import 'models/ride_chat_models.dart';

class RideChatRepository {
  final HttpService _http;

  RideChatRepository(this._http);

  Future<List<RideConversationModel>> conversations(int rideId) async {
    final response = await _http.get(Endpoints.rideConversations(rideId));
    final data = response['data'] as List<dynamic>? ?? const [];
    return data
        .whereType<Map>()
        .map((item) => RideConversationModel.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList();
  }

  Future<RideChatMessagePage> messages(
    int conversationId, {
    int? beforeId,
    int? afterId,
  }) async {
    final response = await _http.get(
      Endpoints.rideConversationMessages(
        conversationId,
        beforeId: beforeId,
        afterId: afterId,
      ),
    );
    return RideChatMessagePage.fromJson(response);
  }

  Future<RideChatMessageModel> send(
    int conversationId, {
    required String content,
    required String clientMessageId,
  }) async {
    final response = await _http.post(
      Endpoints.sendRideConversationMessage(conversationId),
      body: {
        'content': content,
        'client_message_id': clientMessageId,
      },
    );
    return RideChatMessageModel.fromJson(response);
  }

  Future<void> markRead(int conversationId, int throughMessageId) async {
    await _http.post(
      Endpoints.readRideConversationMessages(conversationId),
      body: {'through_message_id': throughMessageId},
    );
  }
}
