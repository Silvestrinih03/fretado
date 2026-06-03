import 'package:flutter/material.dart';

import '../../../../app/design_system/design_system.dart';
import '../models/freight_address_data.dart';
import '../models/freight_package_data.dart';
import '../models/freight_quote_model.dart';
import 'shipping_payment_page.dart';

class ShippingResumePage extends StatelessWidget {
  final int userId;
  final FreightAddressData addressData;
  final FreightPackageData packageData;
  final FreightQuoteModel quote;

  const ShippingResumePage({
    super.key,
    required this.userId,
    required this.addressData,
    required this.packageData,
    required this.quote,
  });

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
                padding: const EdgeInsets.fromLTRB(10, 20, 10, 18),
                children: [
                  const _BackLink(),
                  const SizedBox(height: 16),
                  const _StepLabel(),
                  const SizedBox(height: 8),
                  const Text(
                    'Resumo da Solicitação',
                    style: TextStyle(
                      color: FretColors.neutral900,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _RouteSummaryCard(addressData: addressData),
                  const SizedBox(height: 14),
                  _CargoSpecsCard(
                    packageData: packageData,
                    quote: quote,
                  ),
                  const SizedBox(height: 14),
                  _RouteEstimateCard(quote: quote),
                  const SizedBox(height: 18),
                  _PriceConfirmationCard(
                    quote: quote,
                    onContinue: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ShippingPaymentPage(
                            userId: userId,
                            addressData: addressData,
                            packageData: packageData,
                            quote: quote,
                          ),
                        ),
                      );
                    },
                    onCancel: () => Navigator.of(context).maybePop(),
                  ),
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
      height: 47,
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
              size: 22,
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            'Resumo da Solicitação',
            style: TextStyle(
              color: ShippingResumePage._primaryBlue,
              fontSize: 14,
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
  final FreightAddressData addressData;

  const _RouteSummaryCard({required this.addressData});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      children: [
        const _SectionTitle(
          icon: Icons.alt_route_rounded,
          title: 'Rota Confirmada',
        ),
        const SizedBox(height: 14),
        _RouteStop(
          label: 'ORIGEM (COLETA)',
          address: addressData.pickupAddress,
          coordinate: _formatCoordinates(
            addressData.pickupLatitude,
            addressData.pickupLongitude,
          ),
          isOrigin: true,
        ),
        _RouteStop(
          label: 'DESTINO (ENTREGA)',
          address: addressData.deliveryAddress,
          coordinate: _formatCoordinates(
            addressData.deliveryLatitude,
            addressData.deliveryLongitude,
          ),
        ),
      ],
    );
  }
}

class _CargoSpecsCard extends StatelessWidget {
  final FreightPackageData packageData;
  final FreightQuoteModel quote;

  const _CargoSpecsCard({
    required this.packageData,
    required this.quote,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      children: [
        const _SectionTitle(
          icon: Icons.inventory_2_outlined,
          title: 'Especificações da Carga',
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _SpecTile(
                icon: Icons.scale_outlined,
                label: 'PESO',
                value: '${_formatMetric(packageData.weightKg)} kg',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SpecTile(
                icon: Icons.straighten_rounded,
                label: 'VOLUME',
                value: '${quote.packageVolumeM3.toStringAsFixed(3)} m³',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _SpecTile(
                icon: Icons.view_in_ar_outlined,
                label: 'DIMENSÕES',
                value:
                    '${_formatMetric(packageData.widthCm)} x ${_formatMetric(packageData.heightCm)} x ${_formatMetric(packageData.lengthCm)} cm',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SpecTile(
                icon: Icons.local_shipping_outlined,
                label: 'VEÍCULO',
                value: quote.vehicleLabel,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RouteEstimateCard extends StatelessWidget {
  final FreightQuoteModel quote;

  const _RouteEstimateCard({required this.quote});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      children: [
        const _SectionTitle(
          icon: Icons.schedule_rounded,
          title: 'Estimativa da Entrega',
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _SpecTile(
                icon: Icons.route_outlined,
                label: 'DISTÂNCIA',
                value: '${quote.distanceKm.toStringAsFixed(1)} km',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SpecTile(
                icon: Icons.timer_outlined,
                label: 'DURAÇÃO',
                value: _formatDuration(quote.estimatedTimeMinutes),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _ClassificationRow(quote: quote),
      ],
    );
  }
}

class _PriceConfirmationCard extends StatelessWidget {
  final FreightQuoteModel quote;
  final VoidCallback onContinue;
  final VoidCallback onCancel;

  const _PriceConfirmationCard({
    required this.quote,
    required this.onContinue,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 26, 18, 22),
      decoration: BoxDecoration(
        color: ShippingResumePage._primaryBlue,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            _formatMoney(quote.totalPrice),
            style: const TextStyle(
              color: FretColors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Valor total para o motorista',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFD8DAFF),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 43,
            child: ElevatedButton.icon(
              onPressed: onContinue,
              icon: const Icon(Icons.check_circle_outline_rounded, size: 17),
              label: const Text(
                'Continuar para pagamento',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: ShippingResumePage._orange,
                foregroundColor: FretColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 39,
            child: OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: FretColors.white,
                side: const BorderSide(color: Color(0xFF3133AA)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              child: const Text(
                'Voltar e ajustar',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;

  const _SectionCard({required this.children});

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
        children: children,
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
        Icon(icon, color: ShippingResumePage._orange, size: 17),
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
  final String coordinate;
  final bool isOrigin;

  const _RouteStop({
    required this.label,
    required this.address,
    required this.coordinate,
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
              ),
              if (isOrigin)
                const SizedBox(
                  width: 1,
                  height: 44,
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
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FretColors.neutral900,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  coordinate,
                  style: const TextStyle(
                    color: ShippingResumePage._mutedText,
                    fontSize: 10,
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
      height: 74,
      padding: const EdgeInsets.fromLTRB(10, 10, 8, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F8),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF565867), size: 15),
          const Spacer(),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF747682),
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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

class _ClassificationRow extends StatelessWidget {
  final FreightQuoteModel quote;

  const _ClassificationRow({required this.quote});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F8),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.bolt_rounded,
            color: ShippingResumePage._orange,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              quote.deliveryClassificationLabel,
              style: const TextStyle(
                color: FretColors.neutral900,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
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

String _formatCoordinates(double latitude, double longitude) {
  return '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
}

String _formatMetric(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }

  return value.toStringAsFixed(1).replaceAll('.', ',');
}

String _formatDuration(int minutes) {
  if (minutes < 60) {
    return '$minutes min';
  }

  final hours = minutes ~/ 60;
  final remainingMinutes = minutes % 60;
  if (remainingMinutes == 0) {
    return '${hours}h';
  }

  return '${hours}h ${remainingMinutes}min';
}

String _formatMoney(double value) {
  final fixed = value.toStringAsFixed(2);
  final parts = fixed.split('.');
  final integer = parts.first;
  final decimals = parts.last;
  final buffer = StringBuffer();

  for (int i = 0; i < integer.length; i++) {
    final reverseIndex = integer.length - i;
    buffer.write(integer[i]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write('.');
    }
  }

  return 'R\$ ${buffer.toString()},$decimals';
}
