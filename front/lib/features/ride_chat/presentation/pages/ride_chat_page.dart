import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/design_system/design_system.dart';
import '../../../../core/services/http_service.dart';
import '../../../../core/services/session/session_storage.dart';
import '../../data/models/ride_chat_models.dart';
import '../../data/ride_chat_repository.dart';
import '../ride_chat_controller.dart';

class RideChatPage extends StatefulWidget {
  final int rideId;

  const RideChatPage({super.key, required this.rideId});

  @override
  State<RideChatPage> createState() => _RideChatPageState();
}

class _RideChatPageState extends State<RideChatPage>
    with WidgetsBindingObserver {
  late final HttpService _http;
  late final RideChatController _controller;
  late final ScrollController _scrollController;
  final TextEditingController _draftController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _pollTimer;
  bool _showNewMessages = false;
  bool _didInitialScroll = false;

  bool get _isClient => SessionStorage.instance.currentUserTypeId == 1;

  List<String> get _suggestions => _isClient
      ? const [
          'Olá! Tudo bem?',
          'A encomenda está pronta',
          'Pode me avisar quando chegar?',
        ]
      : const [
          'Estou a caminho!',
          'Cheguei ao local de coleta',
          'Vou iniciar a entrega',
        ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _http = HttpService();
    _draftController.addListener(_onDraftChanged);
    _scrollController = ScrollController()..addListener(_onScroll);
    _controller = RideChatController(
      repository: RideChatRepository(_http),
      rideId: widget.rideId,
      currentUserId: SessionStorage.instance.currentUserId ?? 0,
    )..addListener(_onControllerChanged);
    _controller.initialize();
    _startPolling();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startPolling();
      _poll();
    } else {
      _pollTimer?.cancel();
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _poll());
  }

  Future<void> _poll() async {
    final wasNearBottom = _isNearBottom;
    final added = await _controller.poll();
    await _controller.refreshConversations();
    if (!mounted || added == 0) return;
    if (wasNearBottom) {
      _scrollToBottom();
    } else {
      setState(() => _showNewMessages = true);
    }
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
    if (!_didInitialScroll && !_controller.loading && _controller.messages.isNotEmpty) {
      _didInitialScroll = true;
      _scrollToBottom(jump: true);
    }
  }

  void _onDraftChanged() {
    if (mounted) setState(() {});
  }

  bool get _isNearBottom {
    if (!_scrollController.hasClients) return true;
    return _scrollController.position.maxScrollExtent -
            _scrollController.position.pixels <
        90;
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels < 80 &&
        _controller.hasOlder &&
        !_controller.loadingOlder) {
      _loadOlderPreservingPosition();
    }
    if (_showNewMessages && _isNearBottom) {
      setState(() => _showNewMessages = false);
    }
  }

  Future<void> _loadOlderPreservingPosition() async {
    final oldExtent = _scrollController.position.maxScrollExtent;
    final oldOffset = _scrollController.offset;
    final added = await _controller.loadOlder();
    if (!mounted || added == 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final delta = _scrollController.position.maxScrollExtent - oldExtent;
      _scrollController.jumpTo(oldOffset + delta);
    });
  }

  Future<void> _send([String? quickMessage]) async {
    final text = (quickMessage ?? _draftController.text).trim();
    if (text.isEmpty) return;
    final sent = await _controller.send(text);
    if (!mounted) return;
    if (sent) {
      _draftController.clear();
      _showNewMessages = false;
      _scrollToBottom();
    } else if (quickMessage != null) {
      _draftController.text = quickMessage;
      _draftController.selection = TextSelection.collapsed(
        offset: _draftController.text.length,
      );
    }
  }

  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      if (jump) {
        _scrollController.jumpTo(target);
      } else {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _selectConversation(RideConversationModel conversation) async {
    _didInitialScroll = false;
    _showNewMessages = false;
    await _controller.selectConversation(conversation);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    _controller
      ..removeListener(_onControllerChanged)
      ..dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _draftController
      ..removeListener(_onDraftChanged)
      ..dispose();
    _focusNode.dispose();
    _http.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conversation = _controller.selected;
    return Scaffold(
      backgroundColor: FretColors.screenBackground,
      body: SafeArea(
        child: Column(
          children: [
            _ChatHeader(
              conversation: conversation,
              rideId: widget.rideId,
              isClient: _isClient,
              onBack: () => Navigator.of(context).pop(),
            ),
            if (_isClient && _controller.conversations.length > 1)
              _ConversationSelector(
                conversations: _controller.conversations,
                selectedId: conversation?.id,
                enabled: !_controller.loading,
                onSelected: _selectConversation,
              ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 9, 20, 7),
              child: Text(
                'Conversa vinculada a esta corrida. Evite compartilhar informações pessoais.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: FretColors.screenMuted,
                  fontSize: 11,
                  height: 1.45,
                ),
              ),
            ),
            Expanded(child: _buildMessages()),
            if (_showNewMessages)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: FilledButton.tonalIcon(
                  onPressed: () {
                    setState(() => _showNewMessages = false);
                    _scrollToBottom();
                  },
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                  label: const Text('Novas mensagens'),
                ),
              ),
            if (conversation != null && conversation.canSend)
              _ChatComposer(
                controller: _draftController,
                focusNode: _focusNode,
                suggestions: _suggestions,
                sending: _controller.sending,
                error: _controller.sendError,
                onSuggestion: _send,
                onSend: _send,
              )
            else if (conversation != null)
              const _ClosedConversationBanner(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessages() {
    if (_controller.loading) {
      return const Center(
        child: CircularProgressIndicator(color: FretColors.screenGold),
      );
    }
    if (_controller.error != null) {
      return _ChatState(
        icon: Icons.error_outline_rounded,
        text: _controller.error!,
        action: 'Tentar novamente',
        onTap: _controller.initialize,
      );
    }
    if (_controller.selected == null) {
      return const _ChatState(
        icon: Icons.chat_bubble_outline_rounded,
        text: 'Esta corrida ainda não possui conversas.',
      );
    }
    if (_controller.messages.isEmpty) {
      return const _ChatState(
        icon: Icons.forum_outlined,
        text: 'Nenhuma mensagem ainda.\nComece a conversa por aqui.',
      );
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
      itemCount: _controller.messages.length +
          (_controller.loadingOlder ? 1 : 0),
      itemBuilder: (context, index) {
        if (_controller.loadingOlder && index == 0) {
          return const Padding(
            padding: EdgeInsets.all(10),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        final messageIndex = index - (_controller.loadingOlder ? 1 : 0);
        final message = _controller.messages[messageIndex];
        return _MessageBubble(
          message: message,
          sentByMe: message.senderUserId == _controller.currentUserId,
        );
      },
    );
  }
}

class _ChatHeader extends StatelessWidget {
  final RideConversationModel? conversation;
  final int rideId;
  final bool isClient;
  final VoidCallback onBack;

  const _ChatHeader({
    required this.conversation,
    required this.rideId,
    required this.isClient,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) => Column(
        children: [
          SizedBox(
            height: 54,
            child: Row(
              children: [
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
                ),
                const Text(
                  'Conversa da corrida',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 11, 20, 12),
            decoration: const BoxDecoration(
              color: FretColors.white,
              border: Border(bottom: BorderSide(color: FretColors.screenBorder)),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E9C5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.person_outline_rounded),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conversation?.otherParticipant.fullName ?? 'Conversa',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${isClient ? 'Seu motorista' : 'Seu cliente'} · Corrida #$rideId',
                        style: const TextStyle(
                          fontSize: 11,
                          color: FretColors.screenMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}

class _ConversationSelector extends StatelessWidget {
  final List<RideConversationModel> conversations;
  final int? selectedId;
  final bool enabled;
  final ValueChanged<RideConversationModel> onSelected;

  const _ConversationSelector({
    required this.conversations,
    required this.selectedId,
    required this.enabled,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 48,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          itemCount: conversations.length,
          separatorBuilder: (_, __) => const SizedBox(width: 7),
          itemBuilder: (context, index) {
            final item = conversations[index];
            final selected = item.id == selectedId;
            return ChoiceChip(
              selected: selected,
              onSelected: enabled ? (_) => onSelected(item) : null,
              label: Text(
                '${item.otherParticipant.fullName}${item.isCurrent ? ' · atual' : ''}'
                '${item.unreadCount > 0 ? ' (${item.unreadCount})' : ''}',
              ),
            );
          },
        ),
      );
}

class _MessageBubble extends StatelessWidget {
  final RideChatMessageModel message;
  final bool sentByMe;

  const _MessageBubble({required this.message, required this.sentByMe});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    return Align(
        alignment: sentByMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: screenWidth > 680 ? 520 : screenWidth * .78,
          ),
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment:
                sentByMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: sentByMe ? FretColors.screenDark : FretColors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Color(0x08000000), blurRadius: 10),
                  ],
                ),
                child: Text(
                  message.content,
                  style: TextStyle(
                    color: sentByMe ? FretColors.white : FretColors.screenDark,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTime(message.sentAt),
                style: const TextStyle(fontSize: 10, color: FretColors.screenMuted),
              ),
            ],
          ),
        ),
      );
  }
}

class _ChatComposer extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final List<String> suggestions;
  final bool sending;
  final String? error;
  final ValueChanged<String> onSuggestion;
  final VoidCallback onSend;

  const _ChatComposer({
    required this.controller,
    required this.focusNode,
    required this.suggestions,
    required this.sending,
    required this.error,
    required this.onSuggestion,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: const BoxDecoration(
          color: FretColors.white,
          border: Border(top: BorderSide(color: FretColors.screenBorder)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: suggestions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 7),
                itemBuilder: (_, index) => OutlinedButton(
                  onPressed: sending ? null : () => onSuggestion(suggestions[index]),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 11),
                    minimumSize: Size.zero,
                    side: const BorderSide(color: FretColors.screenBorder),
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(fontSize: 11),
                  ),
                  child: Text(suggestions[index]),
                ),
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 7),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  error!,
                  style: const TextStyle(
                    color: FretColors.destructive700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 9),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    minLines: 1,
                    maxLines: 3,
                    maxLength: 1000,
                    onSubmitted: sending ? null : (_) => onSend(),
                    buildCounter: (
                      _, {
                      required currentLength,
                      required isFocused,
                      required maxLength,
                    }) => null,
                    decoration: InputDecoration(
                      hintText: 'Digite uma mensagem...',
                      filled: true,
                      fillColor: FretColors.screenBackground,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 11,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(13),
                        borderSide: const BorderSide(color: FretColors.screenBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(13),
                        borderSide: const BorderSide(color: FretColors.screenBorder),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                SizedBox(
                  height: 46,
                  child: FilledButton(
                    onPressed: sending || controller.text.trim().isEmpty
                        ? null
                        : onSend,
                    style: FilledButton.styleFrom(
                      backgroundColor: FretColors.screenGold,
                      foregroundColor: FretColors.screenDark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    child: sending
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Enviar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}

class _ClosedConversationBanner extends StatelessWidget {
  const _ClosedConversationBanner();

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        color: FretColors.white,
        child: const Text(
          'Esta conversa foi encerrada. O histórico continua disponível para consulta.',
          textAlign: TextAlign.center,
          style: TextStyle(color: FretColors.screenMuted, fontSize: 12),
        ),
      );
}

class _ChatState extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? action;
  final VoidCallback? onTap;

  const _ChatState({
    required this.icon,
    required this.text,
    this.action,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 38, color: FretColors.screenGold),
              const SizedBox(height: 12),
              Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(color: FretColors.screenMuted, height: 1.5),
              ),
              if (action != null && onTap != null)
                TextButton(onPressed: onTap, child: Text(action!)),
            ],
          ),
        ),
      );
}

String _formatTime(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
