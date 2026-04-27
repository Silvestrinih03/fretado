import 'package:flutter/material.dart';

import '../../../../app/design_system/design_system.dart';
import 'register_shared_widgets.dart';

class RegisterStepTwo extends StatelessWidget {
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const RegisterSectionTitle(
          title: 'Insira seus dados',
          subtitle: 'Preencha as informações abaixo para continuar',
        ),
        const SizedBox(height: 48),
        const RegisterInputLabel(text: 'CPF'),
        const SizedBox(height: 10),
        RegisterInputField(
          controller: cpfController,
          hintText: 'Digite seu CPF sem pontuação',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 28),
        const RegisterInputLabel(text: 'EMAIL'),
        const SizedBox(height: 10),
        RegisterInputField(
          controller: emailController,
          hintText: 'Digite seu email',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 30),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
          decoration: BoxDecoration(
            color: FretColors.neutral100,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: FretColors.neutral200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const RegisterInputLabel(text: 'SENHA'),
              const SizedBox(height: 10),
              RegisterInputField(
                controller: passwordController,
                hintText: 'Digite uma senha',
                obscureText: obscurePassword,
                suffixIcon: IconButton(
                  onPressed: onTogglePassword,
                  icon: Icon(
                    obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: FretColors.neutral500,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const RegisterInputLabel(text: 'CONFIRMAÇÃO DE SENHA'),
              const SizedBox(height: 10),
              RegisterInputField(
                controller: confirmPasswordController,
                hintText: 'Digite novamente sua senha',
                obscureText: obscureConfirmPassword,
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
        const SizedBox(height: 30),
        FretPrimaryGradientButton(
          label: 'Próximo',
          onPressed: onContinue,
        ),
        const SizedBox(height: 26),
        // const RegisterInfoBanner(
        //   icon: Icons.lock,
        //   iconColor: FretColors.secondaryVariation500,
        //   text: 'Seus dados estão protegidos sob nossa infraestrutura de segurança bancária e criptografia de ponta a ponta.',
        // ),
      ],
    );
  }
}
