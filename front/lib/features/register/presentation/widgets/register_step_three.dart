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
          subtitle: 'Preencha seus dados pessoais para finalizar.',
          titleColor: FretColors.loginFooterLink,
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: FretColors.neutral050,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: FretColors.neutral200),
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
                  validator: _validateOptionalBirthDate,
                  inputFormatters: const [_BirthDateInputFormatter()],
                  suffixIcon: const Padding(
                    padding: EdgeInsetsDirectional.only(end: 10),
                    child: Icon(
                      Icons.calendar_today_outlined,
                      color: FretColors.neutral500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _LabeledInput(
                label: 'Telefone de contato',
                child: RegisterInputField(
                  controller: phoneController,
                  hintText: '(00) 0000-0000',
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => onFinish(),
                  validator: _validateOptionalPhone,
                  suffixIcon: const Padding(
                    padding: EdgeInsetsDirectional.only(end: 10),
                    child: Icon(
                      Icons.call_outlined,
                      color: FretColors.neutral500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              FretPrimaryGradientButton(
                label: isLoading ? 'Finalizando...' : 'Finalizar cadastro',
                onPressed: onFinish,
              ),
              const SizedBox(height: 14),
              RichText(
                textAlign: TextAlign.center,
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: FretColors.neutral700,
                  ),
                  children: [
                    TextSpan(text: 'Ao finalizar, você concorda com nossos '),
                    TextSpan(
                      text: 'Termos de Uso',
                      style: TextStyle(color: FretColors.secondaryVariation500),
                    ),
                    TextSpan(text: ' e '),
                    TextSpan(
                      text: 'Privacidade',
                      style: TextStyle(color: FretColors.secondaryVariation500),
                    ),
                    TextSpan(text: '.'),
                  ],
                ),
              ),
            ],
          ),
        ),
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

String? _validateRequiredName(String? value, String fieldName) {
  if ((value ?? '').trim().isEmpty) {
    return 'Informe seu $fieldName.';
  }

  return null;
}

String? _validateOptionalBirthDate(String? value) {
  final String raw = (value ?? '').trim();
  if (raw.isEmpty) {
    return null;
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

String? _validateOptionalPhone(String? value) {
  final String digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) {
    return null;
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
          label,
          style: const TextStyle(
            fontSize: 13,
            height: 1.2,
            fontWeight: FontWeight.w700,
            color: FretColors.neutral700,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
