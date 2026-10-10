import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../app/design_system/design_system.dart';
import '../../../../core/endpoints.dart';
import '../../../../core/services/http_service.dart';
import '../../../driver_operations/data/models/driver_operation_models.dart';

Future<bool> showDriverReassignmentRequestSheet(
  BuildContext context, {
  required DriverRideModel ride,
}) async {
  return await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        barrierColor: const Color(0x990C0C0C),
        builder: (_) => _ReassignmentRequestSheet(ride: ride),
      ) ??
      false;
}

Future<void> showDriverReassignmentStatusSheet(
  BuildContext context, {
  required DriverReassignmentModel reassignment,
  required int userId,
  VoidCallback? onChanged,
}) async {
  final changed = await showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x990C0C0C),
    builder: (_) =>
        _ReassignmentStatusSheet(reassignment: reassignment, userId: userId),
  );
  if (changed == true) onChanged?.call();
}

class DriverReassignmentGate extends StatefulWidget {
  final int userId;
  final VoidCallback? onChanged;
  final Widget child;

  const DriverReassignmentGate({
    super.key,
    required this.userId,
    required this.child,
    this.onChanged,
  });

  static Future<void> checkNow(BuildContext context) async {
    final state = context
        .findAncestorStateOfType<_DriverReassignmentGateState>();
    await state?.checkNow(force: true);
  }

  @override
  State<DriverReassignmentGate> createState() => _DriverReassignmentGateState();
}

