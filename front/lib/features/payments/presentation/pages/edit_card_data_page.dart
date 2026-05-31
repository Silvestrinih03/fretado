import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/design_system/design_system.dart';

class EditCardDataPage extends StatefulWidget {
  const EditCardDataPage({super.key});

  @override
  State<EditCardDataPage> createState() => _EditCardDataPageState();
}

class _EditCardDataPageState extends State<EditCardDataPage> {
  static const Color _primaryBlue = Color(0xFF080A73);
  static const Color _screenBackground = Color(0xFFF7F8FA);
  static const Color _fieldBackground = Color(0xFFE8E8EA);
  static const Color _mutedText = Color(0xFF3F4050);
  static const Color _hintText = Color(0xFFAEB0BA);

  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cardNameController = TextEditingController();
  final TextEditingController _expirationController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cardNameController.addListener(_refreshPreview);
    _expirationController.addListener(_refreshPreview);
  }

  @override
  void dispose() {
    _cardNameController.removeListener(_refreshPreview);
    _expirationController.removeListener(_refreshPreview);
    _cardNumberController.dispose();
    _cardNameController.dispose();
    _expirationController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _screenBackground,
      body: SafeArea(
        child: Column(
          children: [
            const _EditCardHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(19, 30, 19, 22),
                children: [
                  _CreditCardPreview(
                    holderName: _cardNameController.text,
                    expiration: _expirationController.text,
                  ),
                  const SizedBox(height: 34),
                  _CardInputField(
                    label: 'Número do cartão',
                    hintText: '0000 0000 0000 0000',
                    controller: _cardNumberController,
                    keyboardType: TextInputType.number,
                    suffixIcon: Icons.credit_card_rounded,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(16),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _CardInputField(
                    label: 'Nome no cartão',
                    hintText: 'COMO IMPRESSO NO CARTÃO',
                    controller: _cardNameController,
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _CardInputField(
                          label: 'Validade (MM/AA)',
                          hintText: 'MM/AA',
                          controller: _expirationController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _CardInputField(
                          label: 'CVV',
                          hintText: '000',
                          controller: _cvvController,
                          keyboardType: TextInputType.number,
                          suffixIcon: Icons.help_outline_rounded,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 21),
                ],
              ),
            ),
            const _SaveCardBar(),
          ],
        ),
      ),
    );
  }

  void _refreshPreview() {
    setState(() {});
  }
}

class _EditCardHeader extends StatelessWidget {
  const _EditCardHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: const BoxDecoration(
        color: FretColors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E3E8))),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 8,
            child: IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: _EditCardDataPageState._mutedText,
                size: 24,
              ),
            ),
          ),
          const Text(
            'Dados do cartão',
            style: TextStyle(
              color: _EditCardDataPageState._primaryBlue,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CreditCardPreview extends StatelessWidget {
  final String holderName;
  final String expiration;

  const _CreditCardPreview({
    required this.holderName,
    required this.expiration,
  });

  @override
  Widget build(BuildContext context) {
    final String displayName = holderName.trim().isEmpty
        ? 'SEU NOME AQUI'
        : holderName.trim().toUpperCase();
    final String displayExpiration = expiration.trim().isEmpty
        ? 'MM/AA'
        : _formatExpiration(expiration.trim());

    return Container(
      width: double.infinity,
      height: 193,
      padding: const EdgeInsets.fromLTRB(29, 30, 28, 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF080A73),
            Color(0xFF24268D),
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x19080A73),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: FretColors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.contactless_rounded,
                  color: _EditCardDataPageState._primaryBlue,
                  size: 19,
                ),
              ),
              const Spacer(),
              Container(
                width: 42,
                height: 28,
                decoration: BoxDecoration(
                  color: FretColors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ),
          const Spacer(),
          const FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '.  .  .  .  .  .  .  .  .  .',
              maxLines: 1,
              style: TextStyle(
                color: FretColors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _CardPreviewTextGroup(
                  label: 'NOME DO TITULAR',
                  value: displayName,
                ),
              ),
              const SizedBox(width: 18),
              _CardPreviewTextGroup(
                label: 'VALIDADE',
                value: displayExpiration,
                alignEnd: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatExpiration(String value) {
    final String digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length <= 2) {
      return digits;
    }
    return '${digits.substring(0, 2)}/${digits.substring(2)}';
  }
}

class _CardPreviewTextGroup extends StatelessWidget {
  final String label;
  final String value;
  final bool alignEnd;

  const _CardPreviewTextGroup({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: FretColors.white.withValues(alpha: 0.62),
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: alignEnd ? TextAlign.right : TextAlign.left,
          style: const TextStyle(
            color: FretColors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _CardInputField extends StatelessWidget {
  final String label;
  final String hintText;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final IconData? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;

  const _CardInputField({
    required this.label,
    required this.hintText,
    required this.controller,
    this.keyboardType,
    this.suffixIcon,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _EditCardDataPageState._mutedText,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 50,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            textCapitalization: textCapitalization,
            style: const TextStyle(
              color: FretColors.neutral800,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: _EditCardDataPageState._fieldBackground,
              hintText: hintText,
              hintStyle: const TextStyle(
                color: _EditCardDataPageState._hintText,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              suffixIcon: suffixIcon == null
                  ? null
                  : Icon(
                      suffixIcon,
                      color: const Color(0xFFB9BBCB),
                      size: 22,
                    ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 15,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(7),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SaveCardBar extends StatelessWidget {
  const _SaveCardBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(19, 22, 19, 15),
      decoration: const BoxDecoration(
        color: FretColors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E3E8))),
      ),
      child: SizedBox(
        height: 53,
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).maybePop(),
          style: ElevatedButton.styleFrom(
            elevation: 10,
            shadowColor: const Color(0x33080A73),
            backgroundColor: _EditCardDataPageState._primaryBlue,
            foregroundColor: FretColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Salvar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.check_circle_outline_rounded, size: 21),
            ],
          ),
        ),
      ),
    );
  }
}
