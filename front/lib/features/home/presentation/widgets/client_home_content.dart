import 'package:flutter/material.dart';

import '../../../../app/design_system/design_system.dart';

class ClientHomeContent extends StatelessWidget {
  final String userName;

  const ClientHomeContent({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
      children: [
        Text(
          'Olá, $userName!',
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w800,
            color: FretColors.loginFooterLink,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Esta é a Home do cliente (placeholder).',
          style: TextStyle(fontSize: 20, color: FretColors.neutral700),
        ),
        const SizedBox(height: 22),
        const _ClientPlaceholderCard(
          icon: Icons.confirmation_number_outlined,
          title: 'Próxima viagem',
          subtitle: 'Terminal A • 08:10',
        ),
        const SizedBox(height: 12),
        const _ClientPlaceholderCard(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Carteira',
          subtitle: 'Saldo disponível: R\$ 320,00',
        ),
        const SizedBox(height: 12),
        const _ClientPlaceholderCard(
          icon: Icons.history,
          title: 'Histórico de corridas',
          subtitle: 'Últimas viagens e recibos',
        ),
        const SizedBox(height: 12),
        const _ClientPlaceholderCard(
          icon: Icons.support_agent,
          title: 'Central de ajuda',
          subtitle: 'Fale com suporte e consulte FAQs',
        ),
      ],
    );
  }
}

class _ClientPlaceholderCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ClientPlaceholderCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: FretColors.neutral050,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FretColors.neutral200),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: FretColors.primary100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: FretColors.loginFooterLink),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: FretColors.loginFooterLink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 16,
                    color: FretColors.neutral700,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: FretColors.neutral500),
        ],
      ),
    );
  }
}