class _DriverReassignmentGateState extends State<DriverReassignmentGate>
    with WidgetsBindingObserver {
  late final HttpService _http;
  Timer? _timer;
  bool _checking = false;
  bool _showing = false;
  String? _lastAutoShown;
  int? _trackedReassignmentId;
  String? _trackedReassignmentStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _http = HttpService();
    _timer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => unawaited(checkNow()),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(checkNow()));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(checkNow(force: true));
  }

  Future<void> checkNow({bool force = false}) async {
    if (!mounted || _checking || _showing) return;
    _checking = true;
    try {
      final response = await _http.get(Endpoints.driverReassignmentAction);
      if (!mounted) return;
      final rawData = response['data'];
      if (response.isEmpty ||
          (response.containsKey('data') && rawData == null)) {
        if (_trackedReassignmentId != null) {
          _trackedReassignmentId = null;
          _trackedReassignmentStatus = null;
          _lastAutoShown = null;
          widget.onChanged?.call();
        }
        return;
      }
      final payload = rawData is Map
          ? Map<String, dynamic>.from(rawData)
          : response;
      final reassignment = DriverReassignmentModel.fromJson(payload);
      final statusChanged =
          _trackedReassignmentId == reassignment.id &&
          _trackedReassignmentStatus != null &&
          _trackedReassignmentStatus != reassignment.status;
      _trackedReassignmentId = reassignment.id;
      _trackedReassignmentStatus = reassignment.status;
      if (statusChanged) widget.onChanged?.call();
      final isIncoming = reassignment.incomingDriverUserId == widget.userId;
      final requiresAction =
          (isIncoming && reassignment.isAwaitingHandoff) ||
          (!isIncoming && reassignment.isReplacementUnavailable);
      if (!requiresAction) return;
      final key = '${reassignment.id}:${reassignment.status}';
      if (!force && _lastAutoShown == key) return;
      _lastAutoShown = key;
      _showing = true;
      await showDriverReassignmentStatusSheet(
        context,
        reassignment: reassignment,
        userId: widget.userId,
        onChanged: widget.onChanged,
      );
    } catch (_) {
      // Esta consulta auxiliar não deve bloquear a home.
    } finally {
      _checking = false;
      _showing = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _http.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _ReassignmentRequestSheet extends StatefulWidget {
  final DriverRideModel ride;

  const _ReassignmentRequestSheet({required this.ride});

  @override
  State<_ReassignmentRequestSheet> createState() =>
      _ReassignmentRequestSheetState();
}

class _ReassignmentRequestSheetState extends State<_ReassignmentRequestSheet> {
  final _reasonController = TextEditingController();
  late final HttpService _http;
  bool _busy = false;
  String? _error;

  bool get _isTransfer => widget.ride.statusId == 4;

  @override
  void initState() {
    super.initState();
    _http = HttpService();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _http.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _reasonController.text.trim();
    if (reason.length < 10 || reason.length > 500) {
      setState(
        () => _error = 'Informe uma justificativa entre 10 e 500 caracteres.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final body = <String, dynamic>{'reason': reason};
      if (_isTransfer) {
        final position = await _currentPosition();
        body.addAll({
          'latitude': double.parse(position.latitude.toStringAsFixed(6)),
          'longitude': double.parse(position.longitude.toStringAsFixed(6)),
          'accuracy': double.parse(position.accuracy.toStringAsFixed(2)),
        });
      }
      await _http.post(
        Endpoints.createDriverReassignment(widget.ride.id),
        body: body,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on HttpServiceException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<Position> _currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('Ative a localização do aparelho para continuar.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Permita o acesso à localização para continuar.');
    }
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: FretColors.appSurfaceSoft,
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isTransfer
                    ? 'Não consigo concluir a entrega'
                    : 'Desistir da corrida',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                _isTransfer
                    ? 'Sua localização atual será o ponto de transferência. Você continua responsável até o outro motorista confirmar o recebimento.'
                    : 'Você continuará responsável pela corrida enquanto procuramos outro motorista. Sua oferta só será encerrada quando uma nova oferta for criada.',
                style: const TextStyle(
                  color: FretColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _reasonController,
                minLines: 3,
                maxLines: 5,
                maxLength: 500,
                enabled: !_busy,
                decoration: const InputDecoration(
                  labelText: 'Justificativa',
                  hintText: 'Explique o motivo da desistência',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: const TextStyle(color: FretColors.destructive700),
                ),
              ],
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _busy ? null : _submit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: FretColors.screenGold,
                  foregroundColor: FretColors.screenDark,
                ),
                child: _busy
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _isTransfer
                            ? 'Buscar outro motorista'
                            : 'Procurar outro motorista',
                      ),
              ),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                ),
                child: const Text('Voltar'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ReassignmentStatusSheet extends StatefulWidget {
  final DriverReassignmentModel reassignment;
  final int userId;

  const _ReassignmentStatusSheet({
    required this.reassignment,
    required this.userId,
  });

  @override
  State<_ReassignmentStatusSheet> createState() =>
      _ReassignmentStatusSheetState();
}

class _ReassignmentStatusSheetState extends State<_ReassignmentStatusSheet> {
  late final HttpService _http;
  bool _busy = false;
  String? _error;

  bool get _isIncoming =>
      widget.reassignment.incomingDriverUserId == widget.userId;

  @override
  void initState() {
    super.initState();
    _http = HttpService();
  }

  @override
  void dispose() {
    _http.dispose();
    super.dispose();
  }

  Future<void> _act() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_isIncoming) {
        await _http.post(
          Endpoints.confirmDriverReassignmentReceipt(widget.reassignment.id),
        );
      } else {
        await _http.post(
          Endpoints.retryDriverReassignment(widget.reassignment.id),
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } on HttpServiceException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancelSearch() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _http.post(
        Endpoints.cancelDriverReassignment(widget.reassignment.id),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on HttpServiceException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.reassignment.status;
    final isPrePickup = widget.reassignment.isPrePickupWithdrawal;
    final title = _isIncoming
        ? 'Confirme o recebimento da carga'
        : status == 'replacement_unavailable'
        ? 'Nenhum motorista disponível'
        : isPrePickup
        ? 'Troca de motorista em andamento'
        : 'Transferência em andamento';
    final description = _isIncoming
        ? 'Confirme somente depois que a carga estiver com você. Nesse momento, a responsabilidade pela corrida será transferida.'
        : status == 'awaiting_replacement'
        ? isPrePickup
              ? 'Um motorista está avaliando a oferta. A corrida atual permanece com você até a nova oferta ser criada.'
              : 'Um motorista está avaliando a oferta. Você continua responsável pela carga.'
        : status == 'awaiting_handoff'
        ? 'O novo motorista está a caminho do ponto de transferência.'
        : status == 'replacement_unavailable'
        ? isPrePickup
              ? 'Sua corrida e sua oferta continuam ativas. Tente novamente ou continue normalmente com esta corrida.'
              : 'Você continua responsável pela entrega. Tente procurar novamente quando estiver pronto.'
        : isPrePickup
        ? 'Sua corrida continua ativa enquanto procuramos um motorista compatível.'
        : 'Estamos procurando um motorista compatível.';
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: FretColors.appSurfaceSoft,
            borderRadius: BorderRadius.all(Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                description,
                style: const TextStyle(
                  color: FretColors.textSecondary,
                  height: 1.4,
                ),
              ),
              if (widget.reassignment.handoffAddress?.isNotEmpty == true) ...[
                const SizedBox(height: 14),
                Text(
                  'PONTO DE TRANSFERÊNCIA\n${widget.reassignment.handoffAddress}',
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              if (_isIncoming &&
                  widget.reassignment.incomingNetValue != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Você receberá R\$ ${widget.reassignment.incomingNetValue!.toStringAsFixed(2).replaceAll('.', ',')} após concluir a entrega.',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(color: FretColors.destructive700),
                ),
              ],
              if (_isIncoming ||
                  status == 'replacement_unavailable' ||
                  status == 'awaiting_replacement') ...[
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: _busy ? null : _act,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: FretColors.screenGold,
                    foregroundColor: FretColors.screenDark,
                  ),
                  child: Text(
                    _isIncoming
                        ? 'Confirmar recebimento da carga'
                        : 'Procurar outro motorista',
                  ),
                ),
              ],
              if (!_isIncoming && status != 'awaiting_handoff') ...[
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _busy ? null : _cancelSearch,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    foregroundColor: FretColors.screenDark,
                    side: const BorderSide(color: FretColors.screenBorder),
                  ),
                  child: Text(
                    isPrePickup
                        ? 'Continuar com esta corrida'
                        : 'Continuar a entrega',
                  ),
                ),
              ],
              TextButton(
                onPressed: _busy
                    ? null
                    : () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                ),
                child: const Text('Fechar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
