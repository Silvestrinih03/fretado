import 'package:flutter/material.dart';

import '../../../../app/design_system/design_system.dart';
import 'shipping_payment_page.dart';

class ShippingResumePage extends StatelessWidget {
  const ShippingResumePage({super.key});

  static const Color _primaryBlue = Color(0xFF080A73);
  static const Color _orange = Color(0xFFB45C00);
  static const Color _screenBackground = Color(0xFFF7F8FA);
  static const Color _mutedText = Color(0xFF3F4050);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _screenBackground,
      body: SafeArea(
        child: Column(
          children: [
            const _ResumeHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(8, 20, 8, 18),
                children: const [
                  _BackLink(),
                  SizedBox(height: 16),
                  _StepLabel(),
                  SizedBox(height: 8),
                  Text(
                    'Resumo da Solicitação',
                    style: TextStyle(
                      color: FretColors.neutral900,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 16),
                  _RouteSummaryCard(),
                  SizedBox(height: 16),
                  _CargoSpecsCard(),
                  SizedBox(height: 20),
                  _PriceConfirmationCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumeHeader extends StatelessWidget {
  const _ResumeHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 38,
      decoration: const BoxDecoration(
        color: FretColors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE8E9EF))),
      ),
      child: Row(
        children: [
          const SizedBox(width: 2),
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: ShippingResumePage._primaryBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: 2),
          const Text(
            'Resumo da Solicitação',
            style: TextStyle(
              color: ShippingResumePage._primaryBlue,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _BackLink extends StatelessWidget {
  const _BackLink();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).maybePop(),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.arrow_back_rounded,
            color: ShippingResumePage._primaryBlue,
            size: 18,
          ),
          SizedBox(width: 4),
          Text(
            'Voltar',
            style: TextStyle(
              color: ShippingResumePage._primaryBlue,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepLabel extends StatelessWidget {
  const _StepLabel();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'ETAPA 3 DE 4',
      style: TextStyle(
        color: ShippingResumePage._orange,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    );
  }
}

class _RouteSummaryCard extends StatelessWidget {
  const _RouteSummaryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: FretColors.white,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _SectionTitle(
            icon: Icons.alt_route_rounded,
            title: 'Rota Confirmada',
          ),
          SizedBox(height: 14),
          _RouteStop(
            label: 'ORIGEM (COLETA)',
            address: 'Rua das Indústrias, 1045',
            district: 'Galpão 3 - Guarulhos, SP',
            isOrigin: true,
          ),
          _RouteStop(
            label: 'DESTINO (ENTREGA)',
            address: 'Av. Rio Branco, 89',
            district: 'Centro - Rio de Janeiro, RJ',
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: ShippingResumePage._orange, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: ShippingResumePage._primaryBlue,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _RouteStop extends StatelessWidget {
  final String label;
  final String address;
  final String district;
  final bool isOrigin;

  const _RouteStop({
    required this.label,
    required this.address,
    required this.district,
    this.isOrigin = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color dotColor = isOrigin
        ? ShippingResumePage._orange
        : ShippingResumePage._primaryBlue;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 22,
          child: Column(
            children: [
              const SizedBox(height: 4),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.circle,
                  color: FretColors.white,
                  size: 4,
                ),
              ),
              if (isOrigin)
                const SizedBox(
                  width: 1,
                  height: 42,
                  child: CustomPaint(painter: _DottedRouteLinePainter()),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isOrigin ? 9 : 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF747682),
                    fontSize: 7,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  address,
                  style: const TextStyle(
                    color: FretColors.neutral900,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  district,
                  style: const TextStyle(
                    color: ShippingResumePage._mutedText,
                    fontSize: 9,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DottedRouteLinePainter extends CustomPainter {
  const _DottedRouteLinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color(0xFFE1E2E7)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;

    double y = 5;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(0, y + 2), paint);
      y += 6;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CargoSpecsCard extends StatelessWidget {
  const _CargoSpecsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: FretColors.white,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _SectionTitle(
            icon: Icons.inventory_2_outlined,
            title: 'Especificações da Carga',
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SpecTile(
                  icon: Icons.scale_outlined,
                  label: 'PESO APROX.',
                  value: '350 kg',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _SpecTile(
                  icon: Icons.straighten_rounded,
                  label: 'VOLUME',
                  value: '4.5 m³',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpecTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SpecTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.fromLTRB(10, 10, 8, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F8),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF565867), size: 14),
          const Spacer(),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF747682),
              fontSize: 7,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: FretColors.neutral900,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceConfirmationCard extends StatelessWidget {
  const _PriceConfirmationCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 38, 20, 26),
      decoration: BoxDecoration(
        color: ShippingResumePage._primaryBlue,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          RichText(
            text: const TextSpan(
              style: TextStyle(color: FretColors.white),
              children: [
                TextSpan(
                  text: 'R\$ ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                TextSpan(
                  text: '150',
                  style: TextStyle(
                    fontSize: 43,
                    fontWeight: FontWeight.w900,
                    height: 0.9,
                  ),
                ),
                TextSpan(
                  text: ',00',
                  style: TextStyle(
                    color: Color(0xFFAEB2E2),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Divider(height: 1, color: Color(0x1FFFFFFF)),
          const SizedBox(height: 22),
          const Text(
            'Deseja prosseguir com a\nsolicitação?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: FretColors.white,
              fontSize: 13,
              height: 1.2,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),
          const _PrimaryActionButton(),
          const SizedBox(height: 8),
          const _CancelActionButton(),
        ],
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 37,
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const ShippingPaymentPage(),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: ShippingResumePage._orange,
          foregroundColor: FretColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Sim, continuar',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(width: 6),
            Icon(Icons.check_circle_outline_rounded, size: 13),
          ],
        ),
      ),
    );
  }
}

class _CancelActionButton extends StatelessWidget {
  const _CancelActionButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 36,
      child: OutlinedButton(
        onPressed: () => Navigator.of(context).maybePop(),
        style: OutlinedButton.styleFrom(
          foregroundColor: FretColors.white,
          side: const BorderSide(color: Color(0xFF3133AA)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        child: const Text(
          'Não, cancelar',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
