import 'package:flutter/material.dart';

import '../../../../app/design_system/design_system.dart';
import '../../../../core/enums/home_profile.dart';
import '../../../driver_operations/data/models/driver_operation_models.dart';
import '../../../ride_cancellation/presentation/widgets/cancellation_log_timeline.dart';
import '../../../ride_chat/presentation/widgets/ride_chat_access_button.dart';

Future<void> showActiveRideDetailsSheet(
  BuildContext context, {
  required DriverRideModel ride,
  required HomeProfileEnum profile,
  required VoidCallback onTrack,
  VoidCallback? onCancel,
  VoidCallback? onDriverReassignment,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x990C0C0C),
    builder: (sheetContext) => _ActiveRideDetailsSheet(
      ride: ride,
      profile: profile,
      onTrack: () {
        Navigator.of(sheetContext).pop();
        onTrack();
      },
      onCancel: onCancel == null
          ? null
          : () {
              Navigator.of(sheetContext).pop();
              onCancel();
            },
      onDriverReassignment: onDriverReassignment == null
          ? null
          : () {
              Navigator.of(sheetContext).pop();
              onDriverReassignment();
            },
    ),
  );
}

class _ActiveRideDetailsSheet extends StatelessWidget {
  final DriverRideModel ride;
  final HomeProfileEnum profile;
  final VoidCallback onTrack;
  final VoidCallback? onCancel;
  final VoidCallback? onDriverReassignment;

  const _ActiveRideDetailsSheet({
    required this.ride,
    required this.profile,
    required this.onTrack,
    required this.onCancel,
    required this.onDriverReassignment,
  });

  @override
  Widget build(BuildContext context) {
    final isDriver = profile == HomeProfileEnum.driver;
    final party = isDriver ? ride.client : ride.driver;
    final vehicle = ride.assignedVehicle;
    final details = ride.details;
    final cancellationStatus = ride.activeCancellation?.phase;
    final cancellationNotice =
        fretCancellationNotice(cancellationStatus, isDriver: isDriver) ??
        _reassignmentNotice(ride.activeDriverReassignment, isDriver);
    final partySubtitle = isDriver
        ? 'Cliente verificado'
        : vehicle == null
        ? null
        : '${vehicle.displayName} · ${vehicle.plate}';

    return DraggableScrollableSheet(
      initialChildSize: .9,
      minChildSize: .55,
      maxChildSize: .94,
      expand: false,
      builder: (context, controller) => Container(
        decoration: const BoxDecoration(
          color: FretColors.appSurfaceSoft,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD8D6D1),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 17),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ride.isCancellationReturn
                            ? 'DETALHES DA DEVOLUÇÃO'
                            : 'DETALHES DA CORRIDA',
                        style: const TextStyle(
                          color: FretColors.screenMuted,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ride.isCancellationReturn
                            ? 'Devolução #${ride.id} · corrida #${ride.sourceRideId ?? ride.cancellation?.originalRideId ?? ride.id}'
                            : 'Corrida #${ride.id}',
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _formatDate(ride.createdAt),
                        style: const TextStyle(
                          color: FretColors.screenMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                FretRideStatusPill(
                  statusId: ride.statusId,
                  cancellationStatus: cancellationStatus,
                ),
              ],
            ),
            if (cancellationNotice != null) ...[
              const SizedBox(height: 12),
              FretCancellationNotice(message: cancellationNotice),
            ],
            const SizedBox(height: 17),
            _RouteDetailsCard(ride: ride),
            if (ride.cancellation != null ||
                ride.activeCancellation != null) ...[
              const SizedBox(height: 10),
              _CancellationJourneyCard(
                rideId: ride.id,
                cancellation: ride.cancellation ?? ride.activeCancellation!,
                isDriver: isDriver,
              ),
            ],
            if (party != null) ...[
              const SizedBox(height: 10),
              _PartyDetailsCard(
                title: isDriver ? 'SEU CLIENTE' : 'SEU MOTORISTA',
                party: party,
                subtitle: partySubtitle,
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _DetailMetric(
                    label: isDriver ? 'VOCÊ RECEBE' : 'VALOR',
                    value: _formatMoney(
                      isDriver ? ride.driverNetValue : ride.totalPrice,
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: _DetailMetric(
                    label: 'PESO',
                    value: '${_formatNumber(ride.packageWeight)} kg',
                  ),
                ),
              ],
            ),
            if (details != null &&
                (details.packageWidth > 0 ||
                    details.packageHeight > 0 ||
                    details.packageLength > 0)) ...[
              const SizedBox(height: 9),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0x12C9A227),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0x2BC9A227)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DIMENSÕES DA CARGA',
                      style: TextStyle(color: Color(0xFF806515), fontSize: 9),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${_formatNumber(details.packageWidth)} cm × '
                      '${_formatNumber(details.packageHeight)} cm × '
                      '${_formatNumber(details.packageLength)} cm',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            RideChatAccessButton(rideId: ride.id),
            if (onCancel != null) ...[
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  foregroundColor: FretColors.destructive700,
                  side: const BorderSide(color: FretColors.destructive200),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                child: Text(
                  ride.hasPendingCancellation
                      ? 'Ver cancelamento'
                      : 'Cancelar corrida',
                ),
              ),
            ],
            if (onDriverReassignment != null &&
                !ride.isCancellationReturn &&
                (ride.statusId == 2 ||
                    ride.statusId == 3 ||
                    ride.statusId == 4)) ...[
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: onDriverReassignment,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  foregroundColor: FretColors.destructive700,
                  side: const BorderSide(color: FretColors.destructive200),
                ),
                child: Text(
                  ride.hasActiveDriverReassignment
                      ? ride.activeDriverReassignment!.isPrePickupWithdrawal
                            ? 'Ver busca por outro motorista'
                            : 'Ver transferência de carga'
                      : ride.statusId == 4
                      ? 'Não consigo concluir a entrega'
                      : 'Desistir da corrida',
                ),
              ),
            ],
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Fechar',
                style: TextStyle(color: FretColors.screenMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteDetailsCard extends StatelessWidget {
  final DriverRideModel ride;
  const _RouteDetailsCard({required this.ride});

  @override
  Widget build(BuildContext context) {
    final details = ride.details;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: FretColors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: FretColors.screenBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ROTA',
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 13),
          _RouteDetail(
            label: 'COLETA',
            address: details?.originAddress ?? ride.originLabel,
            complement: details?.originAddressComplement,
            reference: details?.originReferencePoint,
            color: FretColors.screenGold,
          ),
          const SizedBox(height: 15),
          _RouteDetail(
            label: 'ENTREGA',
            address: details?.destinationAddress ?? ride.destinationLabel,
            complement: details?.destinationAddressComplement,
            reference: details?.destinationReferencePoint,
            color: FretColors.screenDark,
          ),
        ],
      ),
    );
  }
}

