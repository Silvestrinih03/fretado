import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../app/design_system/design_system.dart';
import '../../../../core/endpoints.dart';
import '../../../../core/services/http_service.dart';
import '../models/freight_address_data.dart';
import 'fill_in_package_details_page.dart';

enum _AddressPointMode { pickup, delivery }

class AddressMapPage extends StatefulWidget {
  final int userId;

  const AddressMapPage({super.key, required this.userId});

  @override
  State<AddressMapPage> createState() => _AddressMapPageState();
}

class _AddressMapPageState extends State<AddressMapPage> {
  static const Color _primaryBlue = Color(0xFF080A73);
  static const Color _originOrange = Color(0xFF9F3F00);
  static const Color _screenBackground = Color(0xFFF7F8FA);
  static const Color _fieldBackground = Color(0xFFE8E8EA);
  static const Color _mutedText = Color(0xFF3F4050);
  static const LatLng _initialCenter = LatLng(-23.550520, -46.633308);
  static const Duration _minSearchInterval = Duration(seconds: 1);
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final MapController _mapController = MapController();
  final HttpService _httpService = HttpService();
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _deliveryController = TextEditingController();

  _AddressResult? _pickupAddress;
  _AddressResult? _deliveryAddress;
  LatLng? _userLocation;
  _AddressPointMode? _searchingMode;
  bool _loadingLocation = false;
  bool _selectingPickupFromCurrentLocation = false;
  DateTime? _lastSearchAt;

