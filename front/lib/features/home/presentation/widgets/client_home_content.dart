import 'package:flutter/material.dart';

import '../../../../app/design_system/design_system.dart';
import '../../../shipping_request/presentation/pages/address_map_page.dart';

class ClientHomeContent extends StatelessWidget {
  final String userName;
  final int userId;

  const ClientHomeContent({
    super.key,
    required this.userName,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final String greetingName = userName.trim().isEmpty ? 'Cliente' : userName;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 0, 18),
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Olá, $greetingName!',
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: FretColors.loginFooterLink,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Para onde vamos hoje? Encontre fretes rápidos e seguros.',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF656671),
                ),
              ),
              const SizedBox(height: 20),
              _FreightRequestCard(userId: userId),
              const SizedBox(height: 22),
              const _FreightsSectionHeader(),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 226,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(right: 16),
            itemCount: _freights.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final freight = _freights[index];

              return _FreightProgressCard(freight: freight);
            },
          ),
        ),
      ],
    );
  }
}

class _FreightRequestCard extends StatelessWidget {
  final int userId;

  const _FreightRequestCard({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        color: const Color(0xFF080A73),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14080A73),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Solicitação de frete',
            style: TextStyle(
              color: FretColors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Precisando de alguém para transportar um produto? Nós fretamos para você',
            style: TextStyle(
              color: Color(0xFFE2E5FF),
              fontSize: 15,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => AddressMapPage(userId: userId),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: const Color(0xFFFFE16D),
                foregroundColor: const Color(0xFF080A73),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'SOLICITAR AGORA',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FreightsSectionHeader extends StatelessWidget {
  const _FreightsSectionHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Fretes em Andamento',
            maxLines: 2,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: FretColors.loginFooterLink,
            ),
          ),
        ),
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            foregroundColor: FretColors.secondaryVariation700,
            padding: EdgeInsets.zero,
          ),
          child: const Text(
            'VER TODOS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _FreightProgressCard extends StatelessWidget {
  final _FreightPreview freight;

  const _FreightProgressCard({required this.freight});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: FretColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatusPill(label: freight.status),
              const Spacer(),
              Text(
                freight.code,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF4C4B55),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _RouteLine(origin: freight.origin, destination: freight.destination),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE8E8EC)),
          const SizedBox(height: 10),
          _FreightInfo(
            icon: freight.infoIcon,
            label: freight.infoLabel,
            value: freight.infoValue,
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;

  const _StatusPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF4EDC8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF3D3312),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _RouteLine extends StatelessWidget {
  final String origin;
  final String destination;

  const _RouteLine({
    required this.origin,
    required this.destination,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _RoutePoint(
          color: FretColors.secondaryVariation700,
          text: origin,
          showConnector: true,
        ),
        _RoutePoint(
          color: FretColors.loginFooterLink,
          text: destination,
        ),
      ],
    );
  }
}

class _RoutePoint extends StatelessWidget {
  final Color color;
  final String text;
  final bool showConnector;

  const _RoutePoint({
    required this.color,
    required this.text,
    this.showConnector = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 20,
          child: Column(
            children: [
              const SizedBox(height: 6),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              if (showConnector)
                Container(
                  width: 1,
                  height: 24,
                  color: const Color(0xFFE0E2EA),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: showConnector ? 22 : 0),
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: FretColors.neutral900,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FreightInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _FreightInfo({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF0F2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF5E606A), size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  letterSpacing: 0,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF5E606A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: FretColors.neutral900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FreightPreview {
  final String code;
  final String status;
  final String origin;
  final String destination;
  final IconData infoIcon;
  final String infoLabel;
  final String infoValue;

  const _FreightPreview({
    required this.code,
    required this.status,
    required this.origin,
    required this.destination,
    required this.infoIcon,
    required this.infoLabel,
    required this.infoValue,
  });
}

const List<_FreightPreview> _freights = [
  _FreightPreview(
    code: '#FR-8921',
    status: 'A CAMINHO',
    origin: 'Indaiatuba, SP',
    destination: 'São Paulo, SP',
    infoIcon: Icons.person_outline_rounded,
    infoLabel: 'MOTORISTA',
    infoValue: 'Marcos Oliveira',
  ),
  _FreightPreview(
    code: '#FR-8840',
    status: 'COLETA',
    origin: 'Campinas, SP',
    destination: 'Santos, SP',
    infoIcon: Icons.local_shipping_outlined,
    infoLabel: 'VEICULO',
    infoValue: 'Truck baú',
  ),
];
