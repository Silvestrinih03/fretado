import 'package:flutter/material.dart';

import '../theme/fret_colors.dart';

const String fretTemporaryRatingLabel = '4,8';

class FretRideSummaryCard extends StatelessWidget {
  final int rideId;
  final int statusId;
  final DateTime? createdAt;
  final String origin;
  final String destination;
  final double totalPrice;
  final double packageWeight;
  final String valueLabel;
  final String? participantName;
  final String? participantSubtitle;
  final String? participantInitials;
  final int? participantRidesCount;
  final String? activeCancellationStatus;
  final String? cancellationNotice;
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
    this.valueLabel = 'VALOR',
    this.participantName,
    this.participantSubtitle,
    this.participantInitials,
    this.participantRidesCount,
    this.activeCancellationStatus,
    this.cancellationNotice,
    this.footer,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: FretColors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: FretColors.screenBorder),
      boxShadow: const [
        BoxShadow(
          color: Color(0x12000000),
          blurRadius: 24,
          offset: Offset(0, 7),
        ),
      ],
    ),
    child: Column(
      children: [
        const SizedBox(
          width: double.infinity,
          height: 4,
          child: ColoredBox(color: FretColors.screenGold),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
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
                        const Text(
                          'CORRIDA EM ANDAMENTO',
                          style: TextStyle(
                            color: FretColors.screenMuted,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .7,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Corrida #$rideId',
                          style: const TextStyle(
                            color: FretColors.screenDark,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  FretRideStatusPill(
                    statusId: statusId,
                    cancellationStatus: activeCancellationStatus,
                  ),
                ],
              ),
              if (cancellationNotice != null &&
                  cancellationNotice!.isNotEmpty) ...[
                const SizedBox(height: 12),
                FretCancellationNotice(message: cancellationNotice!),
              ],
              const SizedBox(height: 16),
              _FretRouteTimeline(origin: origin, destination: destination),
              if (participantName != null && participantName!.isNotEmpty) ...[
                const SizedBox(height: 15),
                _FretParticipantSummary(
                  name: participantName!,
                  subtitle: participantSubtitle,
                  initials: participantInitials,
                  ridesCount: participantRidesCount,
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _FretRideMetric(
                      label: valueLabel,
                      value: _formatMoney(totalPrice),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _FretRideMetric(
                      label: 'CARGA',
                      value: '${_formatNumber(packageWeight)} kg',
                    ),
                  ),
                ],
              ),
              if (footer != null) ...[const SizedBox(height: 14), footer!],
            ],
          ),
        ),
      ],
    ),
  );
}

class FretRideStatusPill extends StatelessWidget {
  final int statusId;
  final String? cancellationStatus;
  const FretRideStatusPill({
    super.key,
    required this.statusId,
    this.cancellationStatus,
  });

  @override
  Widget build(BuildContext context) {
    final style = _FretRideStatusVisualStyle.fromValues(
      statusId,
      cancellationStatus,
    );
    return Container(
      constraints: const BoxConstraints(maxWidth: 145),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: style.backgroundColor,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: style.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: style.dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              style.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: style.foregroundColor,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FretCancellationNotice extends StatelessWidget {
  final String message;

  const FretCancellationNotice({super.key, required this.message});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: FretColors.attention050,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: FretColors.attention200),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.info_outline_rounded,
          size: 16,
          color: FretColors.attention700,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: FretColors.attention900,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ),
      ],
    ),
  );
}

String? fretCancellationNotice(String? status, {required bool isDriver}) =>
    switch (status) {
      'awaiting_driver_confirmation' =>
        isDriver
            ? 'O cliente solicitou o cancelamento. Confirme a posse da carga.'
            : 'Cancelamento solicitado. Aguardando a confirmação do motorista.',
      'awaiting_client_confirmation' =>
        isDriver
            ? 'Confirmação enviada. Aguardando a decisão do cliente.'
            : 'O motorista confirmou a posse da carga. Revise o cancelamento.',
      _ => null,
    };

class _FretParticipantSummary extends StatelessWidget {
  final String name;
  final String? subtitle;
  final String? initials;
  final int? ridesCount;
  const _FretParticipantSummary({
    required this.name,
    this.subtitle,
    this.initials,
    this.ridesCount,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: FretColors.screenBackground,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: FretColors.screenBorder),
    ),
    child: Row(
      children: [
        _FretAvatar(initials: initials ?? _initials(name), size: 38),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FretColors.screenMuted,
                    fontSize: 9,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: FretColors.screenGold,
                  size: 12,
                ),
                const SizedBox(width: 2),
                const Text(
                  fretTemporaryRatingLabel,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            if (ridesCount != null) ...[
              const SizedBox(height: 2),
              Text(
                '$ridesCount corridas',
                style: const TextStyle(
                  color: FretColors.screenMuted,
                  fontSize: 8,
                ),
              ),
            ],
          ],
        ),
      ],
    ),
  );
}