  bool get _isSearching =>
      _searchingMode != null || _selectingPickupFromCurrentLocation;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation(silent: true);
  }

  @override
  void dispose() {
    _mapController.dispose();
    _httpService.dispose();
    _pickupController.dispose();
    _deliveryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: _screenBackground,
      body: SafeArea(
        child: Column(
          children: [
            const _RequestHeader(),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(child: _buildMap()),
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: _AddressRouteCard(
                        pickupController: _pickupController,
                        deliveryController: _deliveryController,
                        isSearchingPickup:
                            _searchingMode == _AddressPointMode.pickup ||
                            _selectingPickupFromCurrentLocation,
                        isSearchingDelivery:
                            _searchingMode == _AddressPointMode.delivery,
                        pickupSelected: _pickupAddress != null,
                        deliverySelected: _deliveryAddress != null,
                        onPickupSearch: () {
                          _searchAddress(_AddressPointMode.pickup);
                        },
                        onDeliverySearch: () {
                          _searchAddress(_AddressPointMode.delivery);
                        },
                        onPickupChanged: (value) {
                          _clearSelectionIfEdited(
                            _AddressPointMode.pickup,
                            value,
                          );
                        },
                        onDeliveryChanged: (value) {
                          _clearSelectionIfEdited(
                            _AddressPointMode.delivery,
                            value,
                          );
                        },
                        pickupValidator: (value) {
                          return _validateAddress(
                            _AddressPointMode.pickup,
                            value,
                          );
                        },
                        deliveryValidator: (value) {
                          return _validateAddress(
                            _AddressPointMode.delivery,
                            value,
                          );
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    right: 15,
                    bottom: 86,
                    child: _MapActionButton(
                      tooltip: 'Usar local atual como coleta',
                      onPressed: _useCurrentLocationAsPickup,
                      icon: Icons.add_location_alt_rounded,
                      loading: _selectingPickupFromCurrentLocation,
                    ),
                  ),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 14,
                    child: _ContinueButton(
                      loading: _isSearching,
                      onPressed: _continueToPackageDetails,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    final List<LatLng> routePoints = [
      if (_pickupAddress != null) _pickupAddress!.point,
      if (_deliveryAddress != null) _deliveryAddress!.point,
    ];
    final LatLng center = _userLocation ?? _initialCenter;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(initialCenter: center, initialZoom: 12),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.fretado',
        ),
        if (routePoints.length == 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: routePoints,
                strokeWidth: 4,
                color: _primaryBlue,
                borderStrokeWidth: 2,
                borderColor: FretColors.white,
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            if (_pickupAddress != null)
              Marker(
                point: _pickupAddress!.point,
                width: 64,
                height: 64,
                child: const _MapPin(
                  color: _originOrange,
                  icon: Icons.radio_button_checked,
                  label: 'Coleta',
                ),
              ),
            if (_deliveryAddress != null)
              Marker(
                point: _deliveryAddress!.point,
                width: 64,
                height: 64,
                child: const _MapPin(
                  color: _primaryBlue,
                  icon: Icons.location_on,
                  label: 'Entrega',
                ),
              ),
            if (_userLocation != null)
              Marker(
                point: _userLocation!,
                width: 28,
                height: 28,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9F0FF),
                    shape: BoxShape.circle,
                    border: Border.all(color: _primaryBlue, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x22080A73),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.person_pin_circle_rounded,
                      color: _primaryBlue,
                      size: 16,
                    ),
                  ),
                ),
              ),
          ],
        ),
        RichAttributionWidget(
          alignment: AttributionAlignment.bottomLeft,
          attributions: [
            TextSourceAttribution(
              'OpenStreetMap contributors',
              textStyle: TextStyle(
                color: FretColors.neutral800.withValues(alpha: 0.86),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _searchAddress(_AddressPointMode mode) async {
    final TextEditingController controller = _controllerFor(mode);
    final String query = controller.text.trim();

    if (query.length < 3) {
      _showMessage('Digite pelo menos 3 caracteres para buscar o endereço.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _searchingMode = mode);

    try {
      await _respectSearchLimit();
      final Map<String, dynamic> response = await _httpService.get(
        Endpoints.rideGeocode(query),
      );
      final List<_AddressResult> results =
          (response['data'] as List<dynamic>? ?? <dynamic>[])
              .whereType<Map<String, dynamic>>()
              .map(_AddressResult.fromGeocodeJson)
              .whereType<_AddressResult>()
              .toList();

      if (!mounted) {
        return;
      }

      if (results.isEmpty) {
        _showMessage('Nenhum endereço encontrado. Tente ser mais específico.');
        return;
      }

      final _AddressResult? selected =
          await showModalBottomSheet<_AddressResult>(
            context: context,
            showDragHandle: true,
            builder: (context) => _AddressResultsSheet(
              title: mode == _AddressPointMode.pickup
                  ? 'Escolha a coleta'
                  : 'Escolha a entrega',
              results: results,
            ),
          );

      if (selected == null || !mounted) {
        return;
      }

      _selectAddress(mode, selected);
    } on HttpServiceException catch (e) {
      _showMessage(e.message);
    } catch (_) {
      _showMessage('Erro ao consultar endereços. Verifique sua conexão.');
    } finally {
      if (mounted) {
        setState(() => _searchingMode = null);
      }
    }
  }

  Future<void> _respectSearchLimit() async {
    final DateTime now = DateTime.now();
    final DateTime? lastSearchAt = _lastSearchAt;

    if (lastSearchAt != null) {
      final Duration elapsed = now.difference(lastSearchAt);
      if (elapsed < _minSearchInterval) {
        await Future<void>.delayed(_minSearchInterval - elapsed);
      }
    }

    _lastSearchAt = DateTime.now();
  }

  void _selectAddress(_AddressPointMode mode, _AddressResult result) {
    setState(() {
      if (mode == _AddressPointMode.pickup) {
        _pickupAddress = result;
        _pickupController.text = result.label;
      } else {
        _deliveryAddress = result;
        _deliveryController.text = result.label;
      }
    });

    _focusSelectedAddresses();
  }

  void _focusSelectedAddresses() {
    final List<LatLng> points = [
      if (_pickupAddress != null) _pickupAddress!.point,
      if (_deliveryAddress != null) _deliveryAddress!.point,
    ];

    if (points.length == 2) {
      _mapController.fitCamera(
        CameraFit.coordinates(
          coordinates: points,
          padding: const EdgeInsets.fromLTRB(72, 210, 72, 120),
          maxZoom: 15,
        ),
      );
      return;
    }

    if (points.length == 1) {
      _mapController.move(points.first, 16);
      return;
    }

    _mapController.move(_initialCenter, 12);
  }

  Future<void> _loadCurrentLocation({bool silent = false}) async {
    if (_loadingLocation) {
      return;
    }

    setState(() => _loadingLocation = true);
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!silent) {
          _showMessage(
            'Ative a localização do aparelho para usar esse atalho.',
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!silent) {
          _showMessage('Permita o acesso à localização para usar esse atalho.');
        }
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final LatLng location = LatLng(position.latitude, position.longitude);

      if (!mounted) {
        return;
      }

      setState(() => _userLocation = location);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _mapController.move(location, 15);
        }
      });
    } catch (_) {
      if (!silent) {
        _showMessage('Não foi possível obter sua localização.');
      }
    } finally {
      if (mounted) {
        setState(() => _loadingLocation = false);
      }
    }
  }

  Future<void> _useCurrentLocationAsPickup() async {
    if (_selectingPickupFromCurrentLocation || _loadingLocation) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _selectingPickupFromCurrentLocation = true);

    try {
      if (_userLocation == null) {
        await _loadCurrentLocation();
      }

      final LatLng? location = _userLocation;
      if (location == null) {
        return;
      }

      final _AddressResult result = await _buildCurrentLocationAddress(
        location,
      );
      if (!mounted) {
        return;
      }

      _selectAddress(_AddressPointMode.pickup, result);
      _showMessage(
        'Localizacao atual selecionada para coleta.',
        isError: false,
      );
    } finally {
      if (mounted) {
        setState(() => _selectingPickupFromCurrentLocation = false);
      }
    }
  }

  Future<_AddressResult> _buildCurrentLocationAddress(LatLng location) async {
    try {
      final Map<String, dynamic> response = await _httpService.get(
        Endpoints.rideReverseGeocode(
          latitude: location.latitude,
          longitude: location.longitude,
        ),
      );
      final List<_AddressResult> results =
          (response['data'] as List<dynamic>? ?? <dynamic>[])
              .whereType<Map<String, dynamic>>()
              .map(_AddressResult.fromGeocodeJson)
              .whereType<_AddressResult>()
              .toList();

      if (results.isEmpty) {
        return _fallbackCurrentLocationAddress(location);
      }

      return results.first;
    } catch (_) {
      return _fallbackCurrentLocationAddress(location);
    }
  }

  _AddressResult _fallbackCurrentLocationAddress(LatLng location) {
    return _AddressResult(
      label: 'Minha localizacao atual',
      point: location,
      addressLine2:
          '${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}',
    );
  }

  void _clearSelectionIfEdited(_AddressPointMode mode, String value) {
    final _AddressResult? selected = _selectedAddressFor(mode);
    if (selected == null || selected.label == value.trim()) {
      return;
    }

    setState(() {
      if (mode == _AddressPointMode.pickup) {
        _pickupAddress = null;
      } else {
        _deliveryAddress = null;
      }
    });
  }

  String? _validateAddress(_AddressPointMode mode, String? value) {
    final String text = value?.trim() ?? '';
    if (text.isEmpty) {
      return mode == _AddressPointMode.pickup
          ? 'Informe o endereço de coleta.'
          : 'Informe o endereço de entrega.';
    }

    final _AddressResult? selected = _selectedAddressFor(mode);
    if (selected == null || selected.label != text) {
      return 'Busque e selecione um endereço da lista.';
    }

    return null;
  }

  void _continueToPackageDetails() {
    final bool isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      _showMessage('Preencha coleta e entrega antes de continuar.');
      return;
    }

    final FreightAddressData addressData = FreightAddressData(
      pickupAddress: _pickupAddress!.label,
      pickupLatitude: _pickupAddress!.point.latitude,
      pickupLongitude: _pickupAddress!.point.longitude,
      pickupPlaceId: _pickupAddress!.placeId,
      deliveryAddress: _deliveryAddress!.label,
      deliveryLatitude: _deliveryAddress!.point.latitude,
      deliveryLongitude: _deliveryAddress!.point.longitude,
      deliveryPlaceId: _deliveryAddress!.placeId,
    );

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FillInPackageDetailsPage(
          userId: widget.userId,
          addressData: addressData,
        ),
      ),
    );
  }

  TextEditingController _controllerFor(_AddressPointMode mode) {
    return mode == _AddressPointMode.pickup
        ? _pickupController
        : _deliveryController;
  }

  _AddressResult? _selectedAddressFor(_AddressPointMode mode) {
    return mode == _AddressPointMode.pickup ? _pickupAddress : _deliveryAddress;
  }

  void _showMessage(String message, {bool isError = true}) {
    if (!mounted) {
      return;
    }

    if (isError) {
      showFretErrorPopup(context, message: message);
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _RequestHeader extends StatelessWidget {
  const _RequestHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 58,
      color: const Color(0xFFF7FAFB),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 12,
            child: IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: FretColors.black,
                size: 28,
              ),
            ),
          ),
          const Text(
            'Solicitar Frete',
            style: TextStyle(
              color: FretColors.black,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressRouteCard extends StatelessWidget {
  final TextEditingController pickupController;
  final TextEditingController deliveryController;
  final bool isSearchingPickup;
  final bool isSearchingDelivery;
  final bool pickupSelected;
  final bool deliverySelected;
  final VoidCallback onPickupSearch;
  final VoidCallback onDeliverySearch;
  final ValueChanged<String> onPickupChanged;
  final ValueChanged<String> onDeliveryChanged;
  final FormFieldValidator<String> pickupValidator;
  final FormFieldValidator<String> deliveryValidator;

  const _AddressRouteCard({
    required this.pickupController,
    required this.deliveryController,
    required this.isSearchingPickup,
    required this.isSearchingDelivery,
    required this.pickupSelected,
    required this.deliverySelected,
    required this.onPickupSearch,
    required this.onDeliverySearch,
    required this.onPickupChanged,
    required this.onDeliveryChanged,
    required this.pickupValidator,
    required this.deliveryValidator,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: FretColors.white,
      elevation: 6,
      shadowColor: FretColors.black.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(width: 28, height: 128, child: _RouteIcons()),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                children: [
                  _RouteAddressField(
                    controller: pickupController,
                    label: 'Endereço de coleta',
                    hintText: 'Rua, número, bairro, cidade',
                    selected: pickupSelected,
                    loading: isSearchingPickup,
                    textInputAction: TextInputAction.next,
                    onSearch: onPickupSearch,
                    onChanged: onPickupChanged,
                    validator: pickupValidator,
                  ),
                  const SizedBox(height: 12),
                  _RouteAddressField(
                    controller: deliveryController,
                    label: 'Endereço de entrega',
                    hintText: 'Rua, número, bairro, cidade',
                    selected: deliverySelected,
                    loading: isSearchingDelivery,
                    textInputAction: TextInputAction.search,
                    onSearch: onDeliverySearch,
                    onChanged: onDeliveryChanged,
                    validator: deliveryValidator,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteIcons extends StatelessWidget {
  const _RouteIcons();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: const [
        Positioned(
          top: 26,
          bottom: 26,
          child: CustomPaint(
            size: Size(1, double.infinity),
            painter: _DottedLinePainter(),
          ),
        ),
        Positioned(
          top: 7,
          child: Icon(
            Icons.radio_button_checked,
            color: _AddressMapPageState._originOrange,
            size: 18,
          ),
        ),
        Positioned(
          bottom: 7,
          child: Icon(
            Icons.location_on_outlined,
            color: _AddressMapPageState._primaryBlue,
            size: 20,
          ),
        ),
      ],
    );
  }
}

class _RouteAddressField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final bool selected;
  final bool loading;
  final TextInputAction textInputAction;
  final VoidCallback onSearch;
  final ValueChanged<String> onChanged;
  final FormFieldValidator<String> validator;

  const _RouteAddressField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.selected,
    required this.loading,
    required this.textInputAction,
    required this.onSearch,
    required this.onChanged,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: (_) => onSearch(),
      textInputAction: textInputAction,
      textCapitalization: TextCapitalization.words,
      style: const TextStyle(
        color: FretColors.neutral800,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: _AddressMapPageState._fieldBackground,
        labelText: label,
        hintText: hintText,
        labelStyle: const TextStyle(
          color: _AddressMapPageState._mutedText,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: const TextStyle(
          color: Color(0xFF8D90A0),
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        suffixIcon: loading
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : IconButton(
                onPressed: onSearch,
                icon: Icon(
                  selected ? Icons.check_circle : Icons.search_rounded,
                  color: selected
                      ? const Color(0xFF159947)
                      : _AddressMapPageState._primaryBlue,
                ),
              ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: FretColors.destructive500),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(
            color: _AddressMapPageState._primaryBlue,
          ),
        ),
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;

  const _MapPin({required this.color, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: FretColors.white, size: 22),
        ),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: FretColors.white,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _MapActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final bool loading;
  final String tooltip;

  const _MapActionButton({
    required this.onPressed,
    required this.icon,
    required this.tooltip,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: FretColors.white,
        borderRadius: BorderRadius.circular(8),
        elevation: 2,
        child: InkWell(
          onTap: loading ? null : onPressed,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 48,
            height: 48,
            child: loading
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    icon,
                    color: _AddressMapPageState._primaryBlue,
                    size: 26,
                  ),
          ),
        ),
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onPressed;

  const _ContinueButton({required this.loading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: _AddressMapPageState._primaryBlue,
          foregroundColor: FretColors.white,
          disabledBackgroundColor: FretColors.neutral400,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
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
                    'Continuar',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(width: 16),
                  Icon(Icons.arrow_forward_rounded, size: 30),
                ],
              ),
      ),
    );
  }
}

class _AddressResultsSheet extends StatelessWidget {
  final String title;
  final List<_AddressResult> results;

  const _AddressResultsSheet({required this.title, required this.results});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
            child: Text(
              title,
              style: const TextStyle(
                color: FretColors.neutral900,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: results.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final _AddressResult result = results[index];
                return ListTile(
                  leading: const Icon(
                    Icons.location_on_outlined,
                    color: _AddressMapPageState._primaryBlue,
                  ),
                  title: Text(
                    result.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    result.addressLine2 ?? result.coordinateLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => Navigator.of(context).pop(result),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  const _DottedLinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color(0xFFE6E6EA)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    double y = 0;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(0, y + 4), paint);
      y += 11;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AddressResult {
  final String label;
  final LatLng point;
  final String? placeId;
  final String? addressLine1;
  final String? addressLine2;

  const _AddressResult({
    required this.label,
    required this.point,
    this.placeId,
    this.addressLine1,
    this.addressLine2,
  });

  String get coordinateLabel {
    return '${point.latitude.toStringAsFixed(5)}, '
        '${point.longitude.toStringAsFixed(5)}';
  }

  static _AddressResult? fromGeocodeJson(Map<String, dynamic> json) {
    final String label = json['label']?.toString().trim() ?? '';
    final double? latitude = double.tryParse(json['latitude']?.toString() ?? '');
    final double? longitude = double.tryParse(
      json['longitude']?.toString() ?? '',
    );

    if (label.isEmpty || latitude == null || longitude == null) {
      return null;
    }

    final LatLng point = LatLng(latitude, longitude);

    return _AddressResult(
      label: label,
      point: point,
      addressLine2:
          '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}',
    );
  }
}