class _RouteDetail extends StatelessWidget {
  final String label;
  final String address;
  final String? complement;
  final String? reference;
  final Color color;
  const _RouteDetail({
    required this.label,
    required this.address,
    required this.complement,
    required this.reference,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
      const SizedBox(width: 11),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: FretColors.screenMuted,
                fontSize: 9,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              address,
              style: const TextStyle(
                fontSize: 11,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (complement != null && complement!.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                complement!,
                style: const TextStyle(
                  color: FretColors.screenMuted,
                  fontSize: 10,
                ),
              ),
            ],
            if (reference != null && reference!.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                'Referência: $reference',
                style: const TextStyle(color: Color(0xFF9A7810), fontSize: 9),
              ),
            ],
          ],
        ),
      ),
    ],
  );
}

class _CancellationJourneyCard extends StatelessWidget {
  final int rideId;
  final RideActiveCancellationModel cancellation;
  final bool isDriver;

  const _CancellationJourneyCard({
    required this.rideId,
    required this.cancellation,
    required this.isDriver,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: FretColors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: FretColors.attention200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'JORNADA DO CANCELAMENTO',
            style: TextStyle(
              color: FretColors.attention800,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            cancellation.returnRideId == null
                ? 'Corrida original #${cancellation.originalRideId}'
                : 'Corrida original #${cancellation.originalRideId} · '
                      'devolução #${cancellation.returnRideId}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const _JourneyLine(
            label: 'Ponto do cancelamento',
            value: 'Localização registrada no log interno',
          ),
          if (_hasText(cancellation.returnAddress)) ...[
            const SizedBox(height: 8),
            _JourneyLine(
              label: 'Destino da devolução',
              value: _joinAddress(
                cancellation.returnAddress,
                cancellation.returnAddressComplement,
                cancellation.returnReferencePoint,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _JourneyChip(
                label: 'Percorrido',
                value: _formatDistance(cancellation.traveledDistanceKm),
              ),
              _JourneyChip(
                label: 'Devolução',
                value: _formatDistance(cancellation.returnDistanceKm),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _JourneyLine(
            label: isDriver ? 'Valor da devolução' : 'Resumo financeiro',
            value: isDriver
                ? '${_formatMoney(cancellation.driverCompensation)} após a conclusão'
                : _clientCancellationFinancial(cancellation),
          ),
          const Divider(height: 24),
          const Text(
            'TIMELINE',
            style: TextStyle(
              color: FretColors.screenMuted,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          CancellationLogTimeline(rideId: rideId),
        ],
      ),
    );
  }
}

class _JourneyLine extends StatelessWidget {
  final String label;
  final String value;

  const _JourneyLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label.toUpperCase(),
        style: const TextStyle(color: FretColors.screenMuted, fontSize: 8),
      ),
      const SizedBox(height: 2),
      Text(value, style: const TextStyle(fontSize: 11, height: 1.35)),
    ],
  );
}

class _JourneyChip extends StatelessWidget {
  final String label;
  final String value;

