import 'package:flutter/material.dart';

import '../../../../app/design_system/design_system.dart';
import 'edit_card_data_page.dart';

class MyPaymentMethodsPage extends StatelessWidget {
  const MyPaymentMethodsPage({super.key});

  static const Color _primaryBlue = Color(0xFF080A73);
  static const Color _screenBackground = Color(0xFFF7F8FA);
  static const Color _mutedText = Color(0xFF3F4050);
  static const Color _cardBorder = Color(0xFFC8C9D8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _screenBackground,
      body: SafeArea(
        child: Column(
          children: [
            const _PaymentMethodsHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 34, 14, 24),
                children: const [
                  Text(
                    'Cartões cadastrados',
                    style: TextStyle(
                      color: FretColors.neutral900,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Gerencie seus métodos de pagamento para\nsolicitações rápidas.',
                    style: TextStyle(
                      color: _mutedText,
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 28),
                  _RegisteredCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodsHeader extends StatelessWidget {
  const _PaymentMethodsHeader();

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
              'Métodos de pagamento',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: MyPaymentMethodsPage._primaryBlue,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _RegisteredCard extends StatelessWidget {
  const _RegisteredCard();

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
            children: const [
              _CardIconBox(),
              SizedBox(width: 12),
              Expanded(child: _CardBrandDetails()),
              SizedBox(width: 10),
              _FretadoCardBrand(),
            ],
          ),
          const SizedBox(height: 28),
          const FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '* * * *  * * * *  * * * *  1234',
              maxLines: 1,
              style: TextStyle(
                color: FretColors.neutral900,
                fontSize: 18,
                fontWeight: FontWeight.w400,
                letterSpacing: 1.3,
              ),
            ),
          ),
          const SizedBox(height: 29),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              Expanded(child: _ExpirationInfo()),
              _EditPaymentButton(),
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
  const _CardBrandDetails();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Mastercard Platinum',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: FretColors.neutral900,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 2),
        Text(
          'Final 1234',
          style: TextStyle(
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
        'FreteJá',
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
  const _ExpirationInfo();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'VENCIMENTO',
          style: TextStyle(
            color: MyPaymentMethodsPage._mutedText,
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 5),
        Text(
          '03/2032',
          style: TextStyle(
            color: FretColors.neutral900,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _EditPaymentButton extends StatelessWidget {
  const _EditPaymentButton();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: MyPaymentMethodsPage._primaryBlue,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const EditCardDataPage(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(9),
        child: const SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            Icons.edit_rounded,
            color: FretColors.white,
            size: 19,
          ),
        ),
      ),
    );
  }
}
