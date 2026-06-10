import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/design_system/design_system.dart';
import 'register_shared_widgets.dart';

const String _weakPasswordMessage =
    'A senha deve ter no mínimo 8 caracteres, 1 maiúscula, 1 minúscula, 1 número e 1 caractere especial.';

class RegisterStepTwo extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final AutovalidateMode autovalidateMode;
  final TextEditingController cpfController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;
  final VoidCallback onContinue;

  const RegisterStepTwo({
    super.key,
    required this.formKey,
    required this.autovalidateMode,
    required this.cpfController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
    required this.onContinue,
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
          title: 'Insira seus dados',
          subtitle: 'Preencha as informações abaixo para continuar',
        ),
        const SizedBox(height: 26),
        const RegisterInputLabel(text: 'CPF'),
        const SizedBox(height: 6),
        RegisterInputField(
          controller: cpfController,
          hintText: 'Digite seu CPF sem pontuação',
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          inputFormatters: const [_CpfInputFormatter()],
          validator: _validateCpf,
        ),
        const SizedBox(height: 18),
        const RegisterInputLabel(text: 'EMAIL'),
        const SizedBox(height: 6),
        RegisterInputField(
          controller: emailController,
          hintText: 'Digite seu email',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          validator: _validateEmail,
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: FretColors.neutral100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: FretColors.neutral200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const RegisterInputLabel(text: 'SENHA'),
              const SizedBox(height: 6),
              RegisterInputField(
                controller: passwordController,
                hintText: 'Digite uma senha',
                obscureText: obscurePassword,
                textInputAction: TextInputAction.next,
                validator: _validatePassword,
                suffixIcon: IconButton(
                  onPressed: onTogglePassword,
                  icon: Icon(
                    obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: FretColors.neutral500,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const RegisterInputLabel(text: 'CONFIRMAÇÃO DE SENHA'),
              const SizedBox(height: 6),
              RegisterInputField(
                controller: confirmPasswordController,
                hintText: 'Digite novamente sua senha',
                obscureText: obscureConfirmPassword,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => onContinue(),
                validator: (value) => _validateConfirmPassword(
                  value,
                  passwordController.text,
                ),
                suffixIcon: IconButton(
                  onPressed: onToggleConfirmPassword,
                  icon: Icon(
                    obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: FretColors.neutral500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        FretPrimaryGradientButton(
          label: 'Próximo',
          onPressed: onContinue,
        ),
        const SizedBox(height: 18),
        // const RegisterInfoBanner(
        //   icon: Icons.lock,
        //   iconColor: FretColors.secondaryVariation500,
        //   text: 'Seus dados estão protegidos sob nossa infraestrutura de segurança bancária e criptografia de ponta a ponta.',
        // ),
        ],
      ),
    );
  }
}

class _CpfInputFormatter extends TextInputFormatter {
  const _CpfInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final String limitedDigits = digits.length > 11
        ? digits.substring(0, 11)
        : digits;
    final String formatted = _formatCpfDigits(limitedDigits);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatCpfDigits(String digits) {
    final StringBuffer buffer = StringBuffer();

    for (int index = 0; index < digits.length; index += 1) {
      if (index == 3 || index == 6) {
        buffer.write('.');
      }
      if (index == 9) {
        buffer.write('-');
      }
      buffer.write(digits[index]);
    }

    return buffer.toString();
  }
}

String? _validateCpf(String? value) {
  final String digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) {
    return 'Informe seu CPF.';
  }
  if (!_isValidCpf(digits)) {
    return 'Informe um CPF válido com 11 dígitos.';
  }

  return null;
}

bool _isValidCpf(String cpf) {
  if (cpf.length != 11 || RegExp(r'^(\d)\1*$').hasMatch(cpf)) {
    return false;
  }

  final int firstDigit = _calculateCpfDigit(cpf.substring(0, 9), 10);
  final int secondDigit = _calculateCpfDigit(cpf.substring(0, 10), 11);

  return cpf.endsWith('$firstDigit$secondDigit');
}

int _calculateCpfDigit(String digits, int startWeight) {
  var total = 0;
  for (var index = 0; index < digits.length; index += 1) {
    total += int.parse(digits[index]) * (startWeight - index);
  }

  final int remainder = (total * 10) % 11;
  return remainder == 10 ? 0 : remainder;
}

String? _validateEmail(String? value) {
  final String trimmedValue = (value ?? '').trim();
  if (trimmedValue.isEmpty) {
    return 'Informe seu email.';
  }

  final bool validEmail = RegExp(
    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
  ).hasMatch(trimmedValue);

  if (!validEmail) {
    return 'Informe um email válido.';
  }

  return null;
}

String? _validatePassword(String? value) {
  final String password = value ?? '';
  if (password.isEmpty) {
    return 'Informe uma senha.';
  }
  if (!_isStrongPassword(password)) {
    return _weakPasswordMessage;
  }

  return null;
}

bool _isStrongPassword(String password) {
  return password.length >= 8 &&
      RegExp(r'[A-Z]').hasMatch(password) &&
      RegExp(r'[a-z]').hasMatch(password) &&
      RegExp(r'\d').hasMatch(password) &&
      RegExp(r'[^A-Za-z0-9\s]').hasMatch(password);
}

String? _validateConfirmPassword(String? value, String password) {
  final String confirmation = value ?? '';
  if (confirmation.isEmpty) {
    return 'Confirme sua senha.';
  }
  if (confirmation != password) {
    return 'A confirmação de senha não confere.';
  }

  return null;
}
