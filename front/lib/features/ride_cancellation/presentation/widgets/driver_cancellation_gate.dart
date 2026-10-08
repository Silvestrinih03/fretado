import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/design_system/design_system.dart';
import '../../../../core/services/http_service.dart';
import '../../../home/presentation/controllers/driver_availability_controller.dart';
import '../../data/datasources/ride_cancellation_datasource.dart';
import '../../data/models/ride_cancellation_models.dart';
import '../../data/repositories/ride_cancellation_repository_impl.dart';

class DriverCancellationGate extends StatefulWidget {
  final DriverAvailabilityController availabilityController;
  final VoidCallback? onCancellationChanged;
  final Widget child;

  const DriverCancellationGate({
    super.key,
    required this.availabilityController,
    required this.child,
    this.onCancellationChanged,
  });

  static Future<void> checkNow(BuildContext context) async {
    final state = context
        .findAncestorStateOfType<_DriverCancellationGateState>();
    await state?.checkNow();
  }

  @override
  State<DriverCancellationGate> createState() => _DriverCancellationGateState();
}

class _DriverCancellationGateState extends State<DriverCancellationGate>
    with WidgetsBindingObserver {
  late final HttpService _httpService;
  late final RideCancellationRepositoryImpl _repository;
  bool _checking = false;
  bool _showing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _httpService = HttpService();
    _repository = RideCancellationRepositoryImpl(
      RideCancellationDatasource(_httpService),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(checkNow());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(checkNow());
    }
  }

  Future<void> checkNow() async {
    if (!mounted || _checking || _showing) return;
    _checking = true;
    try {
      final cancellation = await _repository.driverAction();
      if (!mounted || cancellation == null || cancellation.isAwaitingClient) {
        return;
      }
      if (!cancellation.isAwaitingDriver &&
          !cancellation.isCompleted &&
          !cancellation.isDeclined) {
        return;
      }

      _showing = true;
      final changed = await showModalBottomSheet<bool>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        barrierColor: const Color(0x990C0C0C),
        builder: (_) => _DriverCancellationSheet(
          cancellation: cancellation,
          repository: _repository,
          availabilityController: widget.availabilityController,
        ),
      );
      if (changed == true && mounted) widget.onCancellationChanged?.call();
    } catch (_) {
      // A falha desta checagem não bloqueia o uso da home.
    } finally {
      _showing = false;
      _checking = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _httpService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _DriverCancellationSheet extends StatefulWidget {
  final RideCancellationModel cancellation;
  final RideCancellationRepositoryImpl repository;
  final DriverAvailabilityController availabilityController;

  const _DriverCancellationSheet({
    required this.cancellation,
    required this.repository,
    required this.availabilityController,
  });

  @override
  State<_DriverCancellationSheet> createState() =>
      _DriverCancellationSheetState();
}

class _DriverCancellationSheetState extends State<_DriverCancellationSheet> {
  late RideCancellationModel _cancellation;
  bool _busy = false;
  bool _preparingQuote = false;
  bool _confirmed = false;
  String? _error;

  bool get _isInitialRequest => _cancellation.isAwaitingDriver;
  bool get _hasPreparedQuote => _cancellation.quotePreparedAt != null;

  @override
  void initState() {
    super.initState();
    _cancellation = widget.cancellation;
    if (_isInitialRequest && !_hasPreparedQuote) {
      unawaited(_prepareQuote());
    }
  }

  Future<void> _prepareQuote() async {
    if (_preparingQuote || _hasPreparedQuote) return;
    setState(() {
      _preparingQuote = true;
      _error = null;
    });
    try {
      await widget.availabilityController.refreshCurrentLocation(silent: true);
      final prepared = await widget.repository.prepareDriverQuote(
        _cancellation.id,
      );
      if (!mounted) return;
      setState(() {
        _cancellation = prepared;
        _preparingQuote = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _preparingQuote = false;
        _error = _errorMessage(error);
      });
    }
  }

  Future<void> _confirmCargo() async {
    if (_busy || !_hasPreparedQuote) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final confirmed = await widget.repository.confirmCargo(_cancellation.id);
      if (!mounted) return;
      setState(() {
        _cancellation = confirmed;
        _busy = false;
        _confirmed = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = _errorMessage(error);
      });
    }
  }

  Future<void> _acknowledge() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repository.acknowledge(_cancellation.id);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = _errorMessage(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cancellation = _cancellation;
    final completedWithReturn = cancellation.returnRideId != null;
    final title = _confirmed
        ? 'Confirmação enviada'
        : cancellation.isCompleted
        ? 'Corrida cancelada'
        : cancellation.isDeclined
        ? 'Cancelamento recusado'
        : 'Cancelamento solicitado';
    final description = _confirmed
        ? 'Aguarde a decisão do cliente. A corrida ficará com cancelamento em análise.'
        : cancellation.isCompleted
        ? completedWithReturn
              ? cancellation.phase == 'return_completed'
                    ? 'A devolução #${cancellation.returnRideId}, vinculada à '
                          'corrida #${cancellation.rideId}, foi finalizada. '
                          '${_money(cancellation.driverCompensation)} foi creditado.'
                    : 'A devolução #${cancellation.returnRideId} foi criada e vinculada '
                          'à corrida #${cancellation.rideId}. Você receberá '
                          '${_money(cancellation.driverCompensation)} ao finalizar a devolução.'
              : 'O cancelamento desta corrida foi concluído.'
        : cancellation.isDeclined
        ? 'O cliente recusou o cancelamento. Continue a entrega original.'
        : 'O cliente solicitou o cancelamento. Confirme se a carga está com você.';

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: 16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .88,
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          decoration: const BoxDecoration(
            color: FretColors.appSurfaceSoft,
            borderRadius: BorderRadius.all(Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: FretColors.attention100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: FretColors.attention800,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: FretColors.screenDark,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  description,
                  style: const TextStyle(
                    color: FretColors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                if (_isInitialRequest && !_confirmed) ...[
                  if (_hasText(cancellation.reason)) ...[
                    const SizedBox(height: 16),
                    _CancellationInfo(
                      label: 'MOTIVO',
                      value: cancellation.reason!.trim(),
                    ),
                  ],
                  if (_hasText(cancellation.returnAddress)) ...[
                    const SizedBox(height: 10),
                    _CancellationInfo(
                      label: 'DESTINO DA DEVOLUÇÃO',
                      value: _returnAddress(cancellation),
                    ),
                  ],
                  if (_hasText(cancellation.originalDestinationAddress)) ...[
                    const SizedBox(height: 10),
                    _CancellationInfo(
                      label: 'ENTREGA ORIGINAL',
                      value: _originalDestination(cancellation),
                    ),
                  ],
                  if (_hasPreparedQuote) ...[
                    const SizedBox(height: 10),
                    _CancellationInfo(
                      label: 'DISTÂNCIAS ESTIMADAS',
                      value:
                          'Coleta até o cancelamento: ${_distance(cancellation.traveledDistanceKm)}\n'
                          'Cancelamento até a devolução: ${_distance(cancellation.returnDistanceKm)}',
                    ),
                    const SizedBox(height: 10),
                    _DriverCompensationInfo(
                      compensation: cancellation.driverCompensation,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'O cliente será informado sobre o valor do cancelamento e poderá decidir se deseja prosseguir. '
                      'Caso confirme, você receberá pelo trajeto já realizado e pelo percurso de devolução. '
                      'Se ele optar por continuar, a entrega seguirá normalmente.',
                      style: TextStyle(
                        color: FretColors.textSecondary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ] else if (_preparingQuote) ...[
                    const SizedBox(height: 14),
                    const _PreparingQuote(),
                  ],
                ],
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    _error!,
                    style: const TextStyle(
                      color: FretColors.destructive700,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                if (_confirmed)
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: _primaryButtonStyle(),
                    child: const Text('Entendi'),
                  )
                else if (_isInitialRequest) ...[
                  FilledButton(
                    onPressed: _busy || _preparingQuote || !_hasPreparedQuote
                        ? null
                        : _confirmCargo,
                    style: _primaryButtonStyle(),
                    child: _busy
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Confirmar posse da carga'),
                  ),
                  if (!_preparingQuote && !_hasPreparedQuote) ...[
                    const SizedBox(height: 6),
                    OutlinedButton(
                      onPressed: _busy ? null : _prepareQuote,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                        foregroundColor: FretColors.screenDark,
                      ),
                      child: const Text('Tentar calcular novamente'),
                    ),
                  ],
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      minimumSize: const Size.fromHeight(42),
                      foregroundColor: FretColors.screenMuted,
                    ),
                    child: const Text('Agora não'),
                  ),
                ] else
                  FilledButton(
                    onPressed: _busy ? null : _acknowledge,
                    style: _primaryButtonStyle(),
                    child: _busy
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Entendi'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ButtonStyle _primaryButtonStyle() => FilledButton.styleFrom(
    minimumSize: const Size.fromHeight(48),
    backgroundColor: FretColors.screenGold,
    foregroundColor: FretColors.screenDark,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
  );
}

class _PreparingQuote extends StatelessWidget {
  const _PreparingQuote();

  @override
  Widget build(BuildContext context) => const Row(
    children: [
      SizedBox.square(
        dimension: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      SizedBox(width: 10),
      Expanded(
        child: Text(
          'Calculando as rotas e o valor da devolução...',
          style: TextStyle(color: FretColors.textSecondary, fontSize: 12),
        ),
      ),
    ],
  );
}

class _DriverCompensationInfo extends StatelessWidget {
  final double compensation;

  const _DriverCompensationInfo({required this.compensation});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: FretColors.attention050,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: FretColors.attention200),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SE O CLIENTE ACEITAR, VOCÊ RECEBERÁ',
          style: TextStyle(
            color: FretColors.attention800,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _money(compensation),
          style: const TextStyle(
            color: FretColors.screenDark,
            fontSize: 21,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        const Text(
          'O valor será creditado somente após finalizar a devolução.',
          style: TextStyle(
            color: FretColors.textSecondary,
            fontSize: 10,
            height: 1.35,
          ),
        ),
      ],
    ),
  );
}

class _CancellationInfo extends StatelessWidget {
  final String label;
  final String value;

  const _CancellationInfo({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: FretColors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: FretColors.screenBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: FretColors.screenMuted,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 12, height: 1.35)),
      ],
    ),
  );
}

