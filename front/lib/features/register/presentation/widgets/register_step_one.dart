import 'package:flutter/material.dart';
import '../../../../app/design_system/design_system.dart';
import '../../../../core/enums/register_account_type.dart';
import 'register_shared_widgets.dart';

class RegisterStepOne extends StatelessWidget {
  final UserTypeEnum? selectedType;
  final ValueChanged<UserTypeEnum> onTypeSelected;
  const RegisterStepOne({
    super.key,
    required this.selectedType,
    required this.onTypeSelected,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const RegisterSectionTitle(
        title: 'Você é motorista ou cliente?',
        subtitle: 'Escolha como você vai usar o app',
      ),
      const SizedBox(height: 28),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _AccountTypeOptionCard(
              icon: Icons.local_shipping_outlined,
              title: 'MOTORISTA',
              description: 'Quero realizar fretes',
              selected: selectedType == UserTypeEnum.driver,
              onTap: () => onTypeSelected(UserTypeEnum.driver),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _AccountTypeOptionCard(
              icon: Icons.person_outline_rounded,
              title: 'CLIENTE',
              description: 'Quero solicitar fretes',
              selected: selectedType == UserTypeEnum.client,
              onTap: () => onTypeSelected(UserTypeEnum.client),
            ),
          ),
        ],
      ),
      const SizedBox(height: 24),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: FretColors.screenGold.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: FretColors.screenGold.withValues(alpha: .18),
          ),
        ),
        child: const Text(
          'Você poderá acessar recursos específicos do seu perfil após concluir o cadastro.',
          style: TextStyle(fontSize: 11, height: 1.5, color: Color(0xFF806515)),
        ),
      ),
    ],
  );
}

class _AccountTypeOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;
  const _AccountTypeOptionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: FretColors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: BorderSide(
        color: selected ? FretColors.screenGold : FretColors.screenBorder,
      ),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 22, 10, 18),
        child: Column(
          children: [
            FretIconBox(
              icon: icon,
              size: 62,
              radius: 18,
              iconSize: 26,
              backgroundColor: FretColors.screenDark,
              iconColor: FretColors.screenGold,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: FretColors.screenDark,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10.5,
                height: 1.4,
                color: FretColors.screenMuted,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
