import 'package:flutter/material.dart';

import '../../../../app/design_system/design_system.dart';
import '../../../../core/endpoints.dart';
import '../../../../core/services/http_service.dart';

class CancellationLogTimeline extends StatefulWidget {
  final int rideId;

  const CancellationLogTimeline({super.key, required this.rideId});

  @override
  State<CancellationLogTimeline> createState() =>
      _CancellationLogTimelineState();
}

class _CancellationLogTimelineState extends State<CancellationLogTimeline> {
  late final HttpService _httpService;
  late Future<List<_CancellationLogEvent>> _future;

  @override
  void initState() {
    super.initState();
    _httpService = HttpService();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant CancellationLogTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rideId != widget.rideId) _future = _load();
  }

  Future<List<_CancellationLogEvent>> _load() async {
    final response = await _httpService.get(
      Endpoints.rideCancellationLog(widget.rideId),
    );
    final rawEvents = response['events'];
    if (rawEvents is! List) return const [];
    return rawEvents
        .whereType<Map>()
        .map(
          (event) =>
              _CancellationLogEvent.fromJson(Map<String, dynamic>.from(event)),
        )
        .toList();
  }

  void _retry() => setState(() => _future = _load());

  @override
  void dispose() {
    _httpService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FutureBuilder<List<_CancellationLogEvent>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  SizedBox.square(
                    dimension: 15,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Carregando eventos...',
                    style: TextStyle(
                      color: FretColors.screenMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            );
          }
          if (snapshot.hasError) {
            return TextButton.icon(
              onPressed: _retry,
              icon: const Icon(Icons.refresh_rounded, size: 15),
              label: const Text('Tentar carregar a timeline novamente'),
            );
          }
          final events = snapshot.data ?? const <_CancellationLogEvent>[];
          if (events.isEmpty) {
            return const Text(
              'Nenhum evento registrado.',
              style: TextStyle(color: FretColors.screenMuted, fontSize: 10),
            );
          }
          return Column(
            children: [
              for (var index = 0; index < events.length; index++)
                _TimelineEvent(
                  event: events[index],
                  isLast: index == events.length - 1,
                ),
            ],
          );
        },
      );
}

class _TimelineEvent extends StatelessWidget {
  final _CancellationLogEvent event;
  final bool isLast;

  const _TimelineEvent({required this.event, required this.isLast});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 18,
        child: Column(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: const BoxDecoration(
                color: FretColors.screenGold,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(width: 1, height: 35, color: FretColors.screenBorder),
          ],
        ),
      ),
      const SizedBox(width: 7),
      Expanded(
        child: Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.label,
                style: const TextStyle(
                  color: FretColors.screenDark,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatDateTime(event.createdAt),
                style: const TextStyle(
                  color: FretColors.screenMuted,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class _CancellationLogEvent {
  final String type;
  final DateTime createdAt;

  const _CancellationLogEvent({required this.type, required this.createdAt});

  factory _CancellationLogEvent.fromJson(Map<String, dynamic> json) =>
      _CancellationLogEvent(
        type: json['event_type']?.toString() ?? '',
        createdAt:
            DateTime.tryParse(
              json['created_at']?.toString() ?? '',
            )?.toLocal() ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );

  String get label => switch (type) {
    'cancellation_requested' => 'Cancelamento solicitado',
    'driver_quote_prepared' ||
    'cancellation_cost_calculated' => 'Orçamento da devolução congelado',
    'driver_confirmed_cargo' => 'Motorista confirmou a posse da carga',
    'client_confirmed_cancellation' => 'Cliente confirmou a devolução',
    'client_declined_cancellation' => 'Cliente manteve a entrega original',
    'return_ride_created' => 'Corrida de devolução criada',
    'return_delivery_completed' => 'Devolução finalizada',
    'financial_adjustment_simulated' => 'Ajuste financeiro registrado',
    'driver_compensation_credited' => 'Valor do motorista creditado',
    'ride_cancelled' => 'Corrida original cancelada',
    _ => type.replaceAll('_', ' '),
  };
}

String _formatDateTime(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/'
    '${value.month.toString().padLeft(2, '0')}/${value.year} '
    '${value.hour.toString().padLeft(2, '0')}:'
    '${value.minute.toString().padLeft(2, '0')}';
