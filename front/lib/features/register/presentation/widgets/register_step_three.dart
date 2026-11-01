import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/design_system/design_system.dart';
import 'register_shared_widgets.dart';

class RegisterStepThree extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final AutovalidateMode autovalidateMode;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController birthDateController;
  final TextEditingController phoneController;
  final VoidCallback onFinish;
  final bool isLoading;
  final bool isDriver;

  const RegisterStepThree({
    super.key,
    required this.formKey,
    required this.autovalidateMode,
    required this.firstNameController,
    required this.lastNameController,
    required this.birthDateController,
    required this.phoneController,
    required this.onFinish,
    this.isLoading = false,
    this.isDriver = false,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      autovalidateMode: autovalidateMode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const RegisterSectionTitle(
            title: 'Finalize seu cadastro',
            subtitle: 'Conte um pouco sobre você para finalizar.',
            titleColor: FretColors.screenDark,
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            decoration: BoxDecoration(
              color: FretColors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: FretColors.screenBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _LabeledInput(
                        label: 'Nome',
                        child: RegisterInputField(
                          controller: firstNameController,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          validator: (value) =>
                              _validateRequiredName(value, 'nome'),
                          hintText: 'Ex: João',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _LabeledInput(
                        label: 'Sobrenome',
                        child: RegisterInputField(
                          controller: lastNameController,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          validator: (value) =>
                              _validateRequiredName(value, 'sobrenome'),
                          hintText: 'Ex: Silva',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _LabeledInput(
                  label: 'Data de nascimento',
                  child: RegisterInputField(
                    controller: birthDateController,
                    hintText: 'DD/MM/AAAA',
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    validator: _validateRequiredBirthDate,
                    inputFormatters: const [_BirthDateInputFormatter()],
                    suffixIcon: const Padding(
                      padding: EdgeInsetsDirectional.only(end: 10),
                      child: Icon(
                        Icons.calendar_today_outlined,
                        color: FretColors.screenMuted,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _LabeledInput(
                  label: 'Telefone de contato',
                  child: RegisterInputField(
                    controller: phoneController,
                    hintText: '(00) 00000-0000',
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    inputFormatters: const [_PhoneInputFormatter()],
                    onFieldSubmitted: (_) => onFinish(),
                    validator: _validateRequiredPhone,
                    suffixIcon: const Padding(
                      padding: EdgeInsetsDirectional.only(end: 10),
                      child: Icon(
                        Icons.call_outlined,
                        color: FretColors.screenMuted,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                FretScreenButton(
                  label: isLoading ? 'Finalizando...' : 'Finalizar cadastro',
                  onPressed: onFinish,
                  icon: Icons.arrow_forward_rounded,
                ),
                const SizedBox(height: 14),
                RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 10.5,
                      height: 1.5,
                      color: FretColors.screenMuted,
                    ),
                    children: [
                      TextSpan(text: 'Ao finalizar, você concorda com nossos '),
                      TextSpan(
                        text: 'Termos de Uso',
                        style: TextStyle(color: FretColors.screenGold),
                      ),
                      TextSpan(text: ' e '),
                      TextSpan(
                        text: 'Privacidade',
                        style: TextStyle(color: FretColors.screenGold),
                      ),
                      TextSpan(text: '.'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isDriver) ...[
            const SizedBox(height: 12),
            const Text(
              'Depois, complete seus dados de veículo e CNH para receber corridas.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.5,
                height: 1.5,
                color: FretColors.screenMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BirthDateInputFormatter extends TextInputFormatter {
  const _BirthDateInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final String limitedDigits = digits.length > 8
        ? digits.substring(0, 8)
        : digits;
    final String formatted = _formatBirthDateDigits(limitedDigits);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatBirthDateDigits(String digits) {
    final StringBuffer buffer = StringBuffer();

    for (int index = 0; index < digits.length; index += 1) {
      if (index == 2 || index == 4) {
        buffer.write('/');
      }
      buffer.write(digits[index]);
    }

    return buffer.toString();
  }
}

class _PhoneInputFormatter extends TextInputFormatter {
  const _PhoneInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final String limitedDigits = digits.length > 11
        ? digits.substring(0, 11)
        : digits;
    final String formatted = _formatPhoneDigits(limitedDigits);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatPhoneDigits(String digits) {
    if (digits.isEmpty) {
      return '';
    }

    if (digits.length <= 2) {
      return '($digits';
    }

    final String areaCode = digits.substring(0, 2);
    final String number = digits.substring(2);

    if (number.length <= 4) {
      return '($areaCode) $number';
    }

    if (digits.length <= 10) {
      return '($areaCode) ${number.substring(0, 4)}-${number.substring(4)}';
    }

    return '($areaCode) ${number.substring(0, 5)}-${number.substring(5)}';
  }
}

String? _validateRequiredName(String? value, String fieldName) {
  if ((value ?? '').trim().isEmpty) {
    return 'Informe seu $fieldName.';
  }

  return null;
}

String? _validateRequiredBirthDate(String? value) {
  final String raw = (value ?? '').trim();
  if (raw.isEmpty) {
    return 'Informe sua data de nascimento.';
  }

  final String digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.length != 8) {
    return 'Informe a data no formato DD/MM/AAAA.';
  }

  final int day = int.parse(digits.substring(0, 2));
  final int month = int.parse(digits.substring(2, 4));
  final int year = int.parse(digits.substring(4, 8));
  final DateTime date = DateTime(year, month, day);

  final bool isValidDate =
      date.day == day && date.month == month && date.year == year;
  if (!isValidDate) {
    return 'Informe uma data válida.';
  }

  if (date.isAfter(DateTime.now())) {
    return 'A data de nascimento não pode ser futura.';
  }

  return null;
}

String? _validateRequiredPhone(String? value) {
  final String digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) {
    return 'Informe seu telefone.';
  }

  if (digits.length < 10 || digits.length > 11) {
    return 'Informe um telefone válido.';
  }

  return null;
}

class _LabeledInput extends StatelessWidget {
  final String label;
  final Widget child;

  const _LabeledInput({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            height: 1.2,
            fontWeight: FontWeight.w700,
            color: FretColors.screenDark,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
