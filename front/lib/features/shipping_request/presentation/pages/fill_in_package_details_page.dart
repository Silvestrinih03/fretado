import 'package:flutter/material.dart';

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

  const FillInPackageDetailsPage({
    super.key,
    required this.userId,
    required this.addressData,
  });

  @override
  State<FillInPackageDetailsPage> createState() =>
      _FillInPackageDetailsPageState();
}

class _FillInPackageDetailsPageState extends State<FillInPackageDetailsPage> {
  static const Color _primaryBlue = Color(0xFF080A73);
  static const Color _screenBackground = Color(0xFFF7F8FA);
  static const Color _orange = Color(0xFF9F3F00);

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

  @override
  void initState() {
    super.initState();
    _httpService = HttpService();
  }

  @override
  void dispose() {
    _httpService.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _screenBackground,
      body: SafeArea(
        child: Column(
          children: [
            const _FreightRequestHeader(),
            Expanded(
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
                    _RouteOverviewCard(addressData: widget.addressData),
                    const SizedBox(height: 14),
                    _AddressDetailsCard(
                      pickupComplementController: _pickupComplementController,
                      pickupReferenceController: _pickupReferenceController,
                      deliveryComplementController:
                          _deliveryComplementController,
                      deliveryReferenceController: _deliveryReferenceController,
                    ),
                    const SizedBox(height: 14),
                    _PackageDetailsCard(
                      widthController: _widthController,
                      heightController: _heightController,
                      lengthController: _lengthController,
                      weightController: _weightController,
                    ),
                  ],
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
    FocusScope.of(context).unfocus();

    final bool isFormValid = _formKey.currentState?.validate() ?? false;
    if (!isFormValid) {
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
    final addressData = widget.addressData.copyWith(
      pickupAddressComplement: _optionalText(_pickupComplementController.text),
      pickupReferencePoint: _optionalText(_pickupReferenceController.text),
      deliveryAddressComplement: _optionalText(
        _deliveryComplementController.text,
      ),
      deliveryReferencePoint: _optionalText(_deliveryReferenceController.text),
    );

    setState(() => _isQuoting = true);
    try {
      final response = await _httpService.post(
        Endpoints.rideQuote,
        body: {...addressData.toRideJson(), ...packageData.toQuoteJson()},
      );
      final quote = FreightQuoteModel.fromJson(response);

      if (!mounted) {
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ShippingResumePage(
            userId: widget.userId,
            addressData: addressData,
            packageData: packageData,
            quote: quote,
          ),
        ),
      );
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

class _RouteOverviewCard extends StatelessWidget {
  final FreightAddressData addressData;

  const _RouteOverviewCard({required this.addressData});

  @override
  Widget build(BuildContext context) {
    return _SectionPanel(
      icon: Icons.alt_route_rounded,
      title: 'Rota selecionada',
      children: [
        _RouteOverviewStop(
          label: 'Coleta',
          address: addressData.pickupAddress,
          color: _FillInPackageDetailsPageState._orange,
          showConnector: true,
        ),
        _RouteOverviewStop(
          label: 'Entrega',
          address: addressData.deliveryAddress,
          color: _FillInPackageDetailsPageState._primaryBlue,
        ),
      ],
    );
  }
}

class _RouteOverviewStop extends StatelessWidget {
  final String label;
  final String address;
  final Color color;
  final bool showConnector;

  const _RouteOverviewStop({
    required this.label,
    required this.address,
    required this.color,
    this.showConnector = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 22,
          child: Column(
            children: [
              const SizedBox(height: 6),
              Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              if (showConnector)
                Container(
                  width: 1,
                  height: 30,
                  color: const Color(0xFFE0E2EA),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: showConnector ? 12 : 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    color: FretColors.neutral500,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FretColors.neutral900,
                    fontSize: 13,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE6E7ED)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08080A73),
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
                  color: const Color(0xFFF1F2F8),
                  borderRadius: BorderRadius.circular(8),
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

class _AddressDetailsCard extends StatelessWidget {
  final TextEditingController pickupComplementController;
  final TextEditingController pickupReferenceController;
  final TextEditingController deliveryComplementController;
  final TextEditingController deliveryReferenceController;

  const _AddressDetailsCard({
    required this.pickupComplementController,
    required this.pickupReferenceController,
    required this.deliveryComplementController,
    required this.deliveryReferenceController,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionPanel(
      icon: Icons.edit_location_alt_outlined,
      title: 'Detalhes dos enderecos',
      children: [
        const _FieldGroupLabel(text: 'Coleta'),
        const SizedBox(height: 8),
        _OptionalAddressField(
          label: 'Complemento',
          controller: pickupComplementController,
          icon: Icons.apartment_rounded,
          hintText: 'Apto, bloco, sala...',
        ),
        const SizedBox(height: 12),
        _OptionalAddressField(
          label: 'Referencia',
          controller: pickupReferenceController,
          icon: Icons.near_me_outlined,
          hintText: 'Proximo a...',
        ),
        const SizedBox(height: 16),
        const _FieldGroupLabel(text: 'Entrega'),
        const SizedBox(height: 8),
        _OptionalAddressField(
          label: 'Complemento',
          controller: deliveryComplementController,
          icon: Icons.apartment_rounded,
          hintText: 'Apto, bloco, sala...',
        ),
        const SizedBox(height: 12),
        _OptionalAddressField(
          label: 'Referencia',
          controller: deliveryReferenceController,
          icon: Icons.near_me_outlined,
          hintText: 'Proximo a...',
        ),
      ],
    );
  }
}

class _FieldGroupLabel extends StatelessWidget {
  final String text;

  const _FieldGroupLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: _FillInPackageDetailsPageState._orange,
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 0,
      ),
    );
  }
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
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: FretColors.neutral200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: FretColors.neutral200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
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
    required this.widthController,
    required this.heightController,
    required this.lengthController,
    required this.weightController,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionPanel(
      icon: Icons.inventory_2_outlined,
      title: 'Caracteristicas do produto',
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
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: FretColors.neutral200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: FretColors.neutral200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
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
  if (metricValue == null) {
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
                            'Calcular Valor',
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
