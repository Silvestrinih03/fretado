import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/endpoints.dart';
import '../../../../core/services/http_service.dart';
import '../../data/models/driver_eligibility_model.dart';

class DriverAvailabilityController extends ChangeNotifier {
  static const Duration heartbeatInterval = Duration(seconds: 45);
  final HttpService _httpService;
  Timer? _heartbeatTimer;
  bool _isLoading = true;
  bool _isOnline = false;
  bool _hasLoadedStatus = false;
  bool _hasActiveRide = false;
  bool _checkingEligibility = true;
  bool _syncingStatus = false;
  bool _changingStatus = false;
  bool _isDisposed = false;
  bool _refreshing = false;
  int _statusVersion = 0;
  String? _message;
  String? _eligibilityError;
  DateTime? _lastSeenAt;
  DriverEligibilityModel? _eligibility;

  DriverAvailabilityController({HttpService? httpService})
    : _httpService = httpService ?? HttpService();

  bool get isLoading => _isLoading;
  bool get isOnline => _isOnline;
  bool get hasLoadedStatus => _hasLoadedStatus;
  bool get hasActiveRide => _hasActiveRide;
  bool get checkingEligibility => _checkingEligibility;
  bool get canGoOnline =>
      !_checkingEligibility &&
      _eligibilityError == null &&
      _eligibility?.canGoOnline == true;
  DriverEligibilityModel? get eligibility => _eligibility;
  String? get eligibilityError => _eligibilityError;
  String? get message => _message;
  DateTime? get lastSeenAt => _lastSeenAt;
  bool get _shouldTrack => _isOnline || _hasActiveRide;

  void _applyEligibility(Map<String, dynamic> response) {
    _eligibility = DriverEligibilityModel.fromJson(response);
    _hasActiveRide = _eligibility!.hasActiveRide;
    _eligibilityError = null;
  }

  void _applyStatus(Map<String, dynamic> response) {
    _applyEligibility(response);
    _isOnline = response['is_online'] == true && _eligibility!.canGoOnline;
    _lastSeenAt = _readDateTime(response['last_seen_at']);
    _message = _eligibility!.message.isEmpty ? null : _eligibility!.message;
  }

  void _syncHeartbeat() {
    if (_isDisposed) return;
    if (_shouldTrack) {
      _startHeartbeat();
    } else {
      _stopHeartbeat();
    }
  }

  void _readSetupError(HttpServiceException error) {
    final detail = error.data?['detail'];
    if (detail is Map && detail['code'] == 'driver_setup_incomplete') {
      _applyEligibility(Map<String, dynamic>.from(detail));
    }
  }

  Future<void> loadInitialStatus() async {
    if (_syncingStatus || _changingStatus || _isDisposed) return;
    _syncingStatus = true;
    _statusVersion++;
    _checkingEligibility = true;
    _setLoading(true);
    _notify();
    try {
      _applyEligibility(
        await _httpService.get(Endpoints.driverLocationMeEligibility),
      );
      try {
        _applyStatus(await _httpService.get(Endpoints.driverLocationMe));
      } on HttpServiceException catch (error) {
        if (error.statusCode != 404) rethrow;
        _isOnline = false;
        _lastSeenAt = null;
        _message = _eligibility!.message.isEmpty ? null : _eligibility!.message;
      }
    } catch (error) {
      _eligibility = null;
      _eligibilityError = error is HttpServiceException
          ? _friendlyApiError(
              error,
              fallback: 'Não foi possível verificar seu cadastro.',
            )
          : 'Não foi possível verificar seu cadastro.';
      _message = _eligibilityError;
      if (error is HttpServiceException &&
          (error.statusCode == 401 || error.statusCode == 403)) {
        _isOnline = false;
        _hasActiveRide = false;
      }
    } finally {
      _checkingEligibility = false;
      _syncingStatus = false;
      _hasLoadedStatus = true;
      _setLoading(false);
      _syncHeartbeat();
      _notify();
    }
    if (_shouldTrack && !_isDisposed) {
      unawaited(refreshCurrentLocation(silent: true));
    }
  }

