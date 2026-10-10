import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../data/models/driver_operation_models.dart';
import '../../data/repositories/driver_operations_repository.dart';

enum DriverOfferState { checking, idle, pending, acting, error }

class DriverOfferController extends ChangeNotifier with WidgetsBindingObserver {
  final DriverOperationsRepository repository;
  final int userId;
  final Duration pollInterval;

  Timer? _pollTimer;
  Timer? _clockTimer;
  Future<void>? _request;
  bool _disposed = false;
  bool _foreground = true;
  int _revision = 0;

  DriverOfferState state = DriverOfferState.checking;
  PendingRideOfferModel? pending;
  String? error;

  DriverOfferController({
    required this.repository,
    required this.userId,
    this.pollInterval = const Duration(seconds: 5),
  }) {
    WidgetsBinding.instance.addObserver(this);
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    if (_foreground) {
      _startTimers();
      refresh(forceDetails: true);
    }
  }

  bool get isActing => state == DriverOfferState.acting;
  bool get isBlocking => state != DriverOfferState.idle;

  Duration get elapsed {
    final createdAt = pending?.offer.createdAt;
    if (createdAt == null) return Duration.zero;
    final value = DateTime.now().toUtc().difference(createdAt);
    return value.isNegative ? Duration.zero : value;
  }

  void _startTimers() {
    _pollTimer?.cancel();
    _clockTimer?.cancel();
    _pollTimer = Timer.periodic(pollInterval, (_) => refresh());
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_disposed && pending != null) notifyListeners();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      _startTimers();
      refresh(forceDetails: true);
    } else {
      _pollTimer?.cancel();
      _clockTimer?.cancel();
    }
  }

  Future<void> refresh({bool forceDetails = false}) async {
    if (_disposed || !_foreground || isActing) return;
    if (_request != null) return _request;

    final revision = _revision;
    final request = _fetch(revision, forceDetails: forceDetails);
    _request = request;
    try {
      await request;
    } finally {
      if (identical(_request, request)) _request = null;
    }
  }

  Future<void> _fetch(int revision, {required bool forceDetails}) async {
    try {
      final offers = await repository.listOffersByDriver(userId);
      if (_disposed || revision != _revision) return;

      RideOfferModel? offer;
      for (final candidate in offers) {
        if (candidate.driverUserId == userId && candidate.isPending) {
          offer = candidate;
          break;
        }
      }

      if (offer == null) {
        pending = null;
        error = null;
        state = DriverOfferState.idle;
        _notify();
        return;
      }

      final cachedPending = pending?.offer.id == offer.id ? pending : null;
      if (!forceDetails && cachedPending != null) {
        error = null;
        state = DriverOfferState.pending;
        _notify();
        return;
      }

      final ride = await repository.getRideById(offer.rideId);
      if (_disposed || revision != _revision) return;
      final validTransfer =
          offer.isCargoTransfer &&
          ride.statusId == 4 &&
          offer.reassignment?.status == 'awaiting_replacement';
      final validStandard =
          !offer.isCargoTransfer &&
          ride.statusId == 1 &&
          ride.driverUserId == null;
      if (!validStandard && !validTransfer) {
        pending = null;
        error = null;
        state = DriverOfferState.idle;
        _notify();
        return;
      }

      double distanceKm;
      bool approximate;
      if (offer.isCargoTransfer &&
          offer.reassignment?.incomingDistanceKm != null) {
        distanceKm = offer.reassignment!.incomingDistanceKm!;
        approximate = false;
      } else if (cachedPending != null) {
        distanceKm = cachedPending.distanceKm;
        approximate = cachedPending.distanceIsApproximate;
      } else {
        approximate = false;
        try {
          distanceKm = await repository.getRouteDistance(ride);
        } catch (_) {
          distanceKm = ride.details?.approximateDistanceKm ?? 0;
          approximate = true;
        }
      }
      if (_disposed || revision != _revision) return;

      pending = PendingRideOfferModel(
        offer: offer,
        ride: ride,
        distanceKm: distanceKm,
        distanceIsApproximate: approximate,
      );
      error = null;
      state = DriverOfferState.pending;
      _notify();
    } on DriverOperationsRepositoryException catch (exception) {
      _handleFetchError(revision, exception.message);
    } catch (_) {
      _handleFetchError(revision, 'Nao foi possivel verificar suas ofertas.');
    }
  }

  Future<bool> respond({required bool accept}) async {
    final current = pending;
    if (_disposed || isActing || current == null) return false;

    state = DriverOfferState.acting;
    error = null;
    _revision++;
    _notify();

    try {
      final result = accept
          ? await repository.acceptOffer(current.offer.id, userId)
          : await repository.rejectOffer(current.offer.id, userId);
      if (_disposed) return false;

      final success = accept ? result.statusId == 2 : result.statusId == 3;
      if (success) {
        pending = null;
        error = null;
        state = DriverOfferState.idle;
        _notify();
        return true;
      }

      error = 'A oferta mudou de estado. Atualize para continuar.';
    } on DriverOperationsRepositoryException catch (exception) {
      if (!_disposed) error = exception.message;
    } catch (_) {
      if (!_disposed) error = 'Nao foi possivel confirmar sua resposta.';
    }

    if (!_disposed) {
      final actionError = error;
      state = DriverOfferState.pending;
      _notify();
      await refresh(forceDetails: true);
      if (!_disposed && pending?.offer.id == current.offer.id) {
        error = actionError;
        state = DriverOfferState.pending;
        _notify();
      }
    }
    return false;
  }

  void _handleFetchError(int revision, String message) {
    if (_disposed || revision != _revision) return;
    error = message;
    state = pending == null ? DriverOfferState.error : DriverOfferState.pending;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _revision++;
    _pollTimer?.cancel();
    _clockTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
