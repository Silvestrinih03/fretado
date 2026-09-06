import 'package:flutter/foundation.dart';

import '../../data/models/register_vehicle_model.dart';
import '../../data/models/vehicle_catalog_option_model.dart';
import '../../data/models/vehicle_type_model.dart';
import '../../data/repositories/register_vehicle_repository.dart';
import '../../data/repositories/vehicle_catalog_repository.dart';
import '../../data/repositories/vehicle_type_repository.dart';
import '../../../../core/services/myself/services/myself_service.dart';

class RegisterVehicleStore extends ChangeNotifier {
  final VehicleTypeRepository _vehicleTypeRepository;
  final VehicleCatalogRepository _catalogRepository;
  final RegisterVehicleRepository _registerVehicleRepository;
  final MyselfService _myselfService;

  RegisterVehicleStore(
    this._vehicleTypeRepository,
    this._catalogRepository,
    this._registerVehicleRepository,
    this._myselfService,
  );

  bool _disposed = false;
  bool isLoadingVehicleTypes = false;
  bool isRegisteringVehicle = false;
  String? vehicleTypesError;
  String? registerVehicleError;
  List<VehicleTypeModel> vehicleTypes = [];
  int? selectedVehicleTypeId;
  String? selectedBrand;
  String? selectedModel;
  String? selectedVersion;
  int? selectedYear;
  final Map<String, List<VehicleCatalogOptionModel>> _options = {
    'brands': [],
    'models': [],
    'versions': [],
  };
  final Map<String, bool> _loading = {};
  final Map<String, String?> _errors = {};
  final Map<String, int> _requests = {};

  List<VehicleCatalogOptionModel> options(String level) =>
      List.unmodifiable(_options[level]!);
  bool isLoading(String level) => _loading[level] ?? false;
  String? error(String level) => _errors[level];
  List<int> get years {
    for (final version in _options['versions']!) {
      if (version.value == selectedVersion) return version.years;
    }
    return const [];
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> loadVehicleTypes() async {
    if (isLoadingVehicleTypes) return;
    isLoadingVehicleTypes = true;
    vehicleTypesError = null;
    _notify();
    try {
      vehicleTypes = await _vehicleTypeRepository.listVehicleTypes();
    } on VehicleTypeRepositoryException catch (e) {
      vehicleTypesError = e.message;
    } catch (_) {
      vehicleTypesError = 'Não foi possível carregar os tipos de veículo.';
    } finally {
      isLoadingVehicleTypes = false;
      _notify();
    }
  }

  void selectVehicleType(int id) {
    selectedVehicleTypeId = id;
    _notify();
  }

  void _clear(String level) {
    _requests[level] = (_requests[level] ?? 0) + 1;
    _options[level] = [];
    _loading[level] = false;
    _errors[level] = null;
  }

  void selectBrand(String? value) {
    selectedBrand = value;
    selectedModel = null;
    selectedVersion = null;
    selectedYear = null;
    _clear('models');
    _clear('versions');
    _notify();
    if (value != null) loadModels();
  }

  void selectModel(String? value) {
    selectedModel = value;
    selectedVersion = null;
    selectedYear = null;
    _clear('versions');
    _notify();
    if (value != null) loadVersions();
  }

  void selectVersion(String? value) {
    selectedVersion = value;
    selectedYear = null;
    _notify();
  }

  void selectYear(int? value) {
    selectedYear = value;
    _notify();
  }

  Future<void> loadBrands() => _load('brands', _catalogRepository.listBrands);
  Future<void> loadModels() async {
    final brand = selectedBrand;
    if (brand == null) return;
    await _load('models', () => _catalogRepository.listModels(brandId: brand));
  }

  Future<void> loadVersions() async {
    final brand = selectedBrand;
    final model = selectedModel;
    if (brand == null || model == null) return;
    await _load(
      'versions',
      () => _catalogRepository.listVersions(brandId: brand, modelId: model),
    );
  }

  Future<void> _load(
    String level,
    Future<List<VehicleCatalogOptionModel>> Function() request,
  ) async {
    final token = (_requests[level] ?? 0) + 1;
    _requests[level] = token;
    _loading[level] = true;
    _errors[level] = null;
    _notify();
    try {
      final result = await request();
      if (_disposed || _requests[level] != token) return;
      _options[level] = result;
      if (result.isEmpty)
        _errors[level] = 'Nenhuma opção disponível no catálogo.';
    } catch (e) {
      if (_disposed || _requests[level] != token) return;
      _errors[level] = e is VehicleCatalogRepositoryException
          ? e.message
          : 'Não foi possível carregar o catálogo. Tente novamente.';
    } finally {
      if (!_disposed && _requests[level] == token) {
        _loading[level] = false;
        _notify();
      }
    }
  }

  static String normalizePlate(String value) =>
      value.toUpperCase().replaceAll(RegExp(r'[\s-]'), '');

  static String? validatePlate(String? value) {
    final plate = normalizePlate(value ?? '');
    if (plate.isEmpty) return 'Informe a placa.';
    if (!RegExp(r'^[A-Z]{3}[0-9][A-Z0-9][0-9]{2}$').hasMatch(plate)) {
      return 'Informe uma placa v?lida, como ABC1234 ou ABC1D23.';
    }
    return null;
  }

  Future<bool> registerVehicle({
    required String plate,
    required String color,
  }) async {
    if (isRegisteringVehicle) return false;
    registerVehicleError = null;
    final versionId = int.tryParse(selectedVersion ?? '');
    final userId = _myselfService.currentUserId;
    if (selectedVehicleTypeId == null ||
        selectedBrand == null ||
        selectedModel == null ||
        versionId == null ||
        !years.contains(selectedYear)) {
      registerVehicleError = 'Selecione tipo, marca, modelo, versão e ano.';
    } else if (validatePlate(plate) != null) {
      registerVehicleError = validatePlate(plate);
    } else if (color.trim().length > 50) {
      registerVehicleError = 'A cor deve ter no máximo 50 caracteres.';
    } else if (userId == null) {
      registerVehicleError = 'Usuário logado não encontrado.';
    }
    if (registerVehicleError != null) {
      _notify();
      return false;
    }
    isRegisteringVehicle = true;
    _notify();
    try {
      await _registerVehicleRepository.registerVehicle(
        RegisterVehicleModel(
          userId: userId!,
          vehicleTypeId: selectedVehicleTypeId!,
          versionId: versionId!,
          year: selectedYear!,
          color: color.trim().isEmpty ? null : color.trim(),
          plate: normalizePlate(plate),
          status: true,
        ),
      );
      return true;
    } on RegisterVehicleRepositoryException catch (e) {
      registerVehicleError = e.message;
      return false;
    } catch (_) {
      registerVehicleError =
          'N?o foi poss?vel cadastrar o ve?culo. Tente novamente.';
      return false;
    } finally {
      isRegisteringVehicle = false;
      _notify();
    }
  }
}