  Future<void> goOnline() async {
    if (_isLoading || _isDisposed) return;
    if (!canGoOnline) {
      _message =
          _eligibilityError ??
          _eligibility?.message ??
          'Verifique seu cadastro antes de ficar online.';
      _notify();
      return;
    }
    _changingStatus = true;
    _statusVersion++;
    _checkingEligibility = true;
    _setLoading(true);
    _setMessage(null);
    try {
      _applyEligibility(
        await _httpService.get(Endpoints.driverLocationMeEligibility),
      );
      if (_isDisposed) return;
      _checkingEligibility = false;
      if (!_eligibility!.canGoOnline) {
        _isOnline = false;
        _message = _eligibility!.message;
        return;
      }
      final position = await _getCurrentPosition(
        purpose: _LocationPurpose.goOnline,
      );
      if (position == null || _isDisposed) return;
      _applyStatus(
        await _httpService.post(
          Endpoints.driverLocationMeOnline,
          body: _positionBody(position),
        ),
      );
    } on HttpServiceException catch (error) {
      _readSetupError(error);
      _isOnline = false;
      _message = _friendlyApiError(
        error,
        fallback: 'Não foi possível ficar online.',
      );
      if (_checkingEligibility) {
        _eligibility = null;
        _eligibilityError = _message;
      }
      if (error.statusCode == 401 || error.statusCode == 403) {
        _hasActiveRide = false;
      }
    } catch (_) {
      _isOnline = false;
      _message = 'Não foi possível ficar online.';
      if (_checkingEligibility) {
        _eligibility = null;
        _eligibilityError = 'Não foi possível verificar seu cadastro.';
      }
    } finally {
      _checkingEligibility = false;
      _changingStatus = false;
      _hasLoadedStatus = true;
      _setLoading(false);
      _syncHeartbeat();
      _notify();
    }
  }

  Future<void> goOffline() async {
    if (_isLoading || _isDisposed) return;
    final wasOnline = _isOnline;
    _changingStatus = true;
    _statusVersion++;
    _setLoading(true);
    _setMessage(null);
    try {
      _applyStatus(await _httpService.patch(Endpoints.driverLocationMeOffline));
    } on HttpServiceException catch (error) {
      _isOnline = wasOnline;
      if (error.statusCode == 401 || error.statusCode == 403) {
        _isOnline = false;
        _hasActiveRide = false;
      }
      _message = _friendlyApiError(
        error,
        fallback: 'Não foi possível ficar offline.',
      );
    } catch (_) {
      _isOnline = wasOnline;
      _message = 'Não foi possível ficar offline.';
    } finally {
      _changingStatus = false;
      _hasLoadedStatus = true;
      _setLoading(false);
      _syncHeartbeat();
      _notify();
    }
  }

  Future<void> refreshCurrentLocation({bool silent = false}) async {
    if (!_shouldTrack ||
        _refreshing ||
        _isDisposed ||
        _changingStatus ||
        _syncingStatus) {
      return;
    }
    _refreshing = true;
    final version = _statusVersion;
    try {
      final position = await _getCurrentPosition(
        purpose: _LocationPurpose.refreshOnline,
      );
      if (position == null || _isDisposed || version != _statusVersion) return;
      final response = await _httpService.put(
        Endpoints.driverLocationMeLocation,
        body: _positionBody(position),
      );
      if (_isDisposed || version != _statusVersion) return;
      _applyStatus(response);
      if (!silent && _message == null) _message = 'Localização atualizada.';
      _syncHeartbeat();
      _notify();
    } on HttpServiceException catch (error) {
      if (_isDisposed || version != _statusVersion) return;
      _readSetupError(error);
      if (error.statusCode == 409 || error.statusCode == 404) {
        // Work may have finished since the previous heartbeat.
        await loadInitialStatus();
      } else if (error.statusCode == 401 || error.statusCode == 403) {
        _isOnline = false;
        _hasActiveRide = false;
        _syncHeartbeat();
      }
      _message = _friendlyApiError(
        error,
        fallback: 'Não foi possível atualizar a localização.',
      );
      _notify();
    } catch (_) {
      if (_isDisposed || version != _statusVersion) return;
      _message = 'Não foi possível atualizar a localização.';
      _notify();
    } finally {
      _refreshing = false;
    }
  }

  Future<Position?> _getCurrentPosition({
    required _LocationPurpose purpose,
  }) async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _message = purpose == _LocationPurpose.goOnline
          ? 'Ative a localizacao do navegador ou aparelho para ficar online.'
          : 'Ative a localizacao do navegador ou aparelho para atualizar a localização da corrida.';
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
          : 'Permita acesso a localizacao para atualizar a localização da corrida.';
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
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
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