  const _JourneyChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: FretColors.screenBackground,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: FretColors.screenBorder),
    ),
    child: Text(
      '$label: $value',
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
    ),
  );
}

class _PartyDetailsCard extends StatelessWidget {
  final String title;
  final RidePartyModel party;
  final String? subtitle;
  const _PartyDetailsCard({
    required this.title,
    required this.party,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: FretColors.screenDark,
      borderRadius: BorderRadius.circular(17),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: FretColors.screenGold,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: .7,
          ),
        ),
        const SizedBox(height: 11),
        Row(
          children: [
            Container(
              width: 43,
              height: 43,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0x885C4B15)),
              ),
              child: Text(
                party.initials,
                style: const TextStyle(
                  color: FretColors.screenGold,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    party.fullName,
                    style: const TextStyle(
                      color: FretColors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0x77FFFFFF),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: FretColors.screenGold,
                      size: 12,
                    ),
                    const SizedBox(width: 3),
                    const Text(
                      fretTemporaryRatingLabel,
                      style: TextStyle(
                        color: FretColors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${party.completedRidesCount} corridas',
                  style: const TextStyle(color: Color(0x66FFFFFF), fontSize: 8),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  );
}

class _DetailMetric extends StatelessWidget {
  final String label;
  final String value;
  const _DetailMetric({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: FretColors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: FretColors.screenBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: FretColors.screenMuted, fontSize: 9),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
        ),
      ],
    ),
  );
}

String _formatDate(DateTime? value) {
  if (value == null) return '';
  final local = value.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/${local.year}';
}

String _formatMoney(double value) =>
    'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
String _formatNumber(double value) =>
    value.toStringAsFixed(1).replaceAll('.', ',');
String _formatDistance(double? value) => value == null
    ? 'Indisponível'
    : '${value.toStringAsFixed(1).replaceAll('.', ',')} km';
bool _hasText(String? value) => value?.trim().isNotEmpty == true;

String _joinAddress(String? address, String? complement, String? reference) => [
  address,
  complement,
  if (_hasText(reference)) 'Referência: $reference',
].whereType<String>().where(_hasText).join(' · ');

String _clientCancellationFinancial(RideActiveCancellationModel cancellation) {
  if (cancellation.additionalChargeAmount > 0) {
    return 'Cobrança adicional de '
        '${_formatMoney(cancellation.additionalChargeAmount)}';
  }
  if (cancellation.refundAmount > 0) {
    return 'Reembolso de ${_formatMoney(cancellation.refundAmount)}';
  }
  return 'Valor retido: ${_formatMoney(cancellation.cancellationCharge)}';
}

String? _reassignmentNotice(
  DriverReassignmentModel? reassignment,
  bool isDriver,
) {
  if (reassignment == null) return null;
  final isPrePickup = reassignment.isPrePickupWithdrawal;
  if (isDriver) {
    return switch (reassignment.status) {
      'searching' =>
        isPrePickup
            ? 'Estamos procurando outro motorista. Esta corrida e sua oferta continuam com você.'
            : 'Estamos procurando outro motorista. Você continua responsável pela carga.',
      'awaiting_replacement' =>
        isPrePickup
            ? 'Um motorista está avaliando a nova oferta.'
            : 'Um motorista está avaliando a transferência.',
      'awaiting_handoff' =>
        'O motorista substituto está a caminho do ponto de transferência.',
      'replacement_unavailable' =>
        isPrePickup
            ? 'Nenhum motorista disponível. Você continua responsável pela corrida.'
            : 'Nenhum motorista disponível. Você continua responsável pela entrega.',
      _ => null,
    };
  }
  return switch (reassignment.status) {
    'searching' || 'awaiting_replacement' =>
      isPrePickup
          ? 'Estamos buscando outro motorista. A corrida atual permanece com o motorista até uma nova oferta ser criada.'
          : 'Estamos buscando outro motorista para continuar a entrega.',
    'awaiting_handoff' =>
      'A transferência da carga está em andamento. O motorista atual permanece responsável até a confirmação.',
    'replacement_unavailable' =>
      isPrePickup
          ? 'Nenhum substituto disponível. A corrida permanece com o motorista atual.'
          : 'A busca por outro motorista continuará assim que houver disponibilidade.',
    _ => null,
  };
}
