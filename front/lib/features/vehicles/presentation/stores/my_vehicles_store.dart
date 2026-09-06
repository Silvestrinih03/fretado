import 'package:flutter/foundation.dart';

import '../../../../core/services/myself/services/myself_service.dart';
import '../../data/models/vehicle_list_item_model.dart';
import '../../data/repositories/vehicle_repository.dart';

class MyVehiclesStore extends ChangeNotifier {
  final VehicleRepository _vehicleRepository;
  final MyselfService _myselfService;
  final int? _fallbackUserId;

  MyVehiclesStore(
    this._vehicleRepository,
    this._myselfService, {
    int? fallbackUserId,
  }) : _fallbackUserId = fallbackUserId;

  bool _isLoading = false;
  bool _disposed = false;
  int _request = 0;
  String? _errorMessage;
  List<VehicleListItemModel> _vehicles = <VehicleListItemModel>[];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<VehicleListItemModel> get vehicles =>
      List<VehicleListItemModel>.unmodifiable(_vehicles);

  Future<void> loadVehicles() async {
    final request = ++_request;
    final int? userId = _myselfService.currentUserId ?? _fallbackUserId;
    if (userId == null) {
      _errorMessage = 'Usuário logado não encontrado.';
      _vehicles = <VehicleListItemModel>[];
      _notify();
      return;
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      final vehicles = await _vehicleRepository.listVehiclesByUser(userId);
      if (_disposed || request != _request) return;
      _vehicles = vehicles;
    } on VehicleRepositoryException catch (e) {
      if (_disposed || request != _request) return;
      _errorMessage = e.message;
      _vehicles = <VehicleListItemModel>[];
    } catch (_) {
      if (_disposed || request != _request) return;
      _errorMessage = 'Não foi possível carregar seus veículos.';
      _vehicles = <VehicleListItemModel>[];
    } finally {
      if (!_disposed && request == _request) _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
