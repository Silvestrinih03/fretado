import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide NavigationDestination;
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/design_system/design_system.dart';
import '../../../../core/maps/fret_map.dart';
import '../../../../core/maps/geocoding_credit.dart';
import '../../../../core/services/http_service.dart';
import '../../../../core/services/session/session_storage.dart';
import '../../../driver_operations/data/models/driver_operation_models.dart';
import '../../../ride_rating/presentation/pages/ride_rating_page.dart';
import '../../data/driver_navigation_models.dart';
import '../../data/driver_navigation_repository.dart';

class DriverNavigationPage extends StatefulWidget {
  final int rideId;
  final int userId;
  const DriverNavigationPage({
    super.key,
    required this.rideId,
    required this.userId,
  });
  @override
  State<DriverNavigationPage> createState() => _DriverNavigationPageState();
}

class _DriverNavigationPageState extends State<DriverNavigationPage> {
  static const _channel = MethodChannel('fretado/navigation');
  final _repository = DriverNavigationRepository();
  DriverRideModel? _ride;
  String? _message;
  bool _launching = false;
  bool _advancing = false;
  bool _loading = true;

  NavigationDestination? get _destination {
    final ride = _ride;
    if (ride == null || ride.driverUserId != widget.userId) return null;
    return NavigationDestination.fromRide(ride);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_refresh());
    });
  }

  Future<bool> _refresh() async {
    try {
      final ride = await _repository.ride(widget.rideId);
      if (!mounted) return false;
      setState(() {
        _ride = ride;
        _loading = false;
      });
      return _destination != null;
    } on HttpServiceException catch (error) {
      if (mounted) {
        setState(() {
          _message = error.message;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _message = 'Não foi possível atualizar a corrida.';
          _loading = false;
        });
      }
    }
    return false;
  }

  Future<void> _start() async {
    if (_launching) return;
    setState(() {
      _launching = true;
      _message = null;
    });
    try {
      if (!await _refresh() || !mounted) return;
      if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
        setState(
          () => _message =
              'A navegação integrada está disponível no Android. Use Maps ou Waze neste dispositivo.',
        );
        return;
      }
      if (!mapboxPublicToken.startsWith('pk.')) {
        setState(
          () => _message =
              'A navegação integrada está indisponível neste momento. Você pode usar Maps ou Waze.',
        );
        return;
      }
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (mounted) {
          setState(() => _message = 'Ative o GPS para iniciar a navegação.');
        }
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(
            () => _message =
                'Permita localização precisa nas configurações para navegar.',
          );
        }
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      if (!mounted) return;
      if (!position.accuracy.isFinite || position.accuracy > 100) {
        setState(
          () => _message =
              'O GPS está impreciso. Aguarde um sinal melhor e tente novamente.',
        );
        return;
      }
      final accessToken = SessionStorage.instance.currentAccessToken;
      if (accessToken == null ||
          SessionStorage.instance.currentUserId != widget.userId) {
        setState(() => _message = 'Entre novamente para navegar.');
        return;
      }
      final message = await _channel.invokeMethod<String>('start', {
        'rideId': widget.rideId,
        'apiBaseUrl': _repository.baseUrl,
        'accessToken': accessToken,
        'mapboxToken': mapboxPublicToken,
        'latitude': position.latitude,
        'longitude': position.longitude,
      });
      if (!mounted) return;
      setState(() => _message = message);
      await _refresh();
    } on PlatformException catch (error) {
      if (mounted) {
        setState(
          () => _message =
              error.message ?? 'Não foi possível iniciar a navegação.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _message =
              'Não foi possível iniciar. Confira sua conexão e o sinal de GPS.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _launching = false;
          _loading = false;
        });
      }
    }
  }

  Future<void> _external(bool waze) async {
    if (!await _refresh()) return;
    final destination = _destination;
    if (destination == null) return;
    final coordinates =
        '${destination.point.latitude},${destination.point.longitude}';
    final uri = waze
        ? Uri.https('waze.com', '/ul', {
            'll': coordinates,
            'navigate': 'yes',
            'utm_source': 'fretado',
          })
        : Uri.https('www.google.com', '/maps/dir/', {
            'api': '1',
            'destination': coordinates,
            'travelmode': 'driving',
            'dir_action': 'navigate',
          });
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
          mounted) {
        setState(
          () => _message = 'Não foi possível abrir o navegador externo.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _message = 'Não foi possível abrir o navegador externo.',
        );
      }
    }
  }

  Future<void> _advance() async {
    if (_advancing || !await _refresh() || !mounted) return;
    final ride = _ride!;
    final confirmed = await showFretRideProgressConfirmation(
      context,
      statusId: ride.statusId,
      isCancellationReturn: ride.isCancellationReturn,
    );
    if (!confirmed || !mounted) return;
    setState(() => _advancing = true);
    try {
      final next = await _repository.advance(ride);
      if (!mounted) return;
      setState(() => _ride = next);
      if (next.statusId == 5) {
        await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => RideRatingPage(rideId: widget.rideId),
          ),
        );
        if (mounted) Navigator.of(context).pop(true);
      }
    } on HttpServiceException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'Não foi possível atualizar a corrida.');
      }
    } finally {
      if (mounted) setState(() => _advancing = false);
    }
  }

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final destination = _destination;
    return PopScope(
      canPop: !_launching,
      child: Scaffold(
        backgroundColor: FretColors.appBackground,
        appBar: AppBar(title: Text('Navegação · #${widget.rideId}')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (destination != null) ...[
                      Text(
                        destination.title,
                        style: const TextStyle(
                          color: FretColors.brandGoldDark,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        destination.address,
                        style: const TextStyle(
                          fontSize: 20,
                          height: 1.4,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: SizedBox(
                          height: 260,
                          child: FretMap(
                            initialCenter: destination.point,
                            delivery: destination.point,
                          ),
                        ),
                      ),
                      GeocodingCredit(
                        source:
                            '${_ride?.details?.originAddressSource ?? ''} | ${_ride?.details?.destinationAddressSource ?? ''}',
                      ),
                    ] else
                      const Text(
                        'A corrida não está disponível para navegação neste momento.',
                      ),
                    if (_message != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          _message!,
                          style: const TextStyle(
                            color: FretColors.textSecondary,
                          ),
                        ),
                      ),
                    FilledButton.icon(
                      onPressed: destination == null || _launching || _advancing
                          ? null
                          : _start,
                      style: FilledButton.styleFrom(
                        backgroundColor: FretColors.brandGraphite,
                        minimumSize: const Size.fromHeight(54),
                      ),
                      icon: const Icon(Icons.navigation_rounded),
                      label: Text(
                        _launching
                            ? 'Navegação aberta…'
                            : 'Iniciar navegação pelo app',
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'A orientação funciona com a tela aberta. Ao sair, a sessão é encerrada.',
                      style: TextStyle(
                        fontSize: 12,
                        color: FretColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: destination == null || _launching
                                ? null
                                : () => _external(false),
                            child: const Text('Google Maps'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: destination == null || _launching
                                ? null
                                : () => _external(true),
                            child: const Text('Waze'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (destination != null)
                      FilledButton(
                        onPressed: _launching || _advancing ? null : _advance,
                        style: FilledButton.styleFrom(
                          backgroundColor: FretColors.brandGoldDark,
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: Text(
                          _advancing
                              ? 'Atualizando…'
                              : destination.isPickup
                              ? 'Confirmar coleta'
                              : 'Confirmar entrega',
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