class _FretAvatar extends StatelessWidget {
  final String initials;
  final double size;
  const _FretAvatar({required this.initials, required this.size});
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: FretColors.screenDark,
      shape: BoxShape.circle,
      border: Border.all(color: const Color(0x665C4B15)),
    ),
    child: Text(
      initials,
      style: const TextStyle(
        color: FretColors.screenGold,
        fontSize: 10,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _FretRouteTimeline extends StatelessWidget {
  final String origin;
  final String destination;
  const _FretRouteTimeline({required this.origin, required this.destination});
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 10,
        child: Column(
          children: [
            const SizedBox(height: 4),
            const _FretRouteDot(color: FretColors.screenGold),
            Container(width: 1, height: 31, color: FretColors.screenBorder),
            const _FretRouteDot(color: FretColors.screenDark),
          ],
        ),
      ),
      const SizedBox(width: 11),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FretRouteAddress(label: 'COLETA', value: origin, emphasized: true),
            const SizedBox(height: 10),
            _FretRouteAddress(label: 'ENTREGA', value: destination),
          ],
        ),
      ),
    ],
  );
}

class _FretRouteDot extends StatelessWidget {
  final Color color;
  const _FretRouteDot({required this.color});
  @override
  Widget build(BuildContext context) => Container(
    width: 8,
    height: 8,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _FretRouteAddress extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasized;
  const _FretRouteAddress({
    required this.label,
    required this.value,
    this.emphasized = false,
  });
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(color: FretColors.screenMuted, fontSize: 8),
      ),
      const SizedBox(height: 2),
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: emphasized ? FretColors.screenDark : FretColors.screenMuted,
          fontSize: 11,
          fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    ],
  );
}

class _FretRideMetric extends StatelessWidget {
  final String label;
  final String value;
  const _FretRideMetric({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
    decoration: BoxDecoration(
      color: FretColors.screenBackground,
      borderRadius: BorderRadius.circular(11),
      border: Border.all(color: FretColors.screenBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: FretColors.screenMuted, fontSize: 8),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
        ),
      ],
    ),
  );
}

class _FretRideStatusVisualStyle {
  final String label;
  final Color backgroundColor;
  final Color borderColor;
  final Color foregroundColor;
  final Color dotColor;
  const _FretRideStatusVisualStyle(
    this.label,
    this.backgroundColor,
    this.borderColor,
    this.foregroundColor,
    this.dotColor,
  );
  factory _FretRideStatusVisualStyle.fromValues(
    int statusId,
    String? cancellationStatus,
  ) {
    if (cancellationStatus == 'awaiting_driver_confirmation') {
      return const _FretRideStatusVisualStyle(
        'Cancelamento solicitado',
        FretColors.destructive050,
        FretColors.destructive200,
        FretColors.destructive700,
        FretColors.destructive700,
      );
    }
    if (cancellationStatus == 'awaiting_client_confirmation') {
      return const _FretRideStatusVisualStyle(
        'Cancelamento em análise',
        FretColors.attention050,
        FretColors.attention200,
        FretColors.attention800,
        FretColors.attention600,
      );
    }
    return _FretRideStatusVisualStyle.fromStatusId(statusId);
  }

  factory _FretRideStatusVisualStyle.fromStatusId(int statusId) =>
      switch (statusId) {
        1 => const _FretRideStatusVisualStyle(
          'Aguardando aceite',
          Color(0xFFFFFBED),
          Color(0xFFE8DDAF),
          Color(0xFF806515),
          FretColors.screenGold,
        ),
        2 => const _FretRideStatusVisualStyle(
          'Aguardando início',
          Color(0xFFF2F2F2),
          Color(0xFFD1D1D1),
          Color(0xFF444444),
          FretColors.screenDark,
        ),
        3 => const _FretRideStatusVisualStyle(
          'Em coleta',
          Color(0xFFFFF6D8),
          Color(0xFFE5D08A),
          Color(0xFF735A10),
          FretColors.screenGold,
        ),
        4 => const _FretRideStatusVisualStyle(
          'Em entrega',
          Color(0xFFFFF6D8),
          Color(0xFFE5D08A),
          Color(0xFF735A10),
          FretColors.screenGold,
        ),
        5 => const _FretRideStatusVisualStyle(
          'Finalizada',
          Color(0xFFF0F0F0),
          Color(0xFFD0D0D0),
          Color(0xFF555555),
          Color(0xFF555555),
        ),
        6 => const _FretRideStatusVisualStyle(
          'Cancelada',
          Color(0xFFF8EEEE),
          Color(0xFFE3CACA),
          FretColors.destructive700,
          FretColors.destructive700,
        ),
        _ => const _FretRideStatusVisualStyle(
          'Status',
          Color(0xFFF2F2F2),
          Color(0xFFD1D1D1),
          Color(0xFF555555),
          Color(0xFF777777),
        ),
      };
}

String _formatMoney(double value) =>
    'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
String _formatNumber(double value) =>
    value.toStringAsFixed(1).replaceAll('.', ',');
String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return '--';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}
