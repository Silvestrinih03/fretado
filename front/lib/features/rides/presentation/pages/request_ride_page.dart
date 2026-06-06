import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../app/design_system/design_system.dart';
import '../../../../core/endpoints.dart';
import '../../../../core/services/http_service.dart';

enum _RidePointMode { pickup, delivery }

class RequestRidePage extends StatefulWidget {
  final int userId;

  const RequestRidePage({super.key, required this.userId});

  @override
  State<RequestRidePage> createState() => _RequestRidePageState();
}

class _RequestRidePageState extends State<RequestRidePage> {
  final HttpService _http = HttpService();
  final MapController _mapController = MapController();
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _deliveryController = TextEditingController();
  final TextEditingController _widthController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _lengthController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final GlobalKey<FormState> _detailsFormKey = GlobalKey<FormState>();

  _RidePointMode _mode = _RidePointMode.pickup;
  LatLng? _pickup;
  LatLng? _delivery;
  bool _loading = false;
  bool _detailsVisible = false;
  AutovalidateMode _detailsAutovalidateMode = AutovalidateMode.disabled;
  _RideQuote? _quote;

  @override
  void dispose() {
    _http.dispose();
    _pickupController.dispose();
    _deliveryController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _lengthController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F7),
      appBar: AppBar(
        title: const Text('Solicitar corrida'),
        backgroundColor: FretColors.neutral050,
        foregroundColor: FretColors.loginFooterLink,
        toolbarHeight: 52,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildMap()),
            _buildPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _pickup ?? const LatLng(-23.55052, -46.633308),
        initialZoom: 12,
        onTap: (_, point) => _setPoint(point),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.fretado',
        ),
        MarkerLayer(
          markers: [
            if (_pickup != null)
              Marker(
                point: _pickup!,
                width: 48,
                height: 48,
                child: const Icon(
                  Icons.radio_button_checked,
                  color: Color(0xFF159947),
                  size: 38,
                ),
              ),
            if (_delivery != null)
              Marker(
                point: _delivery!,
                width: 48,
                height: 48,
                child: const Icon(
                  Icons.location_on,
                  color: Color(0xFFD83232),
                  size: 42,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildPanel() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 410),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: const BoxDecoration(
        color: FretColors.white,
        border: Border(top: BorderSide(color: FretColors.neutral200)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<_RidePointMode>(
              segments: const [
                ButtonSegment(
                  value: _RidePointMode.pickup,
                  icon: Icon(Icons.radio_button_checked),
                  label: Text('Coleta'),
                ),
                ButtonSegment(
                  value: _RidePointMode.delivery,
                  icon: Icon(Icons.location_on),
                  label: Text('Entrega'),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (value) =>
                  setState(() => _mode = value.first),
            ),
            const SizedBox(height: 8),
            _AddressSearchField(
              controller: _pickupController,
              label: 'Endereço de coleta',
              selected: _pickup != null,
              onSearch: () => _searchAddress(_RidePointMode.pickup),
            ),
            const SizedBox(height: 8),
            _AddressSearchField(
              controller: _deliveryController,
              label: 'Endereço de entrega',
              selected: _delivery != null,
              onSearch: () => _searchAddress(_RidePointMode.delivery),
            ),
            const SizedBox(height: 8),
            if (!_detailsVisible)
              _PrimaryButton(
                label: 'Prosseguir',
                loading: _loading,
                onPressed: _canProceed
                    ? () => setState(() => _detailsVisible = true)
                    : null,
              )
            else
              _buildDetails(),
          ],
        ),
      ),
    );
  }

  Widget _buildDetails() {
    return Form(
      key: _detailsFormKey,
      autovalidateMode: _detailsAutovalidateMode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _NumberField(
                  controller: _widthController,
                  label: 'Largura',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _NumberField(
                  controller: _heightController,
                  label: 'Altura',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _NumberField(
                  controller: _lengthController,
                  label: 'Comprimento',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _NumberField(
                  controller: _weightController,
                  label: 'Peso',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_quote != null) _QuoteBox(quote: _quote!),
          const SizedBox(height: 8),
          _PrimaryButton(
            label: _quote == null ? 'Calcular valor' : 'Solicitar corrida',
            loading: _loading,
            onPressed: _quote == null ? _quoteRide : _confirmRide,
          ),
        ],
      ),
    );
  }

  bool get _canProceed => _pickup != null && _delivery != null && !_loading;

  void _setPoint(LatLng point) {
    setState(() {
      if (_mode == _RidePointMode.pickup) {
        _pickup = point;
        _pickupController.text =
            '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}';
      } else {
        _delivery = point;
        _deliveryController.text =
            '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}';
      }
      _quote = null;
    });
  }

  Future<void> _searchAddress(_RidePointMode mode) async {
    final controller = mode == _RidePointMode.pickup
        ? _pickupController
        : _deliveryController;
    if (controller.text.trim().length < 3) return;

    setState(() => _loading = true);
    try {
      final data = await _http.get(Endpoints.rideGeocode(controller.text));
      final results = (data['data'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(_GeocodeResult.fromJson)
          .toList();
      if (!mounted) return;
      if (results.isEmpty) {
        _showMessage('Endereço não encontrado.');
        return;
      }
      final selected = await showModalBottomSheet<_GeocodeResult>(
        context: context,
        builder: (_) => ListView.separated(
          itemCount: results.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final result = results[index];
            return ListTile(
              title: Text(
                result.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => Navigator.of(context).pop(result),
            );
          },
        ),
      );
      if (selected == null) return;
      final point = LatLng(selected.latitude, selected.longitude);
      setState(() {
        if (mode == _RidePointMode.pickup) {
          _pickup = point;
          _pickupController.text = selected.label;
        } else {
          _delivery = point;
          _deliveryController.text = selected.label;
        }
        _quote = null;
      });
      _mapController.move(point, 15);
    } on HttpServiceException catch (e) {
      _showMessage(e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _quoteRide() async {
    if (!_validateDetailsForm()) return;

    final payload = _payload(paymentConfirmed: false);
    if (payload == null) return;

    setState(() => _loading = true);
    try {
      final data = await _http.post(Endpoints.rideQuote, body: payload);
      setState(() => _quote = _RideQuote.fromJson(data));
      await _askRequestConfirmation();
    } on HttpServiceException catch (e) {
      _showMessage(e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _askRequestConfirmation() async {
    final quote = _quote;
    if (quote == null || !mounted) return;
    final shouldRequest = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Solicitar corrida?'),
        content: Text(
          'Total: R\$ ${quote.totalPrice.toStringAsFixed(2)}\n'
          '${quote.distanceKm.toStringAsFixed(1)} km - ${quote.estimatedTimeMinutes} min - ${quote.vehicleName}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Não'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sim'),
          ),
        ],
      ),
    );
    if (shouldRequest == true) {
      await _confirmRide();
    } else {
      _cancelFlow();
    }
  }

  Future<void> _confirmRide() async {
    if (!_validateDetailsForm()) return;

    final paid = await _askCardPayment();
    if (paid != true) return;

    final payload = _payload(paymentConfirmed: true);
    if (payload == null) return;

    setState(() => _loading = true);
    try {
      final data = await _http.post(Endpoints.createRide, body: payload);
      await _runRideDispatchJob();
      if (!mounted) return;
      _showMessage(
        'Corrida #${data['id']} solicitada. Status: ${data['status_id']}',
        isError: false,
      );
      Navigator.of(context).pop(true);
    } on HttpServiceException catch (e) {
      _showMessage(e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<bool?> _askCardPayment() async {
    final number = TextEditingController();
    final name = TextEditingController();
    final expiry = TextEditingController();
    final cvv = TextEditingController();
    final formKey = GlobalKey<FormState>();
    AutovalidateMode autovalidateMode = AutovalidateMode.disabled;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            14,
            14,
            14,
            MediaQuery.of(context).viewInsets.bottom + 14,
          ),
          child: Form(
            key: formKey,
            autovalidateMode: autovalidateMode,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Pagamento no cartão',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: number,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Número do cartão',
                  ),
                  validator: _validatePaymentCardNumber,
                  textInputAction: TextInputAction.next,
                ),
                TextFormField(
                  controller: name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Nome impresso'),
                  validator: _validatePaymentCardName,
                  textInputAction: TextInputAction.next,
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: expiry,
                        keyboardType: TextInputType.datetime,
                        decoration: const InputDecoration(
                          labelText: 'Validade',
                        ),
                        validator: _validatePaymentExpiry,
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: cvv,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'CVV'),
                        validator: _validatePaymentCvv,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) {
                          if (formKey.currentState?.validate() ?? false) {
                            Navigator.of(context).pop(true);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _PrimaryButton(
                  label: 'Confirmar pagamento',
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    final isFormValid =
                        formKey.currentState?.validate() ?? false;
                    if (!isFormValid) {
                      setModalState(() {
                        autovalidateMode = AutovalidateMode.onUserInteraction;
                      });
                      return;
                    }

                    Navigator.of(context).pop(true);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );

    number.dispose();
    name.dispose();
    expiry.dispose();
    cvv.dispose();

    return result;
  }

  Future<void> _runRideDispatchJob() async {
    const jobSecret = String.fromEnvironment('JOB_SECRET');
    if (jobSecret.isEmpty) {
      return;
    }

    try {
      await _http.post(
        Endpoints.rideDispatchJob,
        headers: {'X-Job-Secret': jobSecret},
      );
    } catch (_) {
      // A corrida ja foi criada; o job agendado do backend ainda pode processar.
    }
  }

  Map<String, dynamic>? _payload({required bool paymentConfirmed}) {
    final pickup = _pickup;
    final delivery = _delivery;
    final width = double.tryParse(_widthController.text.replaceAll(',', '.'));
    final height = double.tryParse(_heightController.text.replaceAll(',', '.'));
    final length = double.tryParse(_lengthController.text.replaceAll(',', '.'));
    final weight = double.tryParse(_weightController.text.replaceAll(',', '.'));

    if (pickup == null ||
        delivery == null ||
        width == null ||
        height == null ||
        length == null ||
        weight == null) {
      _showMessage(
        'Preencha coleta, entrega e todas as informações do pacote.',
      );
      return null;
    }

    final payload = <String, dynamic>{
      'origin_latitude': pickup.latitude,
      'origin_longitude': pickup.longitude,
      'destination_latitude': delivery.latitude,
      'destination_longitude': delivery.longitude,
      'package_width': width,
      'package_height': height,
      'package_length': length,
      'package_weight': weight,
    };

    if (!paymentConfirmed) {
      return payload;
    }

    final quote = _quote;
    if (quote == null) {
      _showMessage('Calcule o valor antes de solicitar a corrida.');
      return null;
    }

    return {
      ...payload,
      'client_user_id': widget.userId,
      'driver_user_id': null,
      'total_price': quote.totalPrice,
      'status_id': 1,
    };
  }

  bool _validateDetailsForm() {
    final bool isFormValid = _detailsFormKey.currentState?.validate() ?? false;
    if (!isFormValid) {
      setState(() {
        _detailsAutovalidateMode = AutovalidateMode.onUserInteraction;
      });
    }

    return isFormValid;
  }

  void _cancelFlow() {
    setState(() {
      _pickup = null;
      _delivery = null;
      _detailsVisible = false;
      _quote = null;
      _pickupController.clear();
      _deliveryController.clear();
      _widthController.clear();
      _heightController.clear();
      _lengthController.clear();
      _weightController.clear();
    });
  }

  void _showMessage(String message, {bool isError = true}) {
    if (!mounted) return;

    if (isError) {
      showFretErrorPopup(context, message: message);
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _AddressSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool selected;
  final VoidCallback onSearch;

  const _AddressSearchField({
    required this.controller,
    required this.label,
    required this.selected,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          icon: Icon(selected ? Icons.check_circle : Icons.search),
          color: selected ? const Color(0xFF159947) : null,
          onPressed: onSearch,
        ),
        border: const OutlineInputBorder(),
      ),
      onFieldSubmitted: (_) => onSearch(),
    );
  }
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const _NumberField({required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (value) => _validatePositiveNumber(value, label),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

String? _validatePositiveNumber(String? value, String label) {
  final double? number = double.tryParse((value ?? '').replaceAll(',', '.'));
  if (number == null) {
    return 'Informe $label.';
  }
  if (number <= 0) {
    return '$label deve ser maior que zero.';
  }

  return null;
}

String? _validatePaymentCardNumber(String? value) {
  final String digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) {
    return 'Informe o número.';
  }
  if (digits.length < 13 || digits.length > 19) {
    return 'Número inválido.';
  }

  return null;
}

String? _validatePaymentCardName(String? value) {
  if ((value ?? '').trim().isEmpty) {
    return 'Informe o nome.';
  }

  return null;
}

String? _validatePaymentExpiry(String? value) {
  final String digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) {
    return 'Informe a validade.';
  }
  if (digits.length != 4) {
    return 'Use MM/AA.';
  }

  final int month = int.parse(digits.substring(0, 2));
  if (month < 1 || month > 12) {
    return 'Mês inválido.';
  }

  return null;
}

String? _validatePaymentCvv(String? value) {
  final String digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) {
    return 'Informe o CVV.';
  }
  if (digits.length < 3 || digits.length > 4) {
    return 'CVV inválido.';
  }

  return null;
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  const _PrimaryButton({
    required this.label,
    this.loading = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFE16D),
          foregroundColor: const Color(0xFF080A73),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
    );
  }
}

class _QuoteBox extends StatelessWidget {
  final _RideQuote quote;

  const _QuoteBox({required this.quote});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: FretColors.neutral200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${quote.distanceKm.toStringAsFixed(1)} km - ${quote.estimatedTimeMinutes} min\nVeículo: ${quote.vehicleName}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            'R\$ ${quote.totalPrice.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: FretColors.loginFooterLink,
            ),
          ),
        ],
      ),
    );
  }
}

class _GeocodeResult {
  final String label;
  final double latitude;
  final double longitude;

  const _GeocodeResult({
    required this.label,
    required this.latitude,
    required this.longitude,
  });

  factory _GeocodeResult.fromJson(Map<String, dynamic> json) {
    return _GeocodeResult(
      label: json['label']?.toString() ?? '',
      latitude: double.tryParse(json['latitude'].toString()) ?? 0,
      longitude: double.tryParse(json['longitude'].toString()) ?? 0,
    );
  }
}

class _RideQuote {
  final double distanceKm;
  final int estimatedTimeMinutes;
  final String vehicleName;
  final double totalPrice;

  const _RideQuote({
    required this.distanceKm,
    required this.estimatedTimeMinutes,
    required this.vehicleName,
    required this.totalPrice,
  });

  factory _RideQuote.fromJson(Map<String, dynamic> json) {
    return _RideQuote(
      distanceKm: double.tryParse(json['distance_km'].toString()) ?? 0,
      estimatedTimeMinutes:
          int.tryParse(json['estimated_time_minutes'].toString()) ?? 0,
      vehicleName: json['required_vehicle_type_name']?.toString() ?? '',
      totalPrice: double.tryParse(json['total_price'].toString()) ?? 0,
    );
  }
}
