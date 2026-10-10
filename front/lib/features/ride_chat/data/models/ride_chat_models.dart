class RideChatParticipant {
  final int id;
  final String fullName;
  final String role;

  const RideChatParticipant({
    required this.id,
    required this.fullName,
    required this.role,
  });

  factory RideChatParticipant.fromJson(Map<String, dynamic> json) =>
      RideChatParticipant(
        id: _int(json['id']),
        fullName: '${json['full_name'] ?? 'Usuário'}',
        role: '${json['role'] ?? ''}',
      );
}

class RideConversationModel {
  final int id;
  final int rideId;
  final int rideOfferId;
  final RideChatParticipant otherParticipant;
  final bool isCurrent;
  final bool canSend;
  final int unreadCount;
  final DateTime? closedAt;
  final DateTime createdAt;

  const RideConversationModel({
    required this.id,
    required this.rideId,
    required this.rideOfferId,
    required this.otherParticipant,
    required this.isCurrent,
    required this.canSend,
    required this.unreadCount,
    required this.closedAt,
    required this.createdAt,
  });

  factory RideConversationModel.fromJson(Map<String, dynamic> json) =>
      RideConversationModel(
        id: _int(json['id']),
        rideId: _int(json['ride_id']),
        rideOfferId: _int(json['ride_offer_id']),
        otherParticipant: RideChatParticipant.fromJson(
          Map<String, dynamic>.from(json['other_participant'] as Map),
        ),
        isCurrent: json['is_current'] == true,
        canSend: json['can_send'] == true,
        unreadCount: _int(json['unread_count']),
        closedAt: _date(json['closed_at']),
        createdAt: _date(json['created_at']) ?? DateTime.now(),
      );
}

class RideChatMessageModel {
  final int id;
  final int conversationId;
  final int senderUserId;
  final String clientMessageId;
  final String content;
  final DateTime sentAt;
  final DateTime? readAt;

  const RideChatMessageModel({
    required this.id,
    required this.conversationId,
    required this.senderUserId,
    required this.clientMessageId,
    required this.content,
    required this.sentAt,
    required this.readAt,
  });

  factory RideChatMessageModel.fromJson(Map<String, dynamic> json) =>
      RideChatMessageModel(
        id: _int(json['id']),
        conversationId: _int(json['conversation_id']),
        senderUserId: _int(json['sender_user_id']),
        clientMessageId: '${json['client_message_id'] ?? ''}',
        content: '${json['content'] ?? ''}',
        sentAt: _date(json['sent_at']) ?? DateTime.now(),
        readAt: _date(json['read_at']),
      );
}

class RideChatMessagePage {
  final List<RideChatMessageModel> items;
  final bool hasMore;
  final int? nextBeforeId;

  const RideChatMessagePage({
    required this.items,
    required this.hasMore,
    required this.nextBeforeId,
  });

  factory RideChatMessagePage.fromJson(Map<String, dynamic> json) =>
      RideChatMessagePage(
        items: (json['items'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map((item) => RideChatMessageModel.fromJson(
                  Map<String, dynamic>.from(item),
                ))
            .toList(),
        hasMore: json['has_more'] == true,
        nextBeforeId: _nullableInt(json['next_before_id']),
      );
}

int _int(dynamic value) => value is int ? value : int.tryParse('$value') ?? 0;
int? _nullableInt(dynamic value) => value == null ? null : _int(value);
DateTime? _date(dynamic value) =>
    value == null ? null : DateTime.tryParse('$value')?.toLocal();
