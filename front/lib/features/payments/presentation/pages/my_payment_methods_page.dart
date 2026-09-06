import 'package:flutter/material.dart';

import '../../../../app/design_system/design_system.dart';
import '../../../../core/services/http_service.dart';
import '../../../../core/services/myself/services/myself_service.dart';
import '../../data/datasources/user_card_datasource.dart';
import '../../data/models/user_card_model.dart';
import '../../data/repositories/user_card_repository_impl.dart';
import '../stores/payment_cards_store.dart';
import 'edit_card_data_page.dart';

class MyPaymentMethodsPage extends StatefulWidget {
  final int? userId;
  final bool showBackButton;

  const MyPaymentMethodsPage({
    super.key,
    this.userId,
    this.showBackButton = true,
  });

  @override
  State<MyPaymentMethodsPage> createState() => _MyPaymentMethodsPageState();
}

class _MyPaymentMethodsPageState extends State<MyPaymentMethodsPage> {
  late final HttpService _httpService;
  late final PaymentCardsStore _store;

  @override
  void initState() {
    super.initState();
    final myselfService = MyselfService();
    if (widget.userId != null) {
      myselfService.currentUserId = widget.userId;
    }

    _httpService = HttpService();
    _store = PaymentCardsStore(
      UserCardRepositoryImpl(UserCardDatasource(_httpService)),
      myselfService,
      fallbackUserId: widget.userId,
    );
    _store.loadCards();
  }

  @override
  void dispose() {
    _store.dispose();
    _httpService.dispose();
    super.dispose();
  }

