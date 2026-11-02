import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../../app/design_system/design_system.dart';
import '../../../../core/endpoints.dart';
import '../../../../core/maps/address_result.dart';
import '../../../../core/maps/fret_map.dart';
import '../../../../core/maps/geocoding_credit.dart';
import '../../../../core/services/http_service.dart';
import '../models/freight_address_data.dart';
import 'fill_in_package_details_page.dart';

class AddressMapPage extends StatefulWidget {
  final int userId;
  const AddressMapPage({super.key, required this.userId});
  @override
  State<AddressMapPage> createState() => _AddressMapPageState();
}

class _AddressMapPageState extends State<AddressMapPage> {
  final _http = HttpService();
  final _map = FretMapController();
  final _pickupText = TextEditingController();
  final _deliveryText = TextEditingController();
  static const _center = LatLng(-22.9056, -47.0608);
  AddressResult? _pickup;
  AddressResult? _delivery;
  LatLng? _position;
  List<LatLng> _route = [];
  List<AddressResult> _suggestions = [];
  Timer? _debounce;
  bool _pickupActive = true;
  bool _searching = false;
  bool _locating = false;
  int _searchVersion = 0;
  int _routeVersion = 0;
  String? _searchError;
  FreightDetailsDraft? _detailsDraft;

  @override
  void dispose() {
    _debounce?.cancel();
    _http.dispose();
    _map.dispose();
    _pickupText.dispose();
    _deliveryText.dispose();
    super.dispose();
  }

  void _changed(bool pickup, String value) {
    _debounce?.cancel();
    final version = ++_searchVersion;
    ++_routeVersion;
    setState(() {
      _pickupActive = pickup;
      _suggestions = [];
      _searchError = null;
      _route = [];
      _searching = false;
      if (pickup) {
        _pickup = null;
      } else {
        _delivery = null;
      }
    });
    if (value.trim().length >= 3) {
      _debounce = Timer(
        const Duration(milliseconds: 500),
        () => _search(pickup, value.trim(), version),
      );
    }
  }

