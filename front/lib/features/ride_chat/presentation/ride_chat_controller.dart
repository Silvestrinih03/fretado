import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/models/ride_chat_models.dart';
import '../data/ride_chat_repository.dart';

class RideChatController extends ChangeNotifier {
  final RideChatRepository repository;
  final int rideId;
  final int currentUserId;
  final Random _random = Random.secure();

  RideChatController({
    required this.repository,
    required this.rideId,
    required this.currentUserId,
  });

  List<RideConversationModel> conversations = const [];
  List<RideChatMessageModel> messages = const [];
  RideConversationModel? selected;
  bool loading = true;
  bool loadingOlder = false;
  bool sending = false;
  bool polling = false;
  bool hasOlder = false;
  String? error;
  String? sendError;
  String? _pendingContent;
  String? _pendingClientMessageId;
  bool _disposed = false;

  Future<void> initialize() async {
    loading = true;
    error = null;
    _notify();
    try {
      conversations = await repository.conversations(rideId);
      selected = _firstOrNull(conversations.where((item) => item.isCurrent)) ??
          _firstOrNull(conversations);
      if (selected != null) await _loadSelected();
    } catch (_) {
      error = 'Não foi possível carregar a conversa.';
    } finally {
      loading = false;
      _notify();
    }
  }

  Future<void> selectConversation(RideConversationModel conversation) async {
    if (selected?.id == conversation.id) return;
    selected = conversation;
    messages = const [];
    loading = true;
    error = null;
    _notify();
    try {
      await _loadSelected();
    } catch (_) {
      error = 'Não foi possível carregar as mensagens.';
    } finally {
      loading = false;
      _notify();
    }
  }

  Future<void> _loadSelected() async {
    final conversation = selected;
    if (conversation == null) return;
    final page = await repository.messages(conversation.id);
    messages = page.items;
    hasOlder = page.hasMore;
    await _markLoadedRead();
    try {
      final updated = await repository.conversations(rideId);
      conversations = updated;
      selected = _firstOrNull(
        updated.where((item) => item.id == conversation.id),
      );
    } catch (_) {
      // As mensagens continuam disponíveis mesmo se o resumo falhar.
    }
  }

  Future<int> poll() async {
    final conversation = selected;
    if (conversation == null || loading || polling) return 0;
    polling = true;
    try {
      final page = await repository.messages(
        conversation.id,
        afterId: messages.isEmpty ? null : messages.last.id,
      );
      final existing = messages.map((item) => item.id).toSet();
      final additions = page.items.where((item) => !existing.contains(item.id)).toList();
      if (additions.isNotEmpty) {
        messages = [...messages, ...additions];
        await _markLoadedRead();
        _notify();
      }
      return additions.length;
    } catch (_) {
      return 0;
    } finally {
      polling = false;
    }
  }

  Future<int> loadOlder() async {
    final conversation = selected;
    if (conversation == null || loadingOlder || !hasOlder || messages.isEmpty) {
      return 0;
    }
    loadingOlder = true;
    _notify();
    try {
      final page = await repository.messages(
        conversation.id,
        beforeId: messages.first.id,
      );
      final existing = messages.map((item) => item.id).toSet();
      final older = page.items.where((item) => !existing.contains(item.id)).toList();
      messages = [...older, ...messages];
      hasOlder = page.hasMore;
      return older.length;
    } catch (_) {
      return 0;
    } finally {
      loadingOlder = false;
      _notify();
    }
  }

  Future<bool> send(String content) async {
    final conversation = selected;
    final normalized = content.trim();
    if (conversation == null || !conversation.canSend || normalized.isEmpty || sending) {
      return false;
    }
    if (_pendingContent != normalized || _pendingClientMessageId == null) {
      _pendingContent = normalized;
      _pendingClientMessageId = _newClientMessageId();
    }
    sending = true;
    sendError = null;
    _notify();
    try {
      final message = await repository.send(
        conversation.id,
        content: normalized,
        clientMessageId: _pendingClientMessageId!,
      );
      if (!messages.any((item) => item.id == message.id)) {
        messages = [...messages, message];
      }
      _pendingContent = null;
      _pendingClientMessageId = null;
      return true;
    } catch (_) {
      sendError = 'Não foi possível enviar. Tente novamente.';
      return false;
    } finally {
      sending = false;
      _notify();
    }
  }

  Future<void> refreshConversations() async {
    try {
      final updated = await repository.conversations(rideId);
      final selectedId = selected?.id;
      conversations = updated;
      if (selectedId != null) {
        selected = _firstOrNull(
          updated.where((item) => item.id == selectedId),
        );
      }
      selected ??= _firstOrNull(updated.where((item) => item.isCurrent)) ??
          _firstOrNull(updated);
      _notify();
    } catch (_) {}
  }

  Future<void> _markLoadedRead() async {
    final conversation = selected;
    if (conversation == null || messages.isEmpty) return;
    try {
      await repository.markRead(conversation.id, messages.last.id);
    } catch (_) {
      // A leitura sera tentada novamente no proximo ciclo do polling.
    }
  }

  String _newClientMessageId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final random = _random.nextInt(0x7fffffff).toRadixString(16);
    return '$currentUserId-$timestamp-$random';
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

T? _firstOrNull<T>(Iterable<T> values) {
  final iterator = values.iterator;
  return iterator.moveNext() ? iterator.current : null;
}
