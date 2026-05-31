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

  const MyPaymentMethodsPage({super.key, this.userId});

  static const Color _primaryBlue = Color(0xFF080A73);
  static const Color _screenBackground = Color(0xFFF7F8FA);
  static const Color _mutedText = Color(0xFF3F4050);
  static const Color _cardBorder = Color(0xFFC8C9D8);

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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _store,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: MyPaymentMethodsPage._screenBackground,
          body: SafeArea(
            child: Column(
              children: [
                _PaymentMethodsHeader(onAddTap: _openCardForm),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(14, 34, 14, 24),
                    children: [
                      const Text(
                        'Cartoes cadastrados',
                        style: TextStyle(
                          color: FretColors.neutral900,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Gerencie seus metodos de pagamento para\nsolicitacoes rapidas.',
                        style: TextStyle(
                          color: MyPaymentMethodsPage._mutedText,
                          fontSize: 13,
                          height: 1.35,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 28),
                      if (_store.isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 18),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_store.loadErrorMessage != null)
                        _PaymentMethodsStateCard(
                          icon: Icons.error_outline_rounded,
                          title: 'Nao foi possivel carregar os cartoes',
                          subtitle: _store.loadErrorMessage!,
                          actionLabel: 'Tentar novamente',
                          onTap: _store.loadCards,
                        )
                      else if (_store.cards.isEmpty)
                        _PaymentMethodsStateCard(
                          icon: Icons.add_card_rounded,
                          title: 'Nenhum cartao cadastrado',
                          subtitle: 'Cadastre um cartao para usar nas viagens.',
                          actionLabel: 'Cadastrar cartao',
                          onTap: _openCardForm,
                        )
                      else ...[
                        ..._store.cards.asMap().entries.map((entry) {
                          final index = entry.key;
                          final card = entry.value;

                          return Column(
                            children: [
                              _RegisteredCard(card: card),
                              if (index != _store.cards.length - 1)
                                const SizedBox(height: 12),
                            ],
                          );
                        }),
                        const SizedBox(height: 16),
                        _AddPaymentMethodButton(onTap: _openCardForm),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PaymentMethodsHeader extends StatelessWidget {
  final VoidCallback onAddTap;

  const _PaymentMethodsHeader({required this.onAddTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      color: FretColors.white,
      child: Row(
        children: [
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: MyPaymentMethodsPage._mutedText,
              size: 24,
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Metodos de pagamento',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: MyPaymentMethodsPage._primaryBlue,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Cadastrar cartao',
            onPressed: onAddTap,
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.add_card_rounded,
              color: MyPaymentMethodsPage._primaryBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: 8),
        ],
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
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 25, 20, 21),
      decoration: BoxDecoration(
        color: FretColors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: MyPaymentMethodsPage._cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _CardIconBox(),
              const SizedBox(width: 12),
              Expanded(child: _CardBrandDetails(card: card)),
              const SizedBox(width: 10),
              const _FretadoCardBrand(),
            ],
          ),
          const SizedBox(height: 28),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '* * * *  * * * *  * * * *  ${card.lastFour}',
              maxLines: 1,
              style: const TextStyle(
                color: FretColors.neutral900,
                fontSize: 18,
                fontWeight: FontWeight.w400,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(height: 29),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: _ExpirationInfo(card: card)),
              if (card.isDefault) const _DefaultBadge(),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardIconBox extends StatelessWidget {
  const _CardIconBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 28,
      decoration: const BoxDecoration(color: Color(0xFFE8E8EA)),
      alignment: Alignment.center,
      child: const Icon(
        Icons.credit_card_rounded,
        color: MyPaymentMethodsPage._primaryBlue,
        size: 22,
      ),
    );
  }
}

class _CardBrandDetails extends StatelessWidget {
  final UserCardModel card;

  const _CardBrandDetails({required this.card});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          card.brandLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: FretColors.neutral900,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Final ${card.lastFour}',
          style: const TextStyle(
            color: MyPaymentMethodsPage._mutedText,
            fontSize: 11,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _FretadoCardBrand extends StatelessWidget {
  const _FretadoCardBrand();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 1),
      child: Text(
        'FreteJa',
        style: TextStyle(
          color: MyPaymentMethodsPage._primaryBlue,
          fontSize: 15,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ExpirationInfo extends StatelessWidget {
  final UserCardModel card;

  const _ExpirationInfo({required this.card});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'VENCIMENTO',
          style: TextStyle(
            color: MyPaymentMethodsPage._mutedText,
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          card.expirationText,
          style: const TextStyle(
            color: FretColors.neutral900,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _DefaultBadge extends StatelessWidget {
  const _DefaultBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF0FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'Padrao',
        style: TextStyle(
          color: MyPaymentMethodsPage._primaryBlue,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PaymentMethodsStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;

  const _PaymentMethodsStateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: FretColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: MyPaymentMethodsPage._cardBorder),
      ),
      child: Column(
        children: [
          Icon(icon, color: MyPaymentMethodsPage._primaryBlue, size: 34),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: FretColors.neutral900,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: MyPaymentMethodsPage._mutedText,
              fontSize: 13,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: MyPaymentMethodsPage._primaryBlue,
              foregroundColor: FretColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _AddPaymentMethodButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddPaymentMethodButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: FretColors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: MyPaymentMethodsPage._cardBorder),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_card_rounded,
                color: MyPaymentMethodsPage._primaryBlue,
              ),
              SizedBox(width: 10),
              Text(
                'Cadastrar outro cartao',
                style: TextStyle(
                  color: MyPaymentMethodsPage._primaryBlue,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
