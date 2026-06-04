import 'package:flutter/material.dart';

import '../../../../app/design_system/design_system.dart';
import '../../../driver_operations/presentation/pages/driver_operations_page.dart';
import '../../../documents/presentation/pages/my_documents.dart';
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      children: [
        Text(
          'Ola, $firstName!',
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: FretColors.loginFooterLink,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Gerencie suas viagens, veiculos e documentos aqui.',
          style: TextStyle(fontSize: 15, color: FretColors.neutral700),
        ),
        const SizedBox(height: 14),
        _BalanceCard(
          onTap: () => _openOperations(context, initialTabIndex: 2),
        ),
        const SizedBox(height: 10),
        _SimpleMetricCard(
          icon: Icons.inbox_outlined,
          title: 'Ofertas de corrida',
          subtitle: 'Aceitar ou recusar ofertas pendentes',
          onTap: () => _openOperations(context),
        ),
        const SizedBox(height: 10),
        _SimpleMetricCard(
          icon: Icons.route_outlined,
          title: 'Minhas corridas',
          subtitle: 'Ver corridas vinculadas ao motorista',
          onTap: () => _openOperations(context, initialTabIndex: 1),
        ),
        const SizedBox(height: 10),
        _SimpleMetricCard(
          icon: Icons.local_shipping_rounded,
          title: 'Meus veiculos',
          subtitle: 'Gerenciar meus veiculos',
          barColor: FretColors.loginFooterLink,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => MyVehiclesPage(userId: userId),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        _SimpleMetricCard(
          icon: Icons.description_outlined,
          title: 'Meus documentos',
          subtitle: 'Acompanhar validade da CNH',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => MyDocumentsPage(userId: userId),
              ),
            );
          },
        ),
      ],
    );
  }

  void _openOperations(BuildContext context, {int initialTabIndex = 0}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DriverOperationsPage(
          userId: userId,
          initialTabIndex: initialTabIndex,
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final VoidCallback onTap;

  const _BalanceCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              colors: [Color(0xFF1B2397), Color(0xFF151E8C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: FretColors.loginFooterLink.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'CARTEIRA DO MOTORISTA',
                    style: TextStyle(
                      color: Color(0xFFD1D5FF),
                      letterSpacing: 0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Spacer(),
                  Icon(Icons.account_balance_wallet, color: Color(0xFFAFB6F3)),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'Ver saldo',
                style: TextStyle(
                  color: FretColors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 10),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0xFF313CA3),
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Text(
                        'Saldo, historico e saque',
                        style: TextStyle(
                          color: FretColors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      Spacer(),
                      Icon(Icons.arrow_forward_rounded, color: FretColors.white),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: FretColors.neutral050,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: FretColors.neutral200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: FretColors.neutral100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: FretColors.loginFooterLink),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: FretColors.loginFooterLink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: FretColors.neutral700,
                ),
              ),
              const SizedBox(height: 8),
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
