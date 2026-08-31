import 'package:flutter/material.dart';

import '../theme/fret_colors.dart';

class FretRideSummaryCard extends StatelessWidget {
  final int rideId;
  final int statusId;
  final DateTime? createdAt;
  final String origin;
  final String destination;
  final double totalPrice;
  final double packageWeight;
  final Widget? footer;

  const FretRideSummaryCard({
    super.key,
    required this.rideId,
    required this.statusId,
    required this.createdAt,
    required this.origin,
    required this.destination,
    required this.totalPrice,
    required this.packageWeight,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 22),
      decoration: BoxDecoration(
        color: FretColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEDEDED)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Corrida #$rideId',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FretColors.brandBlack,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatDate(createdAt),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF8B8B8B),
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        height: 1.05,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              FretRideStatusPill(statusId: statusId),
            ],
          ),
          const SizedBox(height: 24),
          _FretRouteTimeline(origin: origin, destination: destination),
          const SizedBox(height: 24),
          Row(
            children: [
              _FretRideMetricChip(
                label: _formatMoney(totalPrice),
                emphasized: true,
              ),
              const SizedBox(width: 12),
              _FretRideMetricChip(label: '${_formatNumber(packageWeight)} kg'),
            ],
          ),
          if (footer != null) ...[
            const SizedBox(height: 14),
            footer!,
          ],
        ],
      ),
    );
  }
}

class FretRideStatusPill extends StatelessWidget {
  final int statusId;

  const FretRideStatusPill({
    super.key,
    required this.statusId,
  });

  @override
  Widget build(BuildContext context) {
    final style = _FretRideStatusVisualStyle.fromStatusId(statusId);

    return Container(
      constraints: const BoxConstraints(minHeight: 38, maxWidth: 190),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: style.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: style.borderColor == null
            ? null
            : Border.all(color: style.borderColor!, width: 1.3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (style.icon != null) ...[
            Icon(style.icon, color: style.foregroundColor, size: 17),
            const SizedBox(width: 7),
          ] else ...[
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: style.dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 9),
          ],
          Flexible(
            child: Text(
              style.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: style.foregroundColor,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                height: 1,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FretRideStatusVisualStyle {
  final String label;
  final Color backgroundColor;
  final Color? borderColor;
  final Color foregroundColor;
  final Color dotColor;
  final IconData? icon;

  const _FretRideStatusVisualStyle({
    required this.label,
    required this.backgroundColor,
    required this.borderColor,
    required this.foregroundColor,
    required this.dotColor,
    this.icon,
  });

  static _FretRideStatusVisualStyle fromStatusId(int statusId) {
    return switch (statusId) {
      1 => const _FretRideStatusVisualStyle(
        label: 'Aguardando aceite',
        backgroundColor: Color(0xFFFCF9ED),
        borderColor: Color(0xFFE7D89D),
        foregroundColor: Color(0xFF9A7D20),
        dotColor: FretColors.brandGold,
      ),
      2 => const _FretRideStatusVisualStyle(
        label: 'Aguardando início',
        backgroundColor: Color(0xFFF2F2F2),
        borderColor: Color(0xFFD1D1D1),
        foregroundColor: Color(0xFF444444),
        dotColor: FretColors.brandBlack,
      ),
      3 => const _FretRideStatusVisualStyle(
        label: 'Em coleta',
        backgroundColor: FretColors.brandGold,
        borderColor: null,
        foregroundColor: FretColors.brandBlack,
        dotColor: FretColors.white,
      ),
      4 => const _FretRideStatusVisualStyle(
        label: 'Em entrega',
        backgroundColor: FretColors.brandGold,
        borderColor: null,
        foregroundColor: FretColors.brandBlack,
        dotColor: FretColors.white,
      ),
      5 => const _FretRideStatusVisualStyle(
        label: 'Finalizada',
        backgroundColor: FretColors.brandBlack,
        borderColor: null,
        foregroundColor: FretColors.white,
        dotColor: FretColors.white,
        icon: Icons.check_rounded,
      ),
      6 => const _FretRideStatusVisualStyle(
        label: 'Cancelada',
        backgroundColor: Color(0xFFF0F0F0),
        borderColor: Color(0xFFD0D0D0),
        foregroundColor: Color(0xFF777777),
        dotColor: Color(0xFF777777),
        icon: Icons.close_rounded,
      ),
      _ => const _FretRideStatusVisualStyle(
        label: 'Status',
        backgroundColor: FretColors.neutral100,
        borderColor: FretColors.neutral300,
        foregroundColor: FretColors.neutral700,
        dotColor: FretColors.neutral700,
      ),
    };
  }
}

class _FretRouteTimeline extends StatelessWidget {
  final String origin;
  final String destination;

  const _FretRouteTimeline({
    required this.origin,
    required this.destination,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 16,
          child: Column(
            children: [
              const SizedBox(height: 5),
              const _FretRouteDot(color: FretColors.brandGold),
              Container(width: 1.2, height: 33, color: Color(0xFFE0E0E0)),
              const _FretRouteDot(color: FretColors.brandBlack),
            ],
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FretRouteAddress(value: origin, color: FretColors.brandBlack),
              const SizedBox(height: 21),
              _FretRouteAddress(
                value: destination,
                color: const Color(0xFF909090),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FretRouteDot extends StatelessWidget {
  final Color color;

  const _FretRouteDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _FretRouteAddress extends StatelessWidget {
  final String value;
  final Color color;

  const _FretRouteAddress({
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: color,
        fontSize: 18,
        height: 1.15,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
    );
  }
}

class _FretRideMetricChip extends StatelessWidget {
  final String label;
  final bool emphasized;

  const _FretRideMetricChip({
    required this.label,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAF9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE7E5E0), width: 1.2),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: emphasized ? FretColors.brandBlack : const Color(0xFF8A8A8A),
          fontSize: 17,
          fontWeight: emphasized ? FontWeight.w900 : FontWeight.w600,
          height: 1,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

String _formatMoney(double value) {
  final fixed = value.toStringAsFixed(2).replaceAll('.', ',');
  return 'R\$ $fixed';
}

String _formatNumber(double value) {
  return value.toStringAsFixed(1).replaceAll('.', ',');
}

String _formatDate(DateTime? value) {
  if (value == null) return '';

  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final year = local.year.toString();

  return '$day/$month/$year';
}