  Future<void> _search(bool pickup, String query, int version) async {
    if (!mounted || version != _searchVersion) return;
    setState(() => _searching = true);
    try {
      final result = await _http.get(Endpoints.rideGeocode(query));
      if (!mounted || version != _searchVersion) return;
      setState(() {
        _suggestions = (result['data'] as List)
            .map(
              (e) =>
                  AddressResult.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList();
        _searchError = _suggestions.isEmpty
            ? 'Nenhum endereço encontrado. Inclua bairro e cidade.'
            : null;
      });
    } on HttpServiceException catch (error) {
      if (mounted && version == _searchVersion) {
        setState(() => _searchError = error.message);
      }
    } catch (_) {
      if (mounted && version == _searchVersion) {
        setState(
          () => _searchError =
              'Não foi possível buscar. Toque na lupa para tentar novamente.',
        );
      }
    } finally {
      if (mounted && version == _searchVersion) {
        setState(() => _searching = false);
      }
    }
  }

  void _select(bool pickup, AddressResult result) {
    FocusScope.of(context).unfocus();
    _debounce?.cancel();
    ++_searchVersion;
    setState(() {
      if (pickup) {
        _pickup = result;
        _pickupText.text = result.label;
      } else {
        _delivery = result;
        _deliveryText.text = result.label;
      }
      _suggestions = [];
      _searchError = null;
      _searching = false;
      _route = [];
    });
    _focusRoute();
    unawaited(_previewRoute());
  }

  void _focusRoute() {
    final points = [
      if (_pickup != null) _pickup!.point,
      ..._route,
      if (_delivery != null) _delivery!.point,
    ];
    _map.fit(points, padding: const EdgeInsets.fromLTRB(48, 240, 48, 130));
  }

  Future<void> _previewRoute() async {
    final pickup = _pickup;
    final delivery = _delivery;
    final version = ++_routeVersion;
    if (pickup == null || delivery == null) return;
    try {
      final result = await _http.get(
        Endpoints.rideRoutePreview(
          originLatitude: pickup.point.latitude,
          originLongitude: pickup.point.longitude,
          destinationLatitude: delivery.point.latitude,
          destinationLongitude: delivery.point.longitude,
        ),
      );
      if (!mounted || version != _routeVersion) return;
      setState(
        () => _route = (result['geometry'] as List)
            .map(
              (p) => LatLng((p[1] as num).toDouble(), (p[0] as num).toDouble()),
            )
            .toList(),
      );
      _focusRoute();
    } catch (_) {
      if (mounted && version == _routeVersion) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Prévia da rota indisponível. Você pode preencher os detalhes e tentar calcular o frete.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _pin(LatLng point) async {
    if (_locating) return;
    final pickup = _pickupActive;
    _debounce?.cancel();
    final version = ++_searchVersion;
    setState(() {
      _locating = true;
      _suggestions = [];
      _searching = false;
    });
    try {
      final response = await _http.get(
        Endpoints.rideReverseGeocode(
          latitude: point.latitude,
          longitude: point.longitude,
        ),
      );
      if (!mounted || version != _searchVersion) return;
      final data = response['data'] as List;
      if (data.isEmpty) {
        _message(
          'Não encontramos um endereço neste ponto. Busque pela rua e cidade.',
        );
        return;
      }
      final found = AddressResult.fromJson(
        Map<String, dynamic>.from(data.first as Map),
      );
      // Keep the explicitly selected coordinate instead of silently snapping it.
      _select(
        pickup,
        AddressResult(
          label: found.label,
          baseAddress: found.baseAddress,
          point: point,
          number: found.number,
          street: found.street,
          state: found.state,
          source: found.source,
          placeId: found.placeId,
        ),
      );
    } on HttpServiceException catch (error) {
      if (mounted && version == _searchVersion) _message(error.message);
    } catch (_) {
      if (mounted && version == _searchVersion) {
        _message('Não foi possível identificar o endereço. Tente novamente.');
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _currentLocation() async {
    if (_locating) return;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _message('Ative o GPS para usar sua localização.');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _message('Permita o acesso ? localização nas configurações.');
        return;
      }
      final location = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          timeLimit: Duration(seconds: 15),
        ),
      );
      if (!mounted) return;
      setState(() => _position = LatLng(location.latitude, location.longitude));
      _map.move(_position!, 16);
      await _pin(_position!);
    } catch (_) {
      if (mounted) _message('Não foi possível obter sua localização.');
    }
  }

  void _continue() {
    final pickup = _pickup;
    final delivery = _delivery;
    if (pickup == null || delivery == null) {
      _message('Selecione os endereços de coleta e entrega.');
      return;
    }
    if (pickup.point == delivery.point) {
      _message('Coleta e entrega devem ser diferentes.');
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FillInPackageDetailsPage(
          userId: widget.userId,
          initialDraft: _detailsDraft,
          onDraftSaved: _saveDetailsDraft,
          addressData: FreightAddressData(
            pickupState: pickup.state,
            pickupAddress: pickup.baseAddress,
            pickupAddressNumber: pickup.number,
            pickupAddressSource: pickup.source,
            pickupLatitude: pickup.point.latitude,
            pickupLongitude: pickup.point.longitude,
            pickupPlaceId: pickup.placeId,
            deliveryAddress: delivery.baseAddress,
            deliveryAddressNumber: delivery.number,
            deliveryAddressSource: delivery.source,
            deliveryLatitude: delivery.point.latitude,
            deliveryLongitude: delivery.point.longitude,
            deliveryPlaceId: delivery.placeId,
          ),
        ),
      ),
    );
  }

  void _saveDetailsDraft(FreightDetailsDraft draft) {
    _detailsDraft = draft;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
      final address = draft.addressData;
      setState(() {
        _pickup = AddressResult(
          label: address.originAddress,
          baseAddress: address.pickupAddress,
          point: LatLng(address.pickupLatitude, address.pickupLongitude),
          number: address.pickupAddressNumber,
          state: address.pickupState,
          source: address.pickupAddressSource,
          placeId: address.pickupPlaceId,
        );
        _delivery = AddressResult(
          label: address.destinationAddress,
          baseAddress: address.deliveryAddress,
          point: LatLng(address.deliveryLatitude, address.deliveryLongitude),
          number: address.deliveryAddressNumber,
          source: address.deliveryAddressSource,
          placeId: address.deliveryPlaceId,
        );
        _pickupText.text = _pickup!.label;
        _deliveryText.text = _delivery!.label;
        _route = [];
      });
      _focusRoute();
      unawaited(_previewRoute());
    });
  }

  void _message(String text) => showFretErrorPopup(context, message: text);

  Widget _field(bool pickup) {
    final controller = pickup ? _pickupText : _deliveryText;
    final selected = pickup ? _pickup != null : _delivery != null;
    return TextField(
      controller: controller,
      textCapitalization: TextCapitalization.words,
      onTap: () {
        if (_pickupActive != pickup) {
          _debounce?.cancel();
          ++_searchVersion;
          setState(() {
            _pickupActive = pickup;
            _suggestions = [];
            _searching = false;
            _searchError = null;
          });
        }
      },
      onChanged: (value) => _changed(pickup, value),
      onSubmitted: (query) {
        _debounce?.cancel();
        _search(pickup, query, ++_searchVersion);
      },
      decoration: InputDecoration(
        labelText: pickup ? 'Onde vamos coletar?' : 'Onde vamos entregar?',
        hintText: 'Rua, bairro e cidade',
        filled: true,
        fillColor: FretColors.appSurfaceSoft,
        prefixIcon: Icon(
          pickup ? Icons.trip_origin : Icons.location_on_outlined,
          color: pickup ? FretColors.brandGoldDark : FretColors.brandGraphite,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            selected ? Icons.check_circle_rounded : Icons.search,
            color: selected ? FretColors.success700 : FretColors.brandGraphite,
          ),
          onPressed: () {
            _debounce?.cancel();
            _pickupActive = pickup;
            _search(pickup, controller.text.trim(), ++_searchVersion);
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: FretColors.appBorder),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: FretColors.appBackground,
    appBar: AppBar(
      title: const Text('Solicitar frete'),
      backgroundColor: Colors.white,
    ),
    body: Stack(
      children: [
        Positioned.fill(
          child: FretMap(
            controller: _map,
            initialCenter: _center,
            pickup: _pickup?.point,
            delivery: _delivery?.point,
            position: _position,
            routePoints: _route,
            onTap: _pin,
          ),
        ),
        Positioned(
          top: 12,
          left: 16,
          right: 16,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * .60,
            ),
            child: Material(
              color: Colors.white,
              elevation: 3,
              borderRadius: BorderRadius.circular(20),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '01  /  TRAJETO',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.3,
                        color: FretColors.brandGoldDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _field(true),
                    const SizedBox(height: 12),
                    _field(false),
                    const SizedBox(height: 10),
                    Text(
                      'Toque no mapa para ajustar a ${_pickupActive ? 'coleta' : 'entrega'}.',
                      style: const TextStyle(
                        color: FretColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    if (_searching || _locating)
                      const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: LinearProgressIndicator(),
                      ),
                    if (_searchError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          _searchError!,
                          style: const TextStyle(
                            color: FretColors.destructive600,
                          ),
                        ),
                      ),
                    for (final suggestion in _suggestions)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.place_outlined),
                        title: Text(
                          suggestion.label,
                          style: const TextStyle(fontSize: 13),
                        ),
                        onTap: () => _select(_pickupActive, suggestion),
                      ),
                    GeocodingCredit(
                      source: [
                        if (_pickup?.source != null) _pickup!.source!,
                        if (_delivery?.source != null) _delivery!.source!,
                        ..._suggestions.map((result) => result.source ?? ''),
                      ].join(' | '),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: 16,
          bottom: 100,
          child: FloatingActionButton.small(
            heroTag: 'freight-location',
            backgroundColor: Colors.white,
            onPressed: _locating ? null : _currentLocation,
            tooltip: 'Usar localização no ponto selecionado',
            child: const Icon(
              Icons.my_location,
              color: FretColors.brandGraphite,
            ),
          ),
        ),
      ],
    ),
    bottomNavigationBar: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: FilledButton.icon(
          onPressed: _searching || _locating ? null : _continue,
          style: FilledButton.styleFrom(
            backgroundColor: FretColors.brandGraphite,
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          label: const Text('Continuar para os detalhes'),
          icon: const Icon(Icons.arrow_forward_rounded),
        ),
      ),
    ),
  );
}
