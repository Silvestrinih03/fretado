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
  bool _busy = false;
  bool _confirmed = false;
  String? _error;

  bool get _isInitialRequest => widget.cancellation.isAwaitingDriver;

  Future<void> _confirmCargo() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.availabilityController.refreshCurrentLocation(silent: true);
      await widget.repository.confirmCargo(widget.cancellation.id);
      if (!mounted) return;
      setState(() {
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
      await widget.repository.acknowledge(widget.cancellation.id);
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
    final cancellation = widget.cancellation;
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
              ? 'O cancelamento foi concluído e uma corrida de devolução foi criada.'
              : 'O cancelamento desta corrida foi concluído.'
        : cancellation.isDeclined
        ? 'O cliente recusou o cancelamento. Continue a entrega original.'
        : 'O cliente solicitou o cancelamento. Confirme se a carga já está com você.';

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: 16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          decoration: const BoxDecoration(
            color: FretColors.appSurfaceSoft,
            borderRadius: BorderRadius.all(Radius.circular(24)),
          ),
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
                  onPressed: _busy ? null : _confirmCargo,
                  style: _primaryButtonStyle(),
                  child: _busy
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Confirmar posse da carga'),
                ),
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
    );
  }

  ButtonStyle _primaryButtonStyle() => FilledButton.styleFrom(
    minimumSize: const Size.fromHeight(48),
    backgroundColor: FretColors.screenGold,
    foregroundColor: FretColors.screenDark,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
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

String _errorMessage(Object error) {
  if (error is HttpServiceException) return error.message;
  return 'Não foi possível concluir agora. Tente novamente.';
}
