import 'package:flutter/material.dart';

import '../../../../app/design_system/design_system.dart';

class ShippingPaymentPage extends StatefulWidget {
  const ShippingPaymentPage({super.key});

  @override
  State<ShippingPaymentPage> createState() => _ShippingPaymentPageState();
}

class _ShippingPaymentPageState extends State<ShippingPaymentPage> {
  static const Color _primaryBlue = Color(0xFF080A73);
  static const Color _orange = Color(0xFFB45C00);
  static const Color _screenBackground = Color(0xFFF7F8FA);
  static const Color _mutedText = Color(0xFF3F4050);

  String _selectedPaymentMethod = 'credit_card';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _screenBackground,
      body: SafeArea(
        child: Column(
          children: [
            const _PaymentHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(11, 26, 11, 26),
                children: [
                  const Text(
                    'ETAPA 4 DE 4',
                    style: TextStyle(
                      color: _orange,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Pagamento',
                    style: TextStyle(
                      color: FretColors.neutral900,
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Selecione como deseja pagar pelo seu frete.',
                    style: TextStyle(
                      color: _mutedText,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const _FreightSummaryCard(),
                  const SizedBox(height: 26),
                  const Text(
                    'Forma de Pagamento',
                    style: TextStyle(
                      color: FretColors.neutral900,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _PaymentOptionTile(
                    value: 'credit_card',
                    selectedValue: _selectedPaymentMethod,
                    icon: Icons.credit_card_rounded,
                    title: 'Cartão de Crédito',
                    subtitle: '**** 1234',
                    onChanged: _selectPaymentMethod,
                  ),
                  const SizedBox(height: 24),
                  const _ConfirmShippingButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectPaymentMethod(String value) {
    setState(() => _selectedPaymentMethod = value);
  }
}

class _PaymentHeader extends StatelessWidget {
  const _PaymentHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 47,
      decoration: const BoxDecoration(
        color: FretColors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE8E9EF))),
      ),
      child: Row(
        children: [
          const SizedBox(width: 2),
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: _ShippingPaymentPageState._primaryBlue,
              size: 22,
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            'Pagamento',
            style: TextStyle(
              color: _ShippingPaymentPageState._primaryBlue,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _FreightSummaryCard extends StatelessWidget {
  const _FreightSummaryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: FretColors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 22, 8, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Resumo do Frete',
                    style: TextStyle(
                      color: _ShippingPaymentPageState._primaryBlue,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 18),
                  _SummaryLabel(text: 'Origem'),
                  SizedBox(height: 10),
                  _SummaryLabel(text: 'Destino'),
                  SizedBox(height: 10),
                  _SummaryLabel(text: 'Carga'),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.fromLTRB(8, 18, 12, 20),
              color: const Color(0xFFF9F9FB),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      'R\$ 1.250,00',
                      maxLines: 1,
                      style: TextStyle(
                        color: FretColors.neutral900,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  SizedBox(height: 18),
                  _SummaryValue(text: 'São Paulo, SP'),
                  SizedBox(height: 10),
                  _SummaryValue(text: 'Rio de Janeiro, RJ'),
                  SizedBox(height: 10),
                  _SummaryValue(text: 'Paletes (1.500 kg)'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryLabel extends StatelessWidget {
  final String text;

  const _SummaryLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: _ShippingPaymentPageState._mutedText,
        fontSize: 11,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  final String text;

  const _SummaryValue({required this.text});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Text(
        text,
        maxLines: 1,
        textAlign: TextAlign.right,
        style: const TextStyle(
          color: FretColors.neutral900,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PaymentOptionTile extends StatelessWidget {
  final String value;
  final String selectedValue;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final ValueChanged<String> onChanged;

  const _PaymentOptionTile({
    required this.value,
    required this.selectedValue,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onChanged,
    this.iconColor = _ShippingPaymentPageState._primaryBlue,
  });

  bool get _isSelected => value == selectedValue;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: double.infinity,
        height: 57,
        padding: const EdgeInsets.fromLTRB(8, 10, 12, 10),
        decoration: BoxDecoration(
          color: FretColors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: _isSelected
                ? FretColors.white
                : const Color(0xFFE3E5EC),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 26,
              child: Radio<String>(
                value: value,
                groupValue: selectedValue,
                onChanged: (newValue) {
                  if (newValue != null) {
                    onChanged(newValue);
                  }
                },
                activeColor: _ShippingPaymentPageState._primaryBlue,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F2F8),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: FretColors.neutral900,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _ShippingPaymentPageState._mutedText,
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmShippingButton extends StatelessWidget {
  const _ConfirmShippingButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 43,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          elevation: 8,
          shadowColor: const Color(0x33080A73),
          backgroundColor: _ShippingPaymentPageState._primaryBlue,
          foregroundColor: FretColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Confirmar e Solicitar Frete',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(width: 12),
            Icon(Icons.arrow_forward_rounded, size: 22),
          ],
        ),
      ),
    );
  }
}
