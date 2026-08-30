import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/endpoints.dart';
import '../../../../core/services/http_service.dart';

class DriverAvailabilityController extends ChangeNotifier {
  static const Duration heartbeatInterval = Duration(minutes: 10);

  final HttpService _httpService;
  Timer? _heartbeatTimer;

  bool _isLoading = true;
  bool _isOnline = false;
  bool _hasLoadedStatus = false;
  String? _message;
  DateTime? _lastSeenAt;
  bool _isDisposed = false;

  DriverAvailabilityController({HttpService? httpService})
    : _httpService = httpService ?? HttpService();

  bool get isLoading => _isLoading;
  bool get isOnline => _isOnline;
  bool get hasLoadedStatus => _hasLoadedStatus;
  String? get message => _message;
  DateTime? get lastSeenAt => _lastSeenAt;

  Future<void> loadInitialStatus() async {
    _setLoading(true);
    _setMessage(null);

    try {
      final response = await _httpService.get(Endpoints.driverLocationMe);
      final bool online = response['is_online'] == true;

      _isOnline = online;
      _lastSeenAt = _readDateTime(response['last_seen_at']);
      _hasLoadedStatus = true;
      _notify();

      if (online) {
        _startHeartbeat();
        await refreshCurrentLocation(silent: true);
      } else {
        _stopHeartbeat();
      }
    } on HttpServiceException catch (e) {
      _stopHeartbeat();
      _hasLoadedStatus = true;

      if (e.statusCode == 404) {
        _isOnline = false;
        _lastSeenAt = null;
        _message = null;
      } else if (e.statusCode == 401 || e.statusCode == 403) {
        _isOnline = false;
        _message = 'Entre novamente para sincronizar sua disponibilidade.';
      } else {
        _message = _friendlyApiError(
          e,
          fallback: 'Nao foi possivel carregar seu status.',
        );
      }
      _notify();
    } catch (_) {
      _stopHeartbeat();
      _hasLoadedStatus = true;
      _message = 'Nao foi possivel carregar seu status.';
      _notify();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> goOnline() async {
    if (_isLoading) return;

    _setLoading(true);
    _setMessage(null);

    try {
      final position = await _getCurrentPosition(
        purpose: _LocationPurpose.goOnline,
      );
      if (position == null) return;

      final response = await _httpService.post(
        Endpoints.driverLocationMeOnline,
        body: _positionBody(position),
      );

      await _runRideDispatchJob();
      _isOnline = response['is_online'] == true;
      _lastSeenAt = _readDateTime(response['last_seen_at']);
      // _message = _isOnline ? 'Voce esta online.' : null;

      if (_isOnline) {
        _startHeartbeat();
      } else {
        _stopHeartbeat();
      }
      _notify();
    } on HttpServiceException catch (e) {
      _stopHeartbeat();
      _isOnline = false;
      _message = _friendlyApiError(
        e,
        fallback: 'Nao foi possivel ficar online.',
      );
      _notify();
    } catch (_) {
      _stopHeartbeat();
      _isOnline = false;
      _message = 'Nao foi possivel ficar online.';
      _notify();
    } finally {
      _hasLoadedStatus = true;
      _setLoading(false);
    }
  }

  Future<void> goOffline() async {
    if (_isLoading) return;

    final bool wasOnline = _isOnline;
    _stopHeartbeat();
    _setLoading(true);
    _setMessage(null);

    try {
      final response = await _httpService.patch(
        Endpoints.driverLocationMeOffline,
      );

      _isOnline = response['is_online'] == true;
      _lastSeenAt = _readDateTime(response['last_seen_at']);
      _notify();
    } on HttpServiceException catch (e) {
      _isOnline = wasOnline;
      if (wasOnline) _startHeartbeat();
      _message = _friendlyApiError(
        e,
        fallback: 'Nao foi possivel ficar offline.',
      );
      _notify();
    } catch (_) {
      _isOnline = wasOnline;
      if (wasOnline) _startHeartbeat();
      _message = 'Nao foi possivel ficar offline.';
      _notify();
    } finally {
      _hasLoadedStatus = true;
      _setLoading(false);
    }
  }

  Future<void> refreshCurrentLocation({bool silent = false}) async {
    if (!_isOnline) return;

    final position = await _getCurrentPosition(
      purpose: _LocationPurpose.refreshOnline,
    );
    if (position == null) {
      _stopHeartbeat();
      _notify();
      return;
    }

    try {
      final response = await _httpService.put(
        Endpoints.driverLocationMeLocation,
        body: _positionBody(position),
      );

      await _runRideDispatchJob();
      _isOnline = response['is_online'] == true;
      _lastSeenAt = _readDateTime(response['last_seen_at']);
      if (!silent) {
        _message = 'Localizacao atualizada.';
      }
      if (_isOnline) {
        _startHeartbeat();
      } else {
        _stopHeartbeat();
      }
      _notify();
    } on HttpServiceException catch (e) {
      if (e.statusCode == 409) {
        _isOnline = false;
        _stopHeartbeat();
      } else {
        _message = _friendlyApiError(
          e,
          fallback: 'Nao foi possivel atualizar localizacao.',
        );
      }
      _notify();
    } catch (_) {
      _message = 'Nao foi possivel atualizar localizacao.';
      _notify();
    }
  }

  Future<void> _runRideDispatchJob() async {
    const jobSecret = String.fromEnvironment('JOB_SECRET');
    if (jobSecret.isEmpty) return;

    try {
      await _httpService.post(
        Endpoints.rideDispatchJob,
        headers: {'X-Job-Secret': jobSecret},
        authenticated: false,
      );
    } catch (_) {}
  }

  Future<Position?> _getCurrentPosition({
    required _LocationPurpose purpose,
  }) async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _message = purpose == _LocationPurpose.goOnline
          ? 'Ative a localizacao do navegador ou aparelho para ficar online.'
          : 'Ative a localizacao do navegador ou aparelho para continuar online.';
      _notify();
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      _message = purpose == _LocationPurpose.goOnline
          ? 'Permita acesso a localizacao para ficar online.'
          : 'Permita acesso a localizacao para continuar online.';
      _notify();
      return null;
    }

    if (permission == LocationPermission.deniedForever) {
      _message =
          'A permissao de localizacao esta bloqueada. Libere nas configuracoes do aparelho.';
      _notify();
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (_) {
      _message = purpose == _LocationPurpose.goOnline
          ? 'Nao foi possivel obter sua localizacao para ficar online.'
          : 'Nao foi possivel atualizar sua localizacao agora.';
      _notify();
      return null;
    }
  }

  Map<String, dynamic> _positionBody(Position position) {
    return {
      'latitude': double.parse(position.latitude.toStringAsFixed(6)),
      'longitude': double.parse(position.longitude.toStringAsFixed(6)),
      'accuracy': double.parse(position.accuracy.toStringAsFixed(2)),
    };
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      heartbeatInterval,
      (_) => refreshCurrentLocation(silent: true),
    );
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  DateTime? _readDateTime(dynamic value) {
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  String _friendlyApiError(
    HttpServiceException error, {
    required String fallback,
  }) {
    if (error.statusCode == 401 || error.statusCode == 403) {
      return 'Entre novamente para sincronizar sua disponibilidade.';
    }

    final String message = error.message.trim();
    if (message.isEmpty || message == 'Ocorreu um erro inesperado.') {
      return fallback;
    }

    return message;
  }

  void _setLoading(bool value) {
    if (_isLoading == value || _isDisposed) return;
    _isLoading = value;
    _notify();
  }

  void _setMessage(String? value) {
    if (_message == value || _isDisposed) return;
    _message = value;
    _notify();
  }

  void _notify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _stopHeartbeat();
    _httpService.dispose();
    super.dispose();
  }
}

enum _LocationPurpose { goOnline, refreshOnline }