  Future<void> _openCardForm() async {
    final bool? didSave = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => EditCardDataPage(userId: widget.userId),
      ),
    );

    if (!mounted || didSave != true) {
      return;
    }

    _store.loadCards();
  }

  Future<void> _changeCard(UserCardModel card, {required bool remove}) async {
    final success = remove
        ? await _store.removeCard(card.id)
        : await _store.setDefaultCard(card.id);
    if (!mounted) return;
    if (!success) {
      showFretErrorPopup(
        context,
        message:
            _store.actionErrorMessage ?? 'N?o foi poss?vel atualizar o cart?o.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _store,
      builder: (context, _) => Scaffold(
        backgroundColor: FretColors.screenBackground,
        body: SafeArea(
          bottom: widget.showBackButton,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                child: Row(
                  children: [
                    if (widget.showBackButton)
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                        tooltip: 'Voltar',
                      ),
                    const Expanded(
                      child: Text(
                        'Pagamentos',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: FretColors.screenDark,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 38,
                      height: 38,
                      child: IconButton(
                        onPressed: _openCardForm,
                        tooltip: 'Adicionar cart?o',
                        style: IconButton.styleFrom(
                          backgroundColor: FretColors.screenDark,
                          foregroundColor: FretColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.add_rounded, size: 17),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _store.loadCards,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      if (_store.isLoading)
                        const Padding(
                          padding: EdgeInsets.all(52),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_store.loadErrorMessage != null)
                        _PaymentMethodsStateCard(
                          error: _store.loadErrorMessage,
                          onTap: _store.loadCards,
                        )
                      else if (_store.cards.isEmpty)
                        _PaymentMethodsStateCard(onTap: _openCardForm)
                      else ...[
                        const Text(
                          'Gerencie seus métodos de pagamento',
                          style: TextStyle(
                            fontSize: 12,
                            color: FretColors.screenMuted,
                          ),
                        ),
                        const SizedBox(height: 14),
                        for (final card in _store.cards) ...[
                          _RegisteredCard(card: card),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              if (!card.isDefault) ...[
                                Expanded(
                                  child: _CardAction(
                                    label: 'Definir padrão',
                                    icon: Icons.star_border_rounded,
                                    onTap: _store.isUpdating
                                        ? null
                                        : () =>
                                              _changeCard(card, remove: false),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Expanded(
                                child: _CardAction(
                                  label: 'Remover',
                                  icon: Icons.delete_outline_rounded,
                                  muted: true,
                                  onTap: _store.isUpdating
                                      ? null
                                      : () => _changeCard(card, remove: true),
                                ),
                              ),
                            ],
                          ),
                          if (_store.updatingCardId == card.id) ...[
                            const SizedBox(height: 6),
                            const LinearProgressIndicator(minHeight: 2),
                          ],
                          const SizedBox(height: 16),
                        ],
                        const SizedBox(height: 4),
                        _AddPaymentMethodButton(onTap: _openCardForm),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RegisteredCard extends StatelessWidget {
  final UserCardModel card;
  const _RegisteredCard({required this.card});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            card.brand.toLowerCase() == 'visa'
                ? const Color(0xFF1E2235)
                : FretColors.screenDark,
            const Color(0xFF2E2E3C),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x1AC9A227), Colors.transparent],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 26,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFD4A820), Color(0xFF8A6010)],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (card.isDefault) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0x2EC9A227),
                                borderRadius: BorderRadius.circular(99),
                                border: Border.all(
                                  color: const Color(0x52C9A227),
                                ),
                              ),
                              child: const Text(
                                'PADRÃO',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.54,
                                  color: FretColors.screenGold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Text(
                              card.brandLabel.toUpperCase(),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.56,
                                color: Color(0xD1FFFFFF),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '**** **** **** ${card.lastFour}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2.72,
                      color: Color(0xD1FFFFFF),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: _CardDetail(
                        label: 'TITULAR',
                        value: card.cardholderName.toUpperCase(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _CardDetail(
                      label: 'VENCE',
                      value: card.expirationText,
                      alignRight: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 2,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      FretColors.screenGold,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardDetail extends StatelessWidget {
  final String label;
  final String value;
  final bool alignRight;
  const _CardDetail({
    required this.label,
    required this.value,
    this.alignRight = false,
  });
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: alignRight
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 9,
          color: Color(0x61FFFFFF),
          letterSpacing: 0.54,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        value,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xCCFFFFFF),
        ),
      ),
    ],
  );
}

class _CardAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool muted;
  const _CardAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.muted = false,
  });
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onTap,
    icon: Icon(icon, size: 14),
    label: Text(label),
    style: OutlinedButton.styleFrom(
      foregroundColor: muted ? FretColors.screenMuted : FretColors.screenDark,
      side: const BorderSide(color: FretColors.screenBorder),
      padding: const EdgeInsets.symmetric(vertical: 9),
      minimumSize: const Size(0, 38),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      textStyle: TextStyle(
        fontSize: 12,
        fontWeight: muted ? FontWeight.w500 : FontWeight.w600,
      ),
    ),
  );
}

class _PaymentMethodsStateCard extends StatelessWidget {
  final String? error;
  final VoidCallback onTap;
  const _PaymentMethodsStateCard({this.error, required this.onTap});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 52),
    child: Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: FretColors.white,
            shape: BoxShape.circle,
            border: Border.all(color: FretColors.screenBorder),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 12,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            error == null
                ? Icons.credit_card_outlined
                : Icons.error_outline_rounded,
            size: 30,
            color: FretColors.screenGold,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          error == null
              ? 'Nenhum cartão cadastrado'
              : 'Não foi possível carregar os cartões',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: FretColors.screenDark,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          error ??
              'Adicione um cartão para facilitar\nseus pagamentos de frete.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            height: 1.55,
            color: FretColors.screenMuted,
          ),
        ),
        const SizedBox(height: 28),
        ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(
            error == null ? Icons.add_rounded : Icons.refresh_rounded,
            size: 16,
          ),
          label: Text(error == null ? 'Adicionar cartão' : 'Tentar novamente'),
          style: ElevatedButton.styleFrom(
            backgroundColor: FretColors.screenGold,
            foregroundColor: FretColors.screenDark,
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _AddPaymentMethodButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddPaymentMethodButton({required this.onTap});
  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _DashedCardBorder(),
    child: TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FretIconBox(
            icon: Icons.add_rounded,
            size: 26,
            iconSize: 14,
            radius: 8,
            backgroundColor: FretColors.screenDark,
            iconColor: FretColors.white,
          ),
          SizedBox(width: 10),
          Text(
            'Adicionar novo cartão',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: FretColors.screenDark,
            ),
          ),
        ],
      ),
    ),
  );
}

class _DashedCardBorder extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(1),
          const Radius.circular(16),
        ),
      );
    final paint = Paint()
      ..color = FretColors.screenBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final metric in path.computeMetrics()) {
      for (double offset = 0; offset < metric.length; offset += 7) {
        canvas.drawPath(metric.extractPath(offset, offset + 4), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCardBorder oldDelegate) => false;
}
