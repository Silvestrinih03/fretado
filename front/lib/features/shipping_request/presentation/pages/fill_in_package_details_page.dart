import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/maps/address_point_confirmation.dart';
import '../../../../core/maps/address_result.dart';
import '../../../../core/maps/geocoding_credit.dart';

import '../../../../app/design_system/design_system.dart';
import '../../../../core/endpoints.dart';
import '../../../../core/services/http_service.dart';
import '../models/freight_address_data.dart';
import '../models/freight_package_data.dart';
import '../models/freight_quote_model.dart';
import 'shipping_resume_page.dart';

class FillInPackageDetailsPage extends StatefulWidget {
  final int userId;
  final FreightAddressData addressData;
  final FreightDetailsDraft? initialDraft;
  final ValueChanged<FreightDetailsDraft>? onDraftSaved;

  const FillInPackageDetailsPage({
    super.key,
    required this.userId,
    required this.addressData,
    this.initialDraft,
    this.onDraftSaved,
  });

  @override
  State<FillInPackageDetailsPage> createState() =>
      _FillInPackageDetailsPageState();
}

class _FillInPackageDetailsPageState extends State<FillInPackageDetailsPage> {
  static const Color _primaryBlue = FretColors.brandGraphite;
  static const Color _screenBackground = FretColors.appBackground;
  static const Color _orange = FretColors.brandGoldDark;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _widthController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _lengthController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _pickupComplementController =
      TextEditingController();
  final TextEditingController _pickupReferenceController =
      TextEditingController();
  final TextEditingController _deliveryComplementController =
      TextEditingController();
  final TextEditingController _deliveryReferenceController =
      TextEditingController();
  late final HttpService _httpService;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;
  bool _isQuoting = false;
  late FreightAddressData _address;
  final _pickupNumber = TextEditingController();
  final _deliveryNumber = TextEditingController();
  final _pickupNumberKey = GlobalKey<FormFieldState<String>>();
  final _deliveryNumberKey = GlobalKey<FormFieldState<String>>();
  final _packageKey = GlobalKey();
  bool _pickupWithoutNumber = false;
  bool _deliveryWithoutNumber = false;
  String _previousPickupNumber = '';
  String _previousDeliveryNumber = '';
  bool _savedForRouteEdit = false;

  @override
  void initState() {
    super.initState();
    _httpService = HttpService();
    _address = widget.addressData;
    _pickupNumber.text = _address.pickupAddressNumber ?? '';
    _deliveryNumber.text = _address.deliveryAddressNumber ?? '';
    _pickupWithoutNumber = _pickupNumber.text == 'S/N';
    _deliveryWithoutNumber = _deliveryNumber.text == 'S/N';
    _pickupComplementController.text = _address.pickupAddressComplement ?? '';
    _pickupReferenceController.text = _address.pickupReferencePoint ?? '';
    _deliveryComplementController.text =
        _address.deliveryAddressComplement ?? '';
    _deliveryReferenceController.text = _address.deliveryReferencePoint ?? '';
    final draft = widget.initialDraft;
    if (draft != null) {
      _widthController.text = draft.fields['width'] ?? '';
      _heightController.text = draft.fields['height'] ?? '';
      _lengthController.text = draft.fields['length'] ?? '';
      _weightController.text = draft.fields['weight'] ?? '';
      final previous = draft.addressData;
      if (sameFreightAddressIdentity(
            previous.pickupAddress,
            _address.pickupAddress,
          ) &&
          previous.pickupAddressNumber == _address.pickupAddressNumber) {
        _pickupNumber.text = draft.fields['pickup_number'] ?? '';
        _pickupWithoutNumber = draft.pickupWithoutNumber;
        _pickupComplementController.text =
            draft.fields['pickup_complement'] ?? '';
        _pickupReferenceController.text =
            draft.fields['pickup_reference'] ?? '';
      }
      if (sameFreightAddressIdentity(
            previous.deliveryAddress,
            _address.deliveryAddress,
          ) &&
          previous.deliveryAddressNumber == _address.deliveryAddressNumber) {
        _deliveryNumber.text = draft.fields['delivery_number'] ?? '';
        _deliveryWithoutNumber = draft.deliveryWithoutNumber;
        _deliveryComplementController.text =
            draft.fields['delivery_complement'] ?? '';
        _deliveryReferenceController.text =
            draft.fields['delivery_reference'] ?? '';
      }
    }
  }

