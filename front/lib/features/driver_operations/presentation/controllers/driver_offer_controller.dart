import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../data/models/driver_operation_models.dart';
import '../../data/repositories/driver_operations_repository.dart';

class DriverOfferController extends ChangeNotifier with WidgetsBindingObserver {
  final DriverOperationsRepository repository;
  final int userId;
  Timer? _poll;
  Timer? _clock;
  Future<void>? _request;
  bool _disposed = false;
  bool _foreground = true;
  bool isLoading = true;
  bool isActing = false;
  String? error;
  PendingRideOfferModel? pending;
  int? acceptedOfferId;
  int _revision = 0;

  DriverOfferController({required this.repository, required this.userId}) {
    WidgetsBinding.instance.addObserver(this);
    _startTimers();
    refresh();
  }

  void _startTimers() {
    _poll?.cancel();
    _clock?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 5), (_) => refresh());
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (pending == null || _disposed) return;
      if (pending!.offer.isExpired) {
        pending = null;
        _revision++;
        refresh();
      }
      _notify();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      if (pending?.offer.isExpired == true) pending = null;
      _startTimers();
      refresh();
    } else {
      _poll?.cancel();
      _clock?.cancel();
    }
  }

  Future<void> refresh() async {
    if (_disposed || !_foreground || isActing) return;
    if (_request != null) return _request;
    final revision = _revision;
    final request = _fetch(revision);
    _request = request;
    try {
      await request;
    } finally {
      _request = null;
    }
  }

  Future<void> _fetch(int revision) async {
    try {
      final result = await repository.getPendingOffer(userId);
      if (_disposed || revision != _revision) return;
      pending = result?.offer.isExpired == true ? null : result;
      error = null;
    } on DriverOperationsRepositoryException catch (e) {
      if (!_disposed && revision == _revision) error = e.message;
    } catch (_) {
      if (!_disposed && revision == _revision) {
        error = 'Não foi possível atualizar suas ofertas.';
      }
    } finally {
      if (!_disposed) {
        isLoading = false;
        _notify();
      }
    }
  }

  Future<bool> respond({required bool accept}) async {
    final current = pending;
    if (_disposed || isActing || current == null || current.offer.isExpired) {
      return false;
    }
    isActing = true;
    error = null;
    _revision++; // Ignore any poll response started before this action.
    _notify();
    bool success = false;
    try {
      final result = accept
          ? await repository.acceptOffer(current.offer.id, userId)
          : await repository.rejectOffer(current.offer.id, userId);
      if (_disposed) return false;
      success = accept ? result.statusId == 2 : result.statusId == 3 || result.statusId == 4;
      if (result.statusId != 1) pending = null;
      if (accept && result.statusId == 2) acceptedOfferId = result.id;
      if (!success) error = 'A oferta não está mais disponível. Atualize a tela.';
    } on DriverOperationsRepositoryException catch (e) {
      if (!_disposed) error = e.message;
    } catch (_) {
      if (!_disposed) error = 'Não foi possível confirmar sua resposta. Atualize a oferta.';
    } finally {
      if (!_disposed) {
        isActing = false;
        _notify();
      }
    }
    if (!success && !_disposed) {
      // Reconcile timeouts/conflicts with the server before permitting a retry.
      final actionError = error;
      await _request;
      await refresh();
      if (!_disposed) {
        error = actionError;
        _notify();
      }
    }
    return success;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _revision++;
    _poll?.cancel();
    _clock?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
