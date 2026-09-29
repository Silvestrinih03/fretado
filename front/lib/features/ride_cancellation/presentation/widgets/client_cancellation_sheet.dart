import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/design_system/design_system.dart';
import '../../../../core/services/http_service.dart';
import '../../../../core/services/myself/services/myself_service.dart';
import '../../../driver_operations/data/models/driver_operation_models.dart';
import '../../data/models/ride_cancellation_models.dart';
import '../../domain/repositories/ride_cancellation_repository.dart';

enum ClientCancellationResult { completed, declined, pending }

Future<ClientCancellationResult?> showClientCancellationFlow(
  BuildContext context, {
  required DriverRideModel ride,
  required RideCancellationRepository repository,
  RideCancellationModel? initialCancellation,
}) {
  return showModalBottomSheet<ClientCancellationResult>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x940C0C0C),
    builder: (_) => _ClientCancellationSheet(
      ride: ride,
      repository: repository,
      initialCancellation: initialCancellation,
    ),
  );
}

enum _CancellationStage { request, waitingDriver, quote, success, declined }

class _ClientCancellationSheet extends StatefulWidget {
  final DriverRideModel ride;
  final RideCancellationRepository repository;
  final RideCancellationModel? initialCancellation;

  const _ClientCancellationSheet({
    required this.ride,
    required this.repository,
    required this.initialCancellation,
  });

  @override
  State<_ClientCancellationSheet> createState() =>
      _ClientCancellationSheetState();
}

class _ClientCancellationSheetState extends State<_ClientCancellationSheet> {
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  Timer? _pollTimer;
  Timer? _searchDebounce;
  RideCancellationPreviewModel? _preview;
  RideCancellationModel? _cancellation;
  CancellationAddressModel? _selectedAddress;
  List<CancellationAddressModel> _addresses = const [];
  _CancellationStage _stage = _CancellationStage.request;
  String _destination = 'pickup';
  String _driverSubject = 'O motorista';
  String? _error;
  bool _loading = true;
  bool _busy = false;
  bool _searching = false;

  DriverRideModel get _ride => widget.ride;
  bool get _reasonRequired => _preview?.reasonRequired ?? _ride.statusId == 2;
  bool get _reasonValid {
    final length = _reasonController.text.trim().length;
    return length >= 10 && length <= 500;
  }

