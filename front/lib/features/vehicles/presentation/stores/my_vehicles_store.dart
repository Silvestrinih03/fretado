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
  String? _errorMessage;
  List<VehicleListItemModel> _vehicles = <VehicleListItemModel>[];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<VehicleListItemModel> get vehicles =>
      List<VehicleListItemModel>.unmodifiable(_vehicles);

  Future<void> loadVehicles() async {
    final int? userId = _myselfService.currentUserId ?? _fallbackUserId;
    if (userId == null) {
      _errorMessage = 'Usuário logado não encontrado.';
      _vehicles = <VehicleListItemModel>[];
      notifyListeners();
      return;
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      _vehicles = await _vehicleRepository.listVehiclesByUser(userId);
    } on VehicleRepositoryException catch (e) {
      _errorMessage = e.message;
      _vehicles = <VehicleListItemModel>[];
    } catch (_) {
      _errorMessage = 'Não foi possível carregar seus veículos.';
      _vehicles = <VehicleListItemModel>[];
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}