bool _hasText(String? value) => value?.trim().isNotEmpty == true;

String _returnAddress(RideCancellationModel cancellation) {
  return [
    cancellation.returnAddress,
    cancellation.returnAddressComplement,
    cancellation.returnReferencePoint,
  ].whereType<String>().where(_hasText).join(' · ');
}

String _originalDestination(RideCancellationModel cancellation) => [
  cancellation.originalDestinationAddress,
  cancellation.originalDestinationAddressComplement,
  cancellation.originalDestinationReferencePoint,
].whereType<String>().where(_hasText).join(' · ');

String _distance(double? value) => value == null
    ? 'Indisponível'
    : '${value.toStringAsFixed(1).replaceAll('.', ',')} km';

String _money(double value) =>
    'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';

String _clientFinancialSummary(RideCancellationModel cancellation) {
  if (cancellation.additionalChargeAmount > 0) {
    return 'Cobrança adicional de ${_money(cancellation.additionalChargeAmount)}.';
  }
  if (cancellation.refundAmount > 0) {
    return 'Reembolso de ${_money(cancellation.refundAmount)}.';
  }
  if (cancellation.cancellationCharge > 0) {
    return 'Valor retido: ${_money(cancellation.cancellationCharge)}.';
  }
  return 'Sem cobrança adicional ou reembolso.';
}

String _errorMessage(Object error) {
  if (error is HttpServiceException) return error.message;
  return 'Não foi possível concluir agora. Tente novamente.';
}
