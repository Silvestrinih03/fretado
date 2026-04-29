import 'package:flutter/material.dart';

import '../../../../app/design_system/design_system.dart';
import '../../../vehicles/presentation/pages/my_vehicles.dart';

class DriverHomeContent extends StatelessWidget {
  final String firstName;
  final int userId;

  const DriverHomeContent({
    super.key,
    required this.firstName,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
      children: [
        Text(
          'Olá, $firstName!',
          style: const TextStyle(
            fontSize: 44,
            fontWeight: FontWeight.w800,
            color: FretColors.loginFooterLink,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Gerencie suas viagens, veículos e documentos aqui.',
          style: TextStyle(fontSize: 22, color: FretColors.neutral700),
        ),
        const SizedBox(height: 22),
        const _BalanceCard(),
        const SizedBox(height: 16),
        _SimpleMetricCard(
          icon: Icons.local_shipping_rounded,
          title: 'Meus veículos',
          subtitle: 'Gerenciar meus veículos',
          barColor: FretColors.loginFooterLink,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => MyVehiclesPage(userId: userId),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        const _SimpleMetricCard(
          icon: Icons.description_outlined,
          title: 'Meus documentos',
          subtitle: '3 pendências de renovação',
          urgencyTag: 'URGENTE',
          urgencyColor: Color(0xFFFFD9D9),
          urgencyTextColor: Color(0xFFB01212),
        ),
        const SizedBox(height: 22),
        const Row(
          children: [
            Text(
              'Minhas corridas',
              style: TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.w800,
                color: FretColors.loginFooterLink,
              ),
            ),
            Spacer(),
            Text(
              'Ver todas',
              style: TextStyle(
                color: FretColors.secondaryVariation700,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const _TripCard(
          title: 'Rota Industrial Sul',
          subtitle: 'Placa: ABC-1234 • Motorista: Carlos R.',
          statusLabel: 'EM CURSO',
          statusColor: Color(0xFFF4E8B7),
          sideColor: Color(0xFFD0A900),
          icon: Icons.route,
        ),
        const SizedBox(height: 10),
        const _TripCard(
          title: 'Transporte Executivo',
          subtitle: 'Hoje, 09:30 • Placa: XYZ-9876',
          statusLabel: 'FINALIZADA',
          statusColor: Color(0xFFE8EAF3),
          sideColor: FretColors.loginFooterLink,
          icon: Icons.check_circle,
        ),
        const SizedBox(height: 10),
        const _TripCard(
          title: 'Fretado Universitário',
          subtitle: 'Hoje, 18:45 • Placa: KJK-4421',
          statusLabel: 'AGENDADA',
          statusColor: Color(0xFFF1F1F3),
          sideColor: Color(0xFFBABDCA),
          icon: Icons.schedule,
        ),
        const SizedBox(height: 16),
        // const _TrafficCard(),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF1B2397), Color(0xFF151E8C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: FretColors.loginFooterLink.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text(
                'SALDO DISPONÍVEL',
                style: TextStyle(
                  color: Color(0xFFD1D5FF),
                  letterSpacing: 2,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Spacer(),
              Icon(Icons.account_balance_wallet, color: Color(0xFFAFB6F3)),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'R\$ 42.850,00',
            style: TextStyle(
              color: FretColors.white,
              fontSize: 54,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF313CA3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Text(
                  'Sacar valores',
                  style: TextStyle(
                    color: FretColors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                Spacer(),
                Icon(Icons.arrow_forward_rounded, color: FretColors.white),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleMetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? urgencyTag;
  final Color? urgencyColor;
  final Color? urgencyTextColor;
  final Color? barColor;
  final VoidCallback? onTap;

  const _SimpleMetricCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.urgencyTag,
    this.urgencyColor,
    this.urgencyTextColor,
    this.barColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: FretColors.neutral050,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: FretColors.neutral200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: FretColors.neutral100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: FretColors.loginFooterLink),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
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
              const SizedBox(height: 12),
              if (urgencyTag != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: urgencyColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    urgencyTag!,
                    style: TextStyle(
                      color: urgencyTextColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              if (barColor != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    height: 6,
                    color: FretColors.neutral200,
                    child: FractionallySizedBox(
                      widthFactor: 0.38,
                      alignment: Alignment.centerLeft,
                      child: Container(color: barColor),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String statusLabel;
  final Color statusColor;
  final Color sideColor;
  final IconData icon;

  const _TripCard({
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    required this.statusColor,
    required this.sideColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: FretColors.neutral050,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FretColors.neutral200),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 86,
            decoration: BoxDecoration(
              color: sideColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                bottomLeft: Radius.circular(14),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: FretColors.primary100,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: FretColors.loginFooterLink),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: FretColors.loginFooterLink,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                statusLabel,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: FretColors.neutral700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 14,
                            color: FretColors.neutral700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
