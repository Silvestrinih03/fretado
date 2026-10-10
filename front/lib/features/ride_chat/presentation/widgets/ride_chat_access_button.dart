import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/design_system/design_system.dart';
import '../../../../core/services/http_service.dart';
import '../../../../core/services/session/session_storage.dart';
import '../../data/models/ride_chat_models.dart';
import '../../data/ride_chat_repository.dart';
import '../pages/ride_chat_page.dart';

class RideChatAccessButton extends StatefulWidget {
  final int rideId;
  final bool compact;
  final String? labelOverride;

  const RideChatAccessButton({
    super.key,
    required this.rideId,
    this.compact = false,
    this.labelOverride,
  });

  @override
  State<RideChatAccessButton> createState() => _RideChatAccessButtonState();
}

class _RideChatAccessButtonState extends State<RideChatAccessButton>
    with WidgetsBindingObserver {
  late final HttpService _http;
  late final RideChatRepository _repository;
  Timer? _timer;
  bool _loading = false;
  List<RideConversationModel> _conversations = const [];

  bool get _isClient => SessionStorage.instance.currentUserTypeId == 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _http = HttpService();
    _repository = RideChatRepository(_http);
    _load();
    _startPolling();
  }

  void _startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _load());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _load();
      _startPolling();
    } else {
      _timer?.cancel();
    }
  }

  Future<void> _load() async {
    if (_loading) return;
    _loading = true;
    try {
      final result = await _repository.conversations(widget.rideId);
      if (mounted) setState(() => _conversations = result);
    } catch (_) {
      // Mantem o ultimo estado conhecido quando a conexao oscila.
    } finally {
      _loading = false;
    }
  }

  Future<void> _open() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RideChatPage(rideId: widget.rideId),
      ),
    );
    if (mounted) await _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _http.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_conversations.isEmpty) return const SizedBox.shrink();
    RideConversationModel? current;
    for (final item in _conversations) {
      if (item.isCurrent) {
        current = item;
        break;
      }
    }
    final unread = current?.unreadCount ?? 0;
    final defaultLabel = current != null
        ? 'Conversar com ${_isClient ? 'motorista' : 'cliente'}'
        : _conversations.length > 1
            ? 'Ver conversas'
            : 'Ver conversa';
    final label = widget.labelOverride ?? defaultLabel;
    return FilledButton(
      onPressed: _open,
      style: FilledButton.styleFrom(
        minimumSize: Size.fromHeight(widget.compact ? 42 : 46),
        backgroundColor: FretColors.screenDark,
        foregroundColor: FretColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: widget.compact ? MainAxisSize.min : MainAxisSize.max,
        children: [
          const Icon(Icons.chat_bubble_outline_rounded, size: 17),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          if (unread > 0) ...[
            const SizedBox(width: 7),
            Container(
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: FretColors.screenGold,
                borderRadius: BorderRadius.circular(99),
              ),
              alignment: Alignment.center,
              child: Text(
                unread > 99 ? '99+' : '$unread',
                style: const TextStyle(
                  color: FretColors.screenDark,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
