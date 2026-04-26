import 'package:flutter/material.dart';

import '../../../../app/design_system/design_system.dart';
import '../../../../core/enums/register_account_type.dart';
import 'register_shared_widgets.dart';

class RegisterStepOne extends StatelessWidget {
  final RegisterAccountType? selectedType;
  final ValueChanged<RegisterAccountType> onTypeSelected;

  const RegisterStepOne({
    super.key,
    required this.selectedType,
    required this.onTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 18),
        const RegisterSectionTitle(
          title: 'Você é \nmotorista ou cliente?',
          subtitle: 'Escolha como você vai usar o app',
        ),
        const SizedBox(height: 50),
        Row(
          children: [
            Expanded(
              child: _AccountTypeOptionCard(
                imageIcon: Icons.local_shipping_outlined,
                title: 'Sou',
                subtitle: 'MOTORISTA',
                selected: selectedType == RegisterAccountType.driver,
                onTap: () => onTypeSelected(RegisterAccountType.driver),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _AccountTypeOptionCard(
                imageIcon: Icons.person_outline,
                title: 'Sou',
                subtitle: 'CLIENTE',
                selected: selectedType == RegisterAccountType.client,
                onTap: () => onTypeSelected(RegisterAccountType.client),
              ),
            ),
          ],
        ),
        const SizedBox(height: 54),
        // const RegisterInfoBanner(
        //   icon: Icons.info,
        //   text: 'Você poderá alterar o tipo de perfil mais tarde nas configurações.',
        // ),
      ],
    );
  }
}

class _AccountTypeOptionCard extends StatelessWidget {
  final IconData imageIcon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _AccountTypeOptionCard({
    required this.imageIcon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 168,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: FretColors.neutral300,
              border: Border.all(
                color: selected ? FretColors.loginFooterLink : FretColors.neutral200,
                width: selected ? 3 : 1,
              ),
            ),
            child: Center(
              child: Icon(
                imageIcon,
                size: 58,
                color: FretColors.neutral700,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: FretColors.neutral900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: FretColors.loginFooterLink,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