  FreightDetailsDraft _captureDraft() => FreightDetailsDraft(
    addressData: _address,
    pickupWithoutNumber: _pickupWithoutNumber,
    deliveryWithoutNumber: _deliveryWithoutNumber,
    fields: {
      'width': _widthController.text,
      'height': _heightController.text,
      'length': _lengthController.text,
      'weight': _weightController.text,
      'pickup_number': _pickupNumber.text,
      'delivery_number': _deliveryNumber.text,
      'pickup_complement': _pickupComplementController.text,
      'pickup_reference': _pickupReferenceController.text,
      'delivery_complement': _deliveryComplementController.text,
      'delivery_reference': _deliveryReferenceController.text,
    },
  );

  @override
  void dispose() {
    if (!_savedForRouteEdit) widget.onDraftSaved?.call(_captureDraft());
    _httpService.dispose();
    _pickupNumber.dispose();
    _deliveryNumber.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _lengthController.dispose();
    _weightController.dispose();
    _pickupComplementController.dispose();
    _pickupReferenceController.dispose();
    _deliveryComplementController.dispose();
    _deliveryReferenceController.dispose();
    super.dispose();
  }

  void _toggleWithoutNumber(bool pickup, bool value) {
    final controller = pickup ? _pickupNumber : _deliveryNumber;
    setState(() {
      if (pickup) {
        if (value) {
          _previousPickupNumber = controller.text;
        }
        _pickupWithoutNumber = value;
        controller.text = value ? 'S/N' : _previousPickupNumber;
      } else {
        if (value) {
          _previousDeliveryNumber = controller.text;
        }
        _deliveryWithoutNumber = value;
        controller.text = value ? 'S/N' : _previousDeliveryNumber;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        (pickup ? _pickupNumberKey : _deliveryNumberKey).currentState
            ?.validate();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _screenBackground,
      body: SafeArea(
        child: Column(
          children: [
            const _FreightRequestHeader(),
            Expanded(
              child: AbsorbPointer(
                absorbing: _isQuoting,
                child: Form(
                  key: _formKey,
                  autovalidateMode: _autovalidateMode,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 22),
                    children: [
                      const Text(
                        'ETAPA 2 DE 4',
                        style: TextStyle(
                          color: _orange,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Detalhes da Entrega',
                        style: TextStyle(
                          color: FretColors.neutral900,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Confirme os pontos de acesso e conte o que vamos transportar.',
                        style: TextStyle(
                          color: FretColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _AddressEditor(
                        title: 'Coleta',
                        address: _address.pickupAddress,
                        color: _orange,
                        number: _pickupNumber,
                        numberKey: _pickupNumberKey,
                        withoutNumber: _pickupWithoutNumber,
                        onWithoutNumber: (value) =>
                            _toggleWithoutNumber(true, value),
                        complement: _pickupComplementController,
                        reference: _pickupReferenceController,
                      ),
                      const SizedBox(height: 16),
                      _AddressEditor(
                        title: 'Entrega',
                        address: _address.deliveryAddress,
                        color: _primaryBlue,
                        number: _deliveryNumber,
                        numberKey: _deliveryNumberKey,
                        withoutNumber: _deliveryWithoutNumber,
                        onWithoutNumber: (value) =>
                            _toggleWithoutNumber(false, value),
                        complement: _deliveryComplementController,
                        reference: _deliveryReferenceController,
                      ),
                      GeocodingCredit(
                        source:
                            '${_address.pickupAddressSource ?? ''} | ${_address.deliveryAddressSource ?? ''}',
                      ),
                      const SizedBox(height: 16),
                      _PackageDetailsCard(
                        key: _packageKey,
                        widthController: _widthController,
                        heightController: _heightController,
                        lengthController: _lengthController,
                        weightController: _weightController,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _BottomCalculateBar(
              loading: _isQuoting,
              onBackPressed: () => Navigator.of(context).maybePop(),
              onPressed: _goToResume,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _goToResume() async {
    if (_isQuoting) return;
    FocusScope.of(context).unfocus();

    final bool isFormValid = _formKey.currentState?.validate() ?? false;
    if (!isFormValid) {
      final target = _pickupNumberKey.currentState?.hasError == true
          ? _pickupNumberKey.currentContext
          : _deliveryNumberKey.currentState?.hasError == true
          ? _deliveryNumberKey.currentContext
          : _packageKey.currentContext;
      if (target != null) {
        Scrollable.ensureVisible(
          target,
          duration: const Duration(milliseconds: 250),
          alignment: .15,
        );
      }
      setState(() {
        _autovalidateMode = AutovalidateMode.onUserInteraction;
      });
      return;
    }

    final packageData = FreightPackageData(
      widthCm: _parseMetric(_widthController.text),
      heightCm: _parseMetric(_heightController.text),
      lengthCm: _parseMetric(_lengthController.text),
      weightKg: _parseMetric(_weightController.text),
    );
    setState(() => _isQuoting = true);
    try {
      if (!await _confirmNumber(true) || !mounted) return;
      if (!await _confirmNumber(false) || !mounted) return;
      final addressData = _address.copyWith(
        pickupAddressComplement: _optionalText(
          _pickupComplementController.text,
        ),
        pickupReferencePoint: _optionalText(_pickupReferenceController.text),
        deliveryAddressComplement: _optionalText(
          _deliveryComplementController.text,
        ),
        deliveryReferencePoint: _optionalText(
          _deliveryReferenceController.text,
        ),
      );

      final response = await _httpService.post(
        Endpoints.rideQuote,
        body: {...addressData.toRideJson(), ...packageData.toQuoteJson()},
      );
      final quote = FreightQuoteModel.fromJson(response);
      if (!quote.distanceKm.isFinite ||
          quote.distanceKm <= 0 ||
          quote.estimatedTimeMinutes < 1 ||
          quote.routePoints.length < 2 ||
          quote.routePoints.any(
            (point) =>
                !point.latitude.isFinite ||
                !point.longitude.isFinite ||
                point.latitude.abs() > 90 ||
                point.longitude.abs() > 180,
          )) {
        throw const FormatException('A cotação retornou uma rota inválida.');
      }

      if (!mounted) {
        return;
      }

      setState(() => _isQuoting = false);
      final editPickup = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => ShippingResumePage(
            userId: widget.userId,
            addressData: addressData,
            packageData: packageData,
            quote: quote,
          ),
        ),
      );
      if (editPickup != null && mounted) {
        _savedForRouteEdit = true;
        widget.onDraftSaved?.call(_captureDraft());
        Navigator.of(context).pop<bool>(editPickup);
      }
    } on HttpServiceException catch (e) {
      _showMessage(e.message);
    } catch (_) {
      _showMessage('Nao foi possivel calcular o frete agora.');
    } finally {
      if (mounted) {
        setState(() => _isQuoting = false);
      }
    }
  }

  Future<bool> _confirmNumber(bool pickup) async {
    final number = (pickup ? _pickupWithoutNumber : _deliveryWithoutNumber)
        ? 'S/N'
        : (pickup ? _pickupNumber.text : _deliveryNumber.text).trim();
    final previous = pickup
        ? _address.pickupAddressNumber
        : _address.deliveryAddressNumber;
    final base = pickup ? _address.pickupAddress : _address.deliveryAddress;
    AddressResult? match;
    if (number != 'S/N' && number != previous) {
      final response = await _httpService.get(
        Endpoints.rideGeocode(formatFreightAddress(base, number)),
      );
      for (final row in response['data'] as List) {
        final candidate = AddressResult.fromJson(
          Map<String, dynamic>.from(row as Map),
        );
        if (matchesFreightAddressNumber(base, number, candidate)) {
          match = candidate;
          break;
        }
      }
    }
    if (!mounted) return false;
    final previousApproximate = pickup
        ? _address.pickupPointApproximate
        : _address.deliveryPointApproximate;
    final exactMatch =
        number == 'S/N' ||
        match != null ||
        (number == previous && !previousApproximate);
    final initial =
        match?.point ??
        LatLng(
          pickup ? _address.pickupLatitude : _address.deliveryLatitude,
          pickup ? _address.pickupLongitude : _address.deliveryLongitude,
        );
    final confirmed = await showModalBottomSheet<LatLng>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: FretColors.appBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (_) => AddressPointConfirmation(
        title: pickup ? 'Confirmar coleta' : 'Confirmar entrega',
        address: formatFreightAddress(match?.baseAddress ?? base, number),
        initialPoint: initial,
        exactMatch: exactMatch,
        isPickup: pickup,
        source:
            match?.source ??
            (pickup
                ? _address.pickupAddressSource
                : _address.deliveryAddressSource),
      ),
    );
    if (confirmed == null || !mounted) return false;
    final pointChanged =
        confirmed.latitude != initial.latitude ||
        confirmed.longitude != initial.longitude;
    var pickupState =
        match?.state ??
        normalizeFreightState(_address.pickupState) ??
        freightAddressState(base);
    String? pointSource;
    if (pickup && (pointChanged || pickupState == null)) {
      // Resolve the UF of the confirmed coordinate, without changing the
      // customer's street, number or explicitly selected access point.
      final response = await _httpService.get(
        Endpoints.rideReverseGeocode(
          latitude: confirmed.latitude,
          longitude: confirmed.longitude,
        ),
      );
      if (!mounted) return false;
      final rows = response['data'] as List;
      final resolved = rows.isEmpty
          ? null
          : AddressResult.fromJson(
              Map<String, dynamic>.from(rows.first as Map),
            );
      pickupState = resolved?.state;
      pointSource = resolved?.source;
      if (pickupState == null) {
        _showMessage(
          'Não foi possível identificar o estado do ponto de coleta confirmado. Volte à seleção de endereços e busque pela rua e cidade para tentar novamente.',
        );
        return false;
      }
    }
    if (!mounted) return false;
    final pickupSources = <String>{
      for (final source in [
        _address.pickupAddressSource,
        match?.source,
        pointSource,
      ])
        for (final credit in (source ?? '').split('|'))
          if (credit.trim().isNotEmpty) credit.trim(),
    }.join(' | ');
    setState(() {
      _address = pickup
          ? _address.copyWith(
              pickupAddress: match?.baseAddress ?? base,
              pickupAddressNumber: number,
              pickupState: pickupState,
              pickupAddressSource: pickupSources.isEmpty ? null : pickupSources,
              pickupPlaceId: match?.placeId,
              pickupPointApproximate: !exactMatch && !pointChanged,
              pickupLatitude: confirmed.latitude,
              pickupLongitude: confirmed.longitude,
            )
          : _address.copyWith(
              deliveryAddress: match?.baseAddress ?? base,
              deliveryAddressNumber: number,
              deliveryAddressSource: match?.source,
              deliveryPlaceId: match?.placeId,
              deliveryPointApproximate: !exactMatch && !pointChanged,
              deliveryLatitude: confirmed.latitude,
              deliveryLongitude: confirmed.longitude,
            );
    });
    return true;
  }

  double _parseMetric(String value) {
    return double.parse(value.trim().replaceAll(',', '.'));
  }

  String? _optionalText(String value) {
    final cleaned = value.trim();
    if (cleaned.isEmpty) {
      return null;
    }

    return cleaned;
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    showFretErrorPopup(context, message: message);
  }
}

class _FreightRequestHeader extends StatelessWidget {
  const _FreightRequestHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 47,
      decoration: const BoxDecoration(
        color: FretColors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE9EAF0))),
      ),
      child: Row(
        children: [
          const SizedBox(width: 2),
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: _FillInPackageDetailsPageState._primaryBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            'Solicitação de Frete',
            style: TextStyle(
              color: _FillInPackageDetailsPageState._primaryBlue,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _SectionPanel({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: FretColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6E7ED)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08181818),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5EBC2),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  icon,
                  color: _FillInPackageDetailsPageState._primaryBlue,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: FretColors.neutral900,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _AddressEditor extends StatelessWidget {
  final String title;
  final String address;
  final Color color;
  final TextEditingController number;
  final GlobalKey<FormFieldState<String>> numberKey;
  final bool withoutNumber;
  final ValueChanged<bool> onWithoutNumber;
  final TextEditingController complement;
  final TextEditingController reference;
  const _AddressEditor({
    required this.title,
    required this.address,
    required this.color,
    required this.number,
    required this.numberKey,
    required this.withoutNumber,
    required this.onWithoutNumber,
    required this.complement,
    required this.reference,
  });
  @override
  Widget build(BuildContext context) => _SectionPanel(
    icon: title == 'Coleta' ? Icons.trip_origin : Icons.location_on_outlined,
    title: title,
    children: [
      Text(
        address,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.5,
        ),
      ),
      const SizedBox(height: 16),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextFormField(
              key: numberKey,
              controller: number,
              enabled: !withoutNumber,
              maxLength: 20,
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.streetAddress,
              validator: (value) => withoutNumber
                  ? null
                  : (value == null ||
                        value.trim().isEmpty ||
                        !RegExp(r'[0-9]').hasMatch(value))
                  ? 'Informe o número ou marque S/N.'
                  : null,
              decoration: InputDecoration(
                labelText: 'Número *',
                hintText: withoutNumber ? 'S/N' : 'Ex.: 120, 12A',
                counterText: '',
                prefixIcon: Icon(Icons.tag, color: color),
                filled: true,
                fillColor: FretColors.appSurfaceSoft,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 134,
            child: CheckboxListTile(
              value: withoutNumber,
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Sem número\nS/N',
                style: TextStyle(fontSize: 12),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: color,
              onChanged: (value) => onWithoutNumber(value ?? false),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      _OptionalAddressField(
        label: 'Complemento (opcional)',
        controller: complement,
        icon: Icons.apartment_rounded,
        hintText: 'Apto, bloco, sala...',
      ),
      const SizedBox(height: 14),
      _OptionalAddressField(
        label: 'Referência (opcional)',
        controller: reference,
        icon: Icons.near_me_outlined,
        hintText: 'Um ponto que facilite a chegada',
      ),
    ],
  );
}

class _OptionalAddressField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String hintText;

  const _OptionalAddressField({
    required this.label,
    required this.controller,
    required this.icon,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: FretColors.neutral700,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 37),
          child: TextFormField(
            controller: controller,
            textInputAction: TextInputAction.next,
            validator: (value) => _validateOptionalText(value, label),
            style: const TextStyle(
              color: FretColors.neutral800,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: FretColors.neutral050,
              hintText: hintText,
              hintStyle: const TextStyle(
                color: FretColors.neutral400,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Icon(icon, color: FretColors.neutral500, size: 18),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 42,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 0,
                vertical: 11,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: FretColors.neutral200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: FretColors.neutral200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: _FillInPackageDetailsPageState._primaryBlue,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PackageDetailsCard extends StatelessWidget {
  final TextEditingController widthController;
  final TextEditingController heightController;
  final TextEditingController lengthController;
  final TextEditingController weightController;

  const _PackageDetailsCard({
    super.key,
    required this.widthController,
    required this.heightController,
    required this.lengthController,
    required this.weightController,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionPanel(
      icon: Icons.inventory_2_outlined,
      title: 'Encomenda',
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _PackageMetricField(
                label: 'Largura',
                controller: widthController,
                icon: Icons.swap_horiz_rounded,
                unit: 'cm',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _PackageMetricField(
                label: 'Altura',
                controller: heightController,
                icon: Icons.height_rounded,
                unit: 'cm',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _PackageMetricField(
                label: 'Comprimento',
                controller: lengthController,
                icon: Icons.straighten_rounded,
                unit: 'cm',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _PackageMetricField(
                label: 'Peso',
                controller: weightController,
                icon: Icons.shopping_bag,
                iconColor: _FillInPackageDetailsPageState._primaryBlue,
                unit: 'kg',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PackageMetricField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String? unit;
  final Color iconColor;

  const _PackageMetricField({
    required this.label,
    required this.controller,
    required this.icon,
    this.unit,
    this.iconColor = const Color(0xFF737382),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: FretColors.neutral700,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 37),
          child: TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) => _validatePositiveMetric(value, label),
            style: const TextStyle(
              color: FretColors.neutral800,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: FretColors.neutral050,
              hintText: '0.00',
              hintStyle: const TextStyle(
                color: FretColors.neutral400,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Icon(icon, color: iconColor, size: 18),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 38,
                minHeight: 42,
              ),
              suffixIcon: _FieldUnitSuffix(unit: unit),
              suffixIconConstraints: const BoxConstraints(
                minWidth: 42,
                minHeight: 42,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 0,
                vertical: 11,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: FretColors.neutral200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: FretColors.neutral200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: _FillInPackageDetailsPageState._primaryBlue,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FieldUnitSuffix extends StatelessWidget {
  final String? unit;

  const _FieldUnitSuffix({this.unit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Icon(
            Icons.unfold_more_rounded,
            color: Color(0xFF8E90A1),
            size: 14,
          ),
          if (unit != null) ...[
            const SizedBox(width: 6),
            Text(
              unit!,
              style: const TextStyle(
                color: Color(0xFF565867),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String? _validatePositiveMetric(String? value, String label) {
  final String normalizedValue = (value ?? '').trim().replaceAll(',', '.');
  final double? metricValue = double.tryParse(normalizedValue);
  if (metricValue == null || !metricValue.isFinite) {
    return 'Informe ${label.toLowerCase()}.';
  }
  if (metricValue <= 0) {
    return 'O valor deve ser maior que zero.';
  }

  return null;
}

String? _validateOptionalText(String? value, String label) {
  final cleaned = (value ?? '').trim();
  if (cleaned.length > 255) {
    return '$label deve ter ate 255 caracteres.';
  }

  return null;
}

class _BottomCalculateBar extends StatelessWidget {
  final VoidCallback onPressed;
  final VoidCallback onBackPressed;
  final bool loading;

  const _BottomCalculateBar({
    required this.onPressed,
    required this.onBackPressed,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(11, 12, 9, 10),
      color: FretColors.white,
      child: Row(
        children: [
          SizedBox(
            width: 112,
            height: 42,
            child: OutlinedButton.icon(
              onPressed: loading ? null : onBackPressed,
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: const Text(
                'Voltar',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _FillInPackageDetailsPageState._primaryBlue,
                side: const BorderSide(
                  color: _FillInPackageDetailsPageState._primaryBlue,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 42,
              child: ElevatedButton(
                onPressed: loading ? null : onPressed,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: _FillInPackageDetailsPageState._primaryBlue,
                  foregroundColor: FretColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                child: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: FretColors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Calcular frete',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.calculate_outlined, size: 14),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
