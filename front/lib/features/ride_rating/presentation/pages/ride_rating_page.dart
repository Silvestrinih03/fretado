import 'package:flutter/material.dart';

import '../../../../app/design_system/design_system.dart';
import '../../../../core/services/http_service.dart';
import '../../data/ride_rating_repository.dart';
import '../ride_rating_controller.dart';

class RideRatingPage extends StatefulWidget {
  final int rideId;

  const RideRatingPage({super.key, required this.rideId});

  @override
  State<RideRatingPage> createState() => _RideRatingPageState();
}

class _RideRatingPageState extends State<RideRatingPage> {
  late final HttpService _http;
  late final RideRatingController _controller;
  late final TextEditingController _commentController;

  @override
  void initState() {
    super.initState();
    _http = HttpService();
    _controller = RideRatingController(
      repository: RideRatingRepository(_http),
      rideId: widget.rideId,
    )..addListener(_refresh);
    _commentController = TextEditingController()..addListener(_refresh);
    _controller.initialize();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _commentController
      ..removeListener(_refresh)
      ..dispose();
    _controller
      ..removeListener(_refresh)
      ..dispose();
    _http.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).pop(_controller.sent);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        backgroundColor: FretColors.screenBackground,
        body: SafeArea(
          child: Column(
            children: [
              _RatingHeader(onBack: _close),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_controller.loading) {
      return const Center(
        child: CircularProgressIndicator(color: FretColors.screenGold),
      );
    }
    if (_controller.error != null && _controller.state == null) {
      return _RatingState(
        icon: Icons.error_outline_rounded,
        title: 'Não foi possível carregar',
        message: _controller.error!,
        actionLabel: 'Tentar novamente',
        onAction: _controller.initialize,
      );
    }
    if (_controller.sent || _controller.state?.rating != null) {
      return _RatingState(
        icon: Icons.celebration_rounded,
        title: 'Avaliação enviada!',
        message:
            'Obrigado por compartilhar sua experiência. Sua opinião ajuda a tornar o Fretado cada vez melhor.',
        actionLabel: 'Voltar para a corrida',
        onAction: _close,
      );
    }
    final state = _controller.state;
    if (state == null || !state.eligible || state.reviewee == null) {
      return _RatingState(
        icon: Icons.star_outline_rounded,
        title: 'Avaliação indisponível',
        message: state?.ineligibleReason ?? 'Esta corrida não pode ser avaliada.',
        actionLabel: 'Voltar',
        onAction: _close,
      );
    }

    final revieweeLabel = state.reviewee!.role == 'driver'
        ? 'o motorista'
        : 'o cliente';
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
      children: [
        const Text(
          'CORRIDA CONCLUÍDA',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: FretColors.screenGold,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.8,
          ),
        ),
        const SizedBox(height: 16),
        const Icon(Icons.star_rounded, color: FretColors.screenGold, size: 50),
        const SizedBox(height: 10),
        const Text(
          'Como foi sua experiência?',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: FretColors.screenDark,
            fontSize: 23,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            text: 'Avalie $revieweeLabel ',
            children: [
              TextSpan(
                text: state.reviewee!.fullName,
                style: const TextStyle(
                  color: FretColors.screenDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(color: FretColors.screenMuted, fontSize: 13),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final value = index + 1;
            return IconButton(
              tooltip: '$value estrelas',
              padding: const EdgeInsets.symmetric(horizontal: 2),
              constraints: const BoxConstraints(minWidth: 43, minHeight: 48),
              onPressed: () => _controller.selectScore(value),
              icon: Icon(
                Icons.star_rounded,
                size: 38,
                color: value <= _controller.score
                    ? FretColors.screenGold
                    : const Color(0xFFD9D9D9),
              ),
            );
          }),
        ),
        Text(
          _scoreLabel(_controller.score),
          textAlign: TextAlign.center,
          style: const TextStyle(color: FretColors.screenMuted, fontSize: 12),
        ),
        const SizedBox(height: 26),
        _RatingSection(
          title: 'O que você destacaria?',
          optional: true,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: state.allowedCriteria.map((criterion) {
              final selected = _controller.criteria.contains(criterion.key);
              return FilterChip(
                selected: selected,
                showCheckmark: true,
                checkmarkColor: FretColors.screenDark,
                label: Text(criterion.label),
                onSelected: (_) => _controller.toggleCriterion(criterion.key),
                backgroundColor: FretColors.screenBackground,
                selectedColor: const Color(0xFFFFF7DC),
                side: BorderSide(
                  color: selected
                      ? FretColors.screenGold
                      : FretColors.screenBorder,
                ),
                labelStyle: const TextStyle(
                  color: FretColors.screenDark,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        _RatingSection(
          title: 'Deixe um comentário',
          optional: true,
          child: TextField(
            controller: _commentController,
            maxLength: 500,
            maxLines: 4,
            minLines: 4,
            decoration: InputDecoration(
              hintText: 'Conte um pouco sobre a sua experiência...',
              hintStyle: const TextStyle(
                color: FretColors.screenMuted,
                fontSize: 12,
              ),
              filled: true,
              fillColor: FretColors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: FretColors.screenBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: FretColors.screenBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: FretColors.screenGold),
              ),
            ),
          ),
        ),
        if (_controller.error != null) ...[
          const SizedBox(height: 12),
          Text(
            _controller.error!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: FretColors.destructive700,
              fontSize: 12,
            ),
          ),
        ],
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _controller.score == 0 || _controller.sending
              ? null
              : () => _controller.submit(_commentController.text),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            backgroundColor: FretColors.screenDark,
            foregroundColor: FretColors.white,
            disabledBackgroundColor: FretColors.screenDark.withValues(alpha: .35),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: _controller.sending
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: FretColors.white,
                  ),
                )
              : const Text(
                  'Enviar avaliação',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
        ),
        TextButton(
          onPressed: _controller.sending ? null : _close,
          child: const Text(
            'Avaliar depois',
            style: TextStyle(color: FretColors.screenMuted),
          ),
        ),
      ],
    );
  }
}

class _RatingHeader extends StatelessWidget {
  final VoidCallback onBack;

  const _RatingHeader({required this.onBack});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 5, 20, 8),
    child: Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        const Text(
          'Avaliar corrida',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
      ],
    ),
  );
}

class _RatingSection extends StatelessWidget {
  final String title;
  final bool optional;
  final Widget child;

  const _RatingSection({
    required this.title,
    required this.optional,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: FretColors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: FretColors.screenBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: title,
            children: optional
                ? const [
                    TextSpan(
                      text: ' (opcional)',
                      style: TextStyle(
                        color: FretColors.screenMuted,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ]
                : const [],
          ),
          style: const TextStyle(
            color: FretColors.screenDark,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}

class _RatingState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _RatingState({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 28),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: FretColors.screenGold, size: 58),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: FretColors.screenMuted,
              fontSize: 13,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: onAction,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: FretColors.screenDark,
              foregroundColor: FretColors.white,
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    ),
  );
}

String _scoreLabel(int score) => switch (score) {
  1 => 'Muito ruim',
  2 => 'Ruim',
  3 => 'Regular',
  4 => 'Bom',
  5 => 'Excelente',
  _ => 'Selecione uma nota',
};
