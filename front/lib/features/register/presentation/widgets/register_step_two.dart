import 'package:flutter/material.dart';

import '../../../../app/design_system/design_system.dart';
import 'register_shared_widgets.dart';

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

String? _validateCpf(String? value) {
  final String digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) {
    return 'Informe seu CPF.';
  }
  if (digits.length != 11) {
    return 'Informe um CPF válido com 11 dígitos.';
  }

  return null;
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
  if (password.length < 8) {
    return 'A senha deve ter no mínimo 8 caracteres.';
  }

  return null;
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
