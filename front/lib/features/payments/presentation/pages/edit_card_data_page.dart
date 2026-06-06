import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/design_system/design_system.dart';
import '../../../../core/services/http_service.dart';
import '../../../../core/services/myself/services/myself_service.dart';
import '../../data/datasources/user_card_datasource.dart';
import '../../data/repositories/user_card_repository_impl.dart';
import '../stores/payment_cards_store.dart';

class EditCardDataPage extends StatefulWidget {
  final int? userId;

  const EditCardDataPage({super.key, this.userId});

  @override
  State<EditCardDataPage> createState() => _EditCardDataPageState();
}

class _EditCardDataPageState extends State<EditCardDataPage> {
  static const Color _primaryBlue = Color(0xFF080A73);
  static const Color _screenBackground = Color(0xFFF7F8FA);
  static const Color _fieldBackground = Color(0xFFE8E8EA);
  static const Color _mutedText = Color(0xFF3F4050);
  static const Color _hintText = Color(0xFFAEB0BA);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cardNameController = TextEditingController();
  final TextEditingController _expirationController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();

  late final HttpService _httpService;
  late final PaymentCardsStore _store;
  bool _isDefault = true;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

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
    _cardNameController.addListener(_refreshPreview);
    _expirationController.addListener(_refreshPreview);
  }

  @override
  void dispose() {
    _store.dispose();
    _httpService.dispose();
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
    return AnimatedBuilder(
      animation: _store,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: _screenBackground,
          body: SafeArea(
            child: Column(
              children: [
                const _EditCardHeader(),
                Expanded(
                  child: Form(
                    key: _formKey,
                    autovalidateMode: _autovalidateMode,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(19, 30, 19, 22),
                      children: [
                      _CreditCardPreview(
                        holderName: _cardNameController.text,
                        expiration: _expirationController.text,
                      ),
                      const SizedBox(height: 34),
                      _CardInputField(
                        label: 'Numero do cartao',
                        hintText: '0000 0000 0000 0000',
                        controller: _cardNumberController,
                        keyboardType: TextInputType.number,
                        suffixIcon: Icons.credit_card_rounded,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(19),
                        ],
                        textInputAction: TextInputAction.next,
                        validator: _validateCardNumber,
                      ),
                      const SizedBox(height: 24),
                      _CardInputField(
                        label: 'Nome no cartao',
                        hintText: 'COMO IMPRESSO NO CARTAO',
                        controller: _cardNameController,
                        textCapitalization: TextCapitalization.characters,
                        textInputAction: TextInputAction.next,
                        validator: _validateCardName,
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
                              textInputAction: TextInputAction.next,
                              validator: _validateExpiration,
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
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _saveCard(),
                              validator: _validateCvv,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 21),
                      _DefaultCardSwitch(
                        value: _isDefault,
                        onChanged: (value) {
                          setState(() {
                            _isDefault = value;
                          });
                        },
                      ),
                      ],
                    ),
                  ),
                ),
                _SaveCardBar(
                  isSaving: _store.isSaving,
                  onPressed: _saveCard,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveCard() async {
    FocusScope.of(context).unfocus();

    final bool isFormValid = _formKey.currentState?.validate() ?? false;
    if (!isFormValid) {
      setState(() {
        _autovalidateMode = AutovalidateMode.onUserInteraction;
      });
      return;
    }

    final didSave = await _store.createCard(
      cardholderName: _cardNameController.text,
      cardNumber: _cardNumberController.text,
      expiration: _expirationController.text,
      cvv: _cvvController.text,
      isDefault: _isDefault,
    );

    if (!mounted) {
      return;
    }

    if (didSave) {
      Navigator.of(context).pop(true);
      return;
    }

    showFretErrorPopup(
      context,
      message: _store.saveErrorMessage ?? 'Nao foi possivel salvar.',
    );
  }

  void _refreshPreview() {
    setState(() {});
  }
}

String? _validateCardNumber(String? value) {
  final String digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) {
    return 'Informe o número do cartão.';
  }
  if (digits.length < 13 || digits.length > 19) {
    return 'Informe um número de cartão válido.';
  }

  return null;
}

String? _validateCardName(String? value) {
  if ((value ?? '').trim().isEmpty) {
    return 'Informe o nome impresso no cartão.';
  }

  return null;
}

String? _validateExpiration(String? value) {
  final String digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) {
    return 'Informe a validade.';
  }
  if (digits.length != 4) {
    return 'Use o formato MM/AA.';
  }

  final int month = int.parse(digits.substring(0, 2));
  if (month < 1 || month > 12) {
    return 'Informe um mês válido.';
  }

  return null;
}

String? _validateCvv(String? value) {
  final String digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) {
    return 'Informe o CVV.';
  }
  if (digits.length < 3 || digits.length > 4) {
    return 'Informe um CVV válido.';
  }

  return null;
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
            'Dados do cartao',
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
    final displayName = holderName.trim().isEmpty
        ? 'SEU NOME AQUI'
        : holderName.trim().toUpperCase();
    final displayExpiration = expiration.trim().isEmpty
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
    final digits = value.replaceAll(RegExp(r'\D'), '');
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
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;

  const _CardInputField({
    required this.label,
    required this.hintText,
    required this.controller,
    this.keyboardType,
    this.suffixIcon,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
    this.textInputAction,
    this.onFieldSubmitted,
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
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 50),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            textCapitalization: textCapitalization,
            validator: validator,
            textInputAction: textInputAction,
            onFieldSubmitted: onFieldSubmitted,
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

class _DefaultCardSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _DefaultCardSwitch({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: FretColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E3E8)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Definir como cartao padrao',
              style: TextStyle(
                color: _EditCardDataPageState._mutedText,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: _EditCardDataPageState._primaryBlue,
          ),
        ],
      ),
    );
  }
}

class _SaveCardBar extends StatelessWidget {
  final bool isSaving;
  final VoidCallback onPressed;

  const _SaveCardBar({
    required this.isSaving,
    required this.onPressed,
  });

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
          onPressed: isSaving ? null : onPressed,
          style: ElevatedButton.styleFrom(
            elevation: 10,
            shadowColor: const Color(0x33080A73),
            backgroundColor: _EditCardDataPageState._primaryBlue,
            foregroundColor: FretColors.white,
            disabledBackgroundColor: const Color(0xFFB7B9D5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: isSaving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation<Color>(FretColors.white),
                  ),
                )
              : const Row(
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
