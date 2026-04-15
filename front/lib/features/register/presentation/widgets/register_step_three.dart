import 'package:flutter/material.dart';

import '../../../../app/design_system/design_system.dart';
import 'register_shared_widgets.dart';

class RegisterStepThree extends StatelessWidget {
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController birthDateController;
  final TextEditingController phoneController;
  final VoidCallback onFinish;
  final bool isLoading;

  const RegisterStepThree({
    super.key,
    required this.firstNameController,
    required this.lastNameController,
    required this.birthDateController,
    required this.phoneController,
    required this.onFinish,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const RegisterSectionTitle(
          title: 'Finalize seu cadastro',
          subtitle: 'Preencha seus dados pessoais para finalizar.',
          titleColor: FretColors.loginFooterLink,
        ),
        const SizedBox(height: 34),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
          decoration: BoxDecoration(
            color: FretColors.neutral050,
            borderRadius: BorderRadius.circular(20),
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
                        hintText: 'Ex: João',
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _LabeledInput(
                      label: 'Sobrenome',
                      child: RegisterInputField(
                        controller: lastNameController,
                        hintText: 'Ex: Silva',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              _LabeledInput(
                label: 'Data de nascimento',
                child: RegisterInputField(
                  controller: birthDateController,
                  hintText: 'DD/MM/AAAA',
                  keyboardType: TextInputType.datetime,
                  suffixIcon: const Padding(
                    padding: EdgeInsetsDirectional.only(end: 14),
                    child: Icon(
                      Icons.calendar_today_outlined,
                      color: FretColors.neutral500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              _LabeledInput(
                label: 'Telefone de contato',
                child: RegisterInputField(
                  controller: phoneController,
                  hintText: '(00) 0000-0000',
                  keyboardType: TextInputType.phone,
                  suffixIcon: const Padding(
                    padding: EdgeInsetsDirectional.only(end: 14),
                    child: Icon(
                      Icons.call_outlined,
                      color: FretColors.neutral500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              FretPrimaryGradientButton(
                label: isLoading ? 'Finalizando...' : 'Finalizar cadastro',
                onPressed: onFinish,
              ),
              const SizedBox(height: 22),
              RichText(
                textAlign: TextAlign.center,
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 18,
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
    );
  }
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
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: FretColors.neutral700,
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}