  @override
  void initState() {
    super.initState();
    _cancellation = widget.initialCancellation;
    unawaited(_loadDriverName());
    unawaited(_bootstrap());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _searchDebounce?.cancel();
    _reasonController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadDriverName() async {
    final driverId = _ride.driverUserId;
    if (driverId == null) return;
    try {
      final driver = await MyselfService().getMyself(driverId);
      if (!mounted || driver.firstName.trim().isEmpty) return;
      setState(() => _driverSubject = driver.firstName.trim());
    } catch (_) {
      // The generic label remains available when profile loading fails.
    }
  }

  Future<void> _bootstrap() async {
    try {
      var current = _cancellation;
      current ??= await widget.repository.latest(_ride.id);
      if (!mounted) return;
      if (current?.isAwaitingDriver == true ||
          current?.isAwaitingClient == true) {
        _applyCancellation(current!);
      } else {
        final preview = await widget.repository.preview(_ride.id);
        if (!preview.allowed) {
          throw const _CancellationSheetException(
            'Esta corrida não pode mais ser cancelada.',
          );
        }
        if (!mounted) return;
        setState(() => _preview = preview);
      }
    } catch (error) {
      if (mounted) setState(() => _error = _errorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _retryBootstrap() {
    setState(() {
      _loading = true;
      _error = null;
    });
    unawaited(_bootstrap());
  }

  void _applyCancellation(RideCancellationModel cancellation) {
    _pollTimer?.cancel();
    _cancellation = cancellation;
    if (cancellation.isAwaitingDriver) {
      _stage = _CancellationStage.waitingDriver;
      _startPolling();
    } else if (cancellation.isAwaitingClient) {
      _stage = _CancellationStage.quote;
    } else if (cancellation.isCompleted) {
      _stage = _CancellationStage.success;
    } else if (cancellation.isDeclined) {
      _stage = _CancellationStage.declined;
    }
    if (mounted) setState(() {});
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => unawaited(_refreshCancellation()),
    );
  }

  Future<void> _refreshCancellation() async {
    if (_busy || !mounted) return;
    try {
      final latest = await widget.repository.latest(_ride.id);
      if (!mounted || latest == null) return;
      if (latest.status != _cancellation?.status ||
          latest.updatedAt != _cancellation?.updatedAt) {
        _applyCancellation(latest);
      }
      if (_error != null && mounted) setState(() => _error = null);
    } catch (error) {
      if (mounted) setState(() => _error = _errorMessage(error));
    }
  }

  Future<void> _submitRequest() async {
    if (_busy || _preview == null) return;
    if (_reasonRequired && !_reasonValid) {
      setState(() => _error = 'Use entre 10 e 500 caracteres.');
      return;
    }
    if (_ride.statusId == 4 &&
        _destination == 'other' &&
        _selectedAddress == null) {
      setState(() => _error = 'Selecione um endereço da lista.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final cancellation = await widget.repository.request(
        _ride.id,
        RideCancellationRequestModel(
          reason: _reasonRequired ? _reasonController.text.trim() : null,
          returnDestinationType: _ride.statusId == 4 ? _destination : null,
          returnAddress: _destination == 'other' ? _selectedAddress : null,
        ),
      );
      if (mounted) _applyCancellation(cancellation);
    } catch (error) {
      if (mounted) setState(() => _error = _errorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _decide(bool accept) async {
    final cancellation = _cancellation;
    if (_busy || cancellation == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final updated = await widget.repository.decide(cancellation.id, accept);
      if (mounted) _applyCancellation(updated);
    } catch (error) {
      if (mounted) setState(() => _error = _errorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _scheduleAddressSearch(String value) {
    _searchDebounce?.cancel();
    _selectedAddress = null;
    final query = value.trim();
    if (query.length < 3) {
      setState(() {
        _addresses = const [];
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    _searchDebounce = Timer(
      const Duration(milliseconds: 400),
      () => unawaited(_searchAddress(query)),
    );
  }

  Future<void> _searchAddress(String query) async {
    try {
      final results = await widget.repository.searchAddress(query);
      if (!mounted || _addressController.text.trim() != query) return;
      setState(() {
        _addresses = results;
        _searching = false;
        _error = results.isEmpty ? 'Nenhum endereço encontrado.' : null;
      });
    } catch (error) {
      if (!mounted || _addressController.text.trim() != query) return;
      setState(() {
        _searching = false;
        _error = _errorMessage(error);
      });
    }
  }

  void _selectAddress(CancellationAddressModel address) {
    setState(() {
      _selectedAddress = address;
      _addressController.text = address.label;
      _addresses = const [];
      _error = null;
    });
  }

  void _close() {
    final pending =
        _stage == _CancellationStage.waitingDriver ||
        _stage == _CancellationStage.quote;
    Navigator.of(
      context,
    ).pop(pending ? ClientCancellationResult.pending : null);
  }

  void _finish(ClientCancellationResult result) =>
      Navigator.of(context).pop(result);

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.88),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: Color(0xFFFBFAF7),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Color(0x3D000000),
                blurRadius: 55,
                offset: Offset(0, -18),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9D7D2),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 13, 18, 18),
                    child: _loading
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 72),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: FretColors.brandGold,
                              ),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _stageBody(),
                              if (_error != null) ...[
                                const SizedBox(height: 12),
                                _ErrorPanel(message: _error!),
                              ],
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stageBody() => switch (_stage) {
    _CancellationStage.request => _requestBody(),
    _CancellationStage.waitingDriver => _waitingDriverBody(),
    _CancellationStage.quote => _quoteBody(),
    _CancellationStage.success => _successBody(),
    _CancellationStage.declined => _declinedBody(),
  };

  Widget _requestBody() {
    if (_preview == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SheetHeader(
            eyebrow: 'CANCELAMENTO',
            eyebrowColor: FretColors.destructive700,
            title: 'Não foi possível carregar',
            subtitle:
                'Atualize os dados da corrida para continuar com o cancelamento.',
            onClose: _close,
          ),
          const SizedBox(height: 18),
          _PrimaryButton(label: 'Tentar novamente', onTap: _retryBootstrap),
        ],
      );
    }
    if (_ride.statusId == 4) return _returnDestinationBody();
    final isPickupJourney = _ride.statusId == 3;
    final title = isPickupJourney
        ? 'Cancelar mesmo com o motorista a caminho?'
        : _ride.statusId == 2
        ? 'Deseja cancelar esta corrida?'
        : 'Cancelar esta corrida?';
    final subtitle = isPickupJourney
        ? 'O motorista já iniciou o deslocamento até a coleta. Uma taxa de 10% será destinada a ele.'
        : _ride.statusId == 2
        ? 'O motorista já aceitou sua solicitação. Conte rapidamente o motivo do cancelamento.'
        : 'Ainda não há motorista confirmado. O cancelamento é gratuito e o valor será estornado integralmente.';
    final preview = _preview;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SheetHeader(
          eyebrow: 'CANCELAMENTO',
          eyebrowColor: const Color(0xFFA62C2C),
          title: title,
          subtitle: subtitle,
          onClose: _close,
        ),
        const SizedBox(height: 18),
        _RideSummary(ride: _ride),
        if (_reasonRequired) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Por que deseja cancelar?',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
              AnimatedBuilder(
                animation: _reasonController,
                builder: (_, _) => Text(
                  '${_reasonController.text.length}/500',
                  style: const TextStyle(
                    fontSize: 10,
                    color: FretColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          TextField(
            controller: _reasonController,
            minLines: 4,
            maxLines: 5,
            maxLength: 500,
            onChanged: (_) => setState(() => _error = null),
            decoration: const InputDecoration(
              hintText:
                  'Ex.: Preciso alterar a data da entrega e não conseguirei receber o motorista agora.',
              counterText: '',
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                _reasonValid
                    ? Icons.check_circle_rounded
                    : Icons.circle_outlined,
                size: 16,
                color: _reasonValid
                    ? FretColors.brandGoldDark
                    : FretColors.neutral400,
              ),
              const SizedBox(width: 6),
              Text(
                'Use entre 10 e 500 caracteres',
                style: TextStyle(
                  fontSize: 10,
                  color: _reasonValid
                      ? FretColors.brandGoldDark
                      : FretColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 14),
        _FinancialCard(
          total: _ride.totalPrice,
          charge: isPickupJourney ? preview?.cancellationCharge ?? 0 : 0,
          refund: preview?.refundAmount ?? _ride.totalPrice,
          showFee: isPickupJourney,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _SecondaryButton(label: 'Manter corrida', onTap: _close),
            ),
            const SizedBox(width: 9),
            Expanded(
              flex: 2,
              child: _PrimaryButton(
                label: 'Confirmar cancelamento',
                color: const Color(0xFFA62C2C),
                loading: _busy,
                onTap: _reasonRequired && !_reasonValid ? null : _submitRequest,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _returnDestinationBody() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _SheetHeader(
        eyebrow: 'DEVOLUÇÃO DA CARGA',
        title: 'Onde devemos devolver?',
        subtitle:
            'Como a mercadoria já foi coletada, precisamos definir um destino de devolução antes de calcular o novo custo.',
        onClose: _close,
      ),
      const SizedBox(height: 18),
      _DestinationOption(
        selected: _destination == 'pickup',
        icon: Icons.undo_rounded,
        title: 'Devolver ao local de coleta',
        subtitle: _ride.originLabel,
        onTap: () => setState(() {
          _destination = 'pickup';
          _error = null;
        }),
      ),
      const SizedBox(height: 9),
      _DestinationOption(
        selected: _destination == 'other',
        icon: Icons.location_on_outlined,
        title: 'Entregar em outro endereço',
        subtitle: 'Informe um novo destino para a devolução',
        onTap: () => setState(() {
          _destination = 'other';
          _error = null;
        }),
      ),
      if (_destination == 'other') ...[
        const SizedBox(height: 14),
        const Text(
          'NOVO DESTINO',
          style: TextStyle(
            color: FretColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.7,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _addressController,
          onChanged: _scheduleAddressSearch,
          decoration: InputDecoration(
            hintText: 'Digite um endereço',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _searching
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _selectedAddress != null
                ? const Icon(
                    Icons.check_circle_rounded,
                    color: FretColors.success700,
                  )
                : null,
          ),
        ),
        if (_addresses.isNotEmpty) ...[
          const SizedBox(height: 7),
          ..._addresses
              .take(4)
              .map(
                (address) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _AddressResult(
                    address: address,
                    onTap: () => _selectAddress(address),
                  ),
                ),
              ),
        ],
      ],
      const SizedBox(height: 14),
      const _NoticeBox(
        message:
            'A corrida ainda não será cancelada. Primeiro o motorista confirmará a posse da carga e o sistema calculará o custo da devolução.',
      ),
      const SizedBox(height: 14),
      _PrimaryButton(
        label: 'Solicitar cálculo da devolução',
        loading: _busy,
        onTap: _destination == 'other' && _selectedAddress == null
            ? null
            : _submitRequest,
      ),
    ],
  );

  Widget _waitingDriverBody() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _SheetHeader(
        eyebrow: 'CANCELAMENTO EM ANÁLISE',
        title: 'Aguardando o motorista',
        subtitle:
            '$_driverSubject precisa confirmar que está com a mercadoria e atualizar a localização antes do cálculo.',
        onClose: _close,
      ),
      const SizedBox(height: 18),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: FretColors.brandBlack,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Color(0x24CDB13F),
              child: Icon(
                Icons.location_on_outlined,
                color: FretColors.brandGold,
              ),
            ),
            SizedBox(height: 13),
            Text(
              'Sua corrida continua ativa',
              style: TextStyle(
                color: FretColors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'A entrega original fica temporariamente bloqueada para finalização enquanto analisamos a devolução.',
              style: TextStyle(
                color: Color(0x7AFFFFFF),
                height: 1.5,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 13),
      const _ProgressStep(
        index: 1,
        label: 'Solicitação enviada ao motorista',
        done: true,
      ),
      const SizedBox(height: 8),
      const _ProgressStep(index: 2, label: 'Confirmar posse e localização'),
      const SizedBox(height: 8),
      const _ProgressStep(index: 3, label: 'Calcular valor da devolução'),
    ],
  );

  Widget _quoteBody() {
    final cancellation = _cancellation!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SheetHeader(
          eyebrow: 'ORÇAMENTO PRONTO',
          title: 'Confira antes de decidir',
          subtitle:
              'O valor considera o trecho já realizado e a rota da posição atual do motorista até o destino de devolução.',
          onClose: _close,
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: FretColors.brandBlack,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Custo total da devolução',
                style: TextStyle(color: Color(0x70FFFFFF), fontSize: 10),
              ),
              const SizedBox(height: 3),
              Text(
                _money(cancellation.cancellationCharge),
                style: const TextStyle(
                  color: FretColors.white,
                  fontSize: 29,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Divider(height: 28, color: Color(0x1FFFFFFF)),
              Row(
                children: [
                  Expanded(
                    child: _DarkMetric(
                      label: 'JÁ PERCORRIDO',
                      value: _distance(cancellation.traveledDistanceKm),
                    ),
                  ),
                  Expanded(
                    child: _DarkMetric(
                      label: 'ATÉ DEVOLUÇÃO',
                      value: _distance(cancellation.returnDistanceKm),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _AdjustmentCard(ride: _ride, cancellation: cancellation),
        const SizedBox(height: 13),
        const _NoticeBox(
          message:
              'Se você mantiver a entrega, a corrida segue para o destino original e o valor pago permanece o mesmo.',
        ),
        const SizedBox(height: 14),
        _PrimaryButton(
          label:
              'Confirmar devolução por ${_money(cancellation.cancellationCharge)}',
          loading: _busy,
          onTap: () => _decide(true),
        ),
        const SizedBox(height: 8),
        _SecondaryButton(
          label: 'Manter entrega original',
          onTap: _busy ? null : () => _decide(false),
        ),
      ],
    );
  }

  Widget _successBody() {
    final cancellation = _cancellation!;
    final isReturn = cancellation.returnRideId != null;
    return _ResultBody(
      icon: Icons.check_rounded,
      eyebrow: isReturn ? 'DEVOLUÇÃO CONFIRMADA' : 'CANCELAMENTO CONCLUÍDO',
      title: isReturn ? 'Vamos devolver sua carga' : 'Corrida cancelada',
      message: isReturn
          ? 'O motorista foi avisado e seguirá para o destino de devolução selecionado.'
          : cancellation.previousRideStatusId == 2
          ? 'O motorista foi avisado e o estorno foi registrado.'
          : 'O cancelamento foi registrado e o ajuste financeiro foi concluído.',
      details: isReturn
          ? [
              _ResultDetail(
                'Novo destino',
                _returnDestinationLabel(cancellation),
              ),
              _ResultDetail(
                'Ajuste financeiro',
                _adjustmentLabel(cancellation),
              ),
            ]
          : [
              const _ResultDetail('Status', 'Cancelada'),
              _ResultDetail(
                'Valor a estornar',
                _money(cancellation.refundAmount),
              ),
            ],
      buttonLabel: 'Entendi',
      buttonColor: FretColors.brandGold,
      onTap: () => _finish(ClientCancellationResult.completed),
    );
  }

  Widget _declinedBody() => _ResultBody(
    icon: Icons.arrow_forward_rounded,
    eyebrow: 'ENTREGA MANTIDA',
    title: 'Tudo certo, a corrida continua',
    message:
        'A solicitação de cancelamento foi encerrada e $_driverSubject continuará até o destino original.',
    buttonLabel: 'Voltar para a corrida',
    onTap: () => _finish(ClientCancellationResult.declined),
  );
}

class _SheetHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final Color eyebrowColor;
  final VoidCallback onClose;

  const _SheetHeader({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.onClose,
    this.eyebrowColor = FretColors.brandGoldDark,
  });

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eyebrow,
              style: TextStyle(
                color: eyebrowColor,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: const TextStyle(
                color: FretColors.brandBlack,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              subtitle,
              style: const TextStyle(
                color: FretColors.textSecondary,
                fontSize: 12,
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: 14),
      Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: FretColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: FretColors.appBorder),
        ),
        child: IconButton(
          tooltip: 'Fechar',
          padding: EdgeInsets.zero,
          onPressed: onClose,
          icon: const Icon(Icons.close_rounded, size: 18),
        ),
      ),
    ],
  );
}

class _RideSummary extends StatelessWidget {
  final DriverRideModel ride;
  const _RideSummary({required this.ride});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
    decoration: BoxDecoration(
      color: FretColors.appBackground,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: FretColors.appBorder),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Corrida #${ride.id}',
                style: const TextStyle(
                  color: FretColors.textSecondary,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${_shortAddress(ride.originLabel)} → ${_shortAddress(ride.destinationLabel)}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _StatusBadge(statusId: ride.statusId),
      ],
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  final int statusId;
  const _StatusBadge({required this.statusId});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: FretColors.brandGoldSoft,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      switch (statusId) {
        1 => 'Aguardando',
        2 => 'Aceita',
        3 => 'A caminho',
        4 => 'Em entrega',
        _ => 'Ativa',
      },
      style: const TextStyle(
        color: FretColors.brandGoldDark,
        fontSize: 9,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _FinancialCard extends StatelessWidget {
  final double total;
  final double charge;
  final double refund;
  final bool showFee;

  const _FinancialCard({
    required this.total,
    required this.charge,
    required this.refund,
    required this.showFee,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: FretColors.brandBlack,
      borderRadius: BorderRadius.circular(16),
    ),
    child: showFee
        ? Column(
            children: [
              _DarkValueRow(label: 'Valor pago', value: _money(total)),
              const SizedBox(height: 9),
              _DarkValueRow(
                label: 'Taxa de cancelamento · 10%',
                value: '− ${_money(charge)}',
                valueColor: FretColors.brandGold,
              ),
              const Divider(height: 20, color: Color(0x1FFFFFFF)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Expanded(
                    child: Text(
                      'Você receberá de volta',
                      style: TextStyle(
                        color: FretColors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    _money(refund),
                    style: const TextStyle(
                      color: FretColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          )
        : Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estorno previsto',
                      style: TextStyle(color: Color(0x70FFFFFF), fontSize: 10),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Sem taxa de cancelamento',
                      style: TextStyle(color: Color(0x9EFFFFFF), fontSize: 11),
                    ),
                  ],
                ),
              ),
              Text(
                _money(refund),
                style: const TextStyle(
                  color: FretColors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
  );
}

class _DarkValueRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _DarkValueRow({
    required this.label,
    required this.value,
    this.valueColor = FretColors.white,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: const TextStyle(color: Color(0x75FFFFFF), fontSize: 10.5),
        ),
      ),
      Text(
        value,
        style: TextStyle(
          color: valueColor,
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );
}

class _DestinationOption extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DestinationOption({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? const Color(0x12C9A227) : FretColors.white,
    borderRadius: BorderRadius.circular(15),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: selected ? FretColors.brandGold : FretColors.appBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selected
                    ? FretColors.brandBlack
                    : FretColors.appBackground,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: FretColors.brandGold, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: FretColors.textSecondary,
                      fontSize: 10.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? FretColors.brandGold : FretColors.neutral400,
              size: 21,
            ),
          ],
        ),
      ),
    ),
  );
}

class _AddressResult extends StatelessWidget {
  final CancellationAddressModel address;
  final VoidCallback onTap;
  const _AddressResult({required this.address, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
    color: FretColors.appBackground,
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: FretColors.appBorder),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 18,
              color: FretColors.brandGoldDark,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                address.label,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _NoticeBox extends StatelessWidget {
  final String message;
  const _NoticeBox({required this.message});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    decoration: BoxDecoration(
      color: const Color(0x14C9A227),
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: const Color(0x33C9A227)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.info_outline_rounded,
          size: 17,
          color: Color(0xFF8A6A0A),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: Color(0xFF735A10),
              fontSize: 10.5,
              height: 1.5,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ProgressStep extends StatelessWidget {
  final int index;
  final String label;
  final bool done;
  const _ProgressStep({
    required this.index,
    required this.label,
    this.done = false,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
    decoration: BoxDecoration(
      color: done ? const Color(0x14C9A227) : FretColors.appBackground,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: done ? const Color(0x30C9A227) : FretColors.appBorder,
      ),
    ),
    child: Row(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: done ? FretColors.brandGold : FretColors.white,
          child: done
              ? const Icon(
                  Icons.check_rounded,
                  size: 13,
                  color: FretColors.brandBlack,
                )
              : Text(
                  '$index',
                  style: const TextStyle(
                    color: FretColors.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: done ? FretColors.brandBlack : FretColors.textSecondary,
              fontSize: 11.5,
              fontWeight: done ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class _DarkMetric extends StatelessWidget {
  final String label;
  final String value;
  const _DarkMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(color: Color(0x61FFFFFF), fontSize: 9.5),
      ),
      const SizedBox(height: 4),
      Text(
        value,
        style: const TextStyle(
          color: FretColors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );
}

class _AdjustmentCard extends StatelessWidget {
  final DriverRideModel ride;
  final RideCancellationModel cancellation;
  const _AdjustmentCard({required this.ride, required this.cancellation});

  @override
  Widget build(BuildContext context) {
    final hasRefund = cancellation.refundAmount > 0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FretColors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: FretColors.appBorder),
      ),
      child: Column(
        children: [
          _ValueRow(label: 'Valor já pago', value: _money(ride.totalPrice)),
          const SizedBox(height: 9),
          _ValueRow(
            label: hasRefund
                ? 'Estorno após confirmação'
                : 'Cobrança adicional',
            value: _money(
              hasRefund
                  ? cancellation.refundAmount
                  : cancellation.additionalChargeAmount,
            ),
            valueColor: hasRefund
                ? FretColors.success700
                : FretColors.destructive700,
          ),
        ],
      ),
    );
  }
}

class _ValueRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  const _ValueRow({
    required this.label,
    required this.value,
    this.valueColor = FretColors.brandBlack,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: const TextStyle(color: FretColors.textSecondary, fontSize: 11),
        ),
      ),
      Text(
        value,
        style: TextStyle(
          color: valueColor,
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  );
}

class _ResultDetail {
  final String label;
  final String value;
  const _ResultDetail(this.label, this.value);
}

class _ResultBody extends StatelessWidget {
  final IconData icon;
  final String eyebrow;
  final String title;
  final String message;
  final List<_ResultDetail> details;
  final String buttonLabel;
  final Color buttonColor;
  final VoidCallback onTap;

  const _ResultBody({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.message,
    required this.buttonLabel,
    required this.onTap,
    this.details = const [],
    this.buttonColor = FretColors.brandBlack,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Align(
        child: Container(
          width: 70,
          height: 70,
          margin: const EdgeInsets.only(bottom: 15),
          decoration: BoxDecoration(
            color: FretColors.brandBlack,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0x52C9A227), width: 2),
          ),
          child: Icon(icon, color: FretColors.brandGold, size: 29),
        ),
      ),
      Text(
        eyebrow,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: FretColors.brandGoldDark,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          height: 1.15,
        ),
      ),
      const SizedBox(height: 7),
      Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: FretColors.textSecondary,
          fontSize: 12,
          height: 1.55,
        ),
      ),
      if (details.isNotEmpty) ...[
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: FretColors.appBackground,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: FretColors.appBorder),
          ),
          child: Column(
            children: [
              for (var index = 0; index < details.length; index++) ...[
                if (index > 0) const SizedBox(height: 9),
                _ValueRow(
                  label: details[index].label,
                  value: details[index].value,
                ),
              ],
            ],
          ),
        ),
      ],
      const SizedBox(height: 14),
      _PrimaryButton(label: buttonLabel, color: buttonColor, onTap: onTap),
    ],
  );
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color color;
  final bool loading;
  const _PrimaryButton({
    required this.label,
    required this.onTap,
    this.color = FretColors.brandBlack,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: FilledButton(
      onPressed: loading ? null : onTap,
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: color == FretColors.brandGold
            ? FretColors.brandBlack
            : FretColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
    ),
  );
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _SecondaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: FretColors.brandBlack,
        side: const BorderSide(color: FretColors.appBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
    ),
  );
}

class _ErrorPanel extends StatelessWidget {
  final String message;
  const _ErrorPanel({required this.message});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: FretColors.destructive050,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: FretColors.destructive100),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.error_outline_rounded,
          color: FretColors.destructive700,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: FretColors.destructive700,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );
}

class _CancellationSheetException implements Exception {
  final String message;
  const _CancellationSheetException(this.message);
}

String _errorMessage(Object error) {
  if (error is HttpServiceException) return error.message;
  if (error is _CancellationSheetException) return error.message;
  return 'Não foi possível concluir esta ação. Tente novamente.';
}

String _money(double value) =>
    'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';

String _distance(double? value) =>
    value == null ? '—' : '${value.toStringAsFixed(1).replaceAll('.', ',')} km';

String _shortAddress(String value) => value.split('—').first.trim();

String _adjustmentLabel(RideCancellationModel cancellation) {
  if (cancellation.refundAmount > 0) {
    return 'Estorno de ${_money(cancellation.refundAmount)}';
  }
  if (cancellation.additionalChargeAmount > 0) {
    return '+ ${_money(cancellation.additionalChargeAmount)}';
  }
  return 'Sem ajuste';
}

String _returnDestinationLabel(RideCancellationModel cancellation) {
  final parts = <String>[
    if (cancellation.returnAddress?.trim().isNotEmpty == true)
      cancellation.returnAddress!.trim(),
    if (cancellation.returnAddressComplement?.trim().isNotEmpty == true)
      cancellation.returnAddressComplement!.trim(),
  ];
  return parts.isEmpty ? 'Destino informado' : parts.join(' · ');
}
