import 'package:flutter/foundation.dart';

import '../../data/models/register_vehicle_model.dart';
import '../../data/models/vehicle_fipe_option_model.dart';
import '../../data/models/vehicle_type_model.dart';
import '../../data/repositories/register_vehicle_repository.dart';
import '../../data/repositories/vehicle_fipe_repository.dart';
import '../../data/repositories/vehicle_type_repository.dart';

class RegisterVehicleStore extends ChangeNotifier {
  static const int _fixedUserId = 5;

  final VehicleTypeRepository _vehicleTypeRepository;
  final VehicleFipeRepository _vehicleFipeRepository;
  final RegisterVehicleRepository _registerVehicleRepository;

  RegisterVehicleStore(
    this._vehicleTypeRepository,
    this._vehicleFipeRepository,
    this._registerVehicleRepository,
  );

  bool _isLoadingVehicleTypes = false;
  bool _isLoadingVehicleFipe = false;
  bool _isRegisteringVehicle = false;
  String? _vehicleTypesError;
  String? _vehicleFipeError;
  String? _registerVehicleError;
  List<VehicleTypeModel> _vehicleTypes = <VehicleTypeModel>[];
  List<VehicleFipeOptionModel> _vehicleFipeBrands = <VehicleFipeOptionModel>[];
  List<VehicleFipeOptionModel> _vehicleFipeModels = <VehicleFipeOptionModel>[];
  List<VehicleFipeOptionModel> _vehicleFipeYears = <VehicleFipeOptionModel>[];
  int? _selectedVehicleTypeId;
  String? _selectedVehicleFipeBrandCode;
  String? _selectedVehicleFipeModelCode;
  String? _selectedVehicleFipeYearCode;
  RegisterVehicleModel? _registeredVehicle;

  bool get isLoadingVehicleTypes => _isLoadingVehicleTypes;
  bool get isLoadingVehicleFipe => _isLoadingVehicleFipe;
  bool get isRegisteringVehicle => _isRegisteringVehicle;
  String? get vehicleTypesError => _vehicleTypesError;
  String? get vehicleFipeError => _vehicleFipeError;
  String? get registerVehicleError => _registerVehicleError;
  List<VehicleTypeModel> get vehicleTypes =>
      List<VehicleTypeModel>.unmodifiable(_vehicleTypes);
  List<VehicleFipeOptionModel> get vehicleFipeBrands =>
      List<VehicleFipeOptionModel>.unmodifiable(_vehicleFipeBrands);
  List<VehicleFipeOptionModel> get vehicleFipeModels =>
      List<VehicleFipeOptionModel>.unmodifiable(_vehicleFipeModels);
  List<VehicleFipeOptionModel> get vehicleFipeYears =>
      List<VehicleFipeOptionModel>.unmodifiable(_vehicleFipeYears);
  int? get selectedVehicleTypeId => _selectedVehicleTypeId;
  String? get selectedVehicleFipeBrandCode => _selectedVehicleFipeBrandCode;
  String? get selectedVehicleFipeModelCode => _selectedVehicleFipeModelCode;
  String? get selectedVehicleFipeYearCode => _selectedVehicleFipeYearCode;
  RegisterVehicleModel? get registeredVehicle => _registeredVehicle;

  Future<void> loadVehicleTypes() async {
    _setLoading(true);
    _vehicleTypesError = null;

    try {
      _vehicleTypes = await _vehicleTypeRepository.listVehicleTypes();
    } on VehicleTypeRepositoryException catch (e) {
      _vehicleTypesError = e.message;
    } catch (_) {
      _vehicleTypesError = 'Não foi possível carregar os tipos de veículo.';
    } finally {
      _setLoading(false);
    }
  }

  void selectVehicleType(int id) {
    _selectedVehicleTypeId = id;
    _resetVehicleFipeSelection();
    notifyListeners();
  }

  Future<void> loadVehicleFipeBrands() async {
    if (_selectedVehicleTypeId == null) {
      _vehicleFipeError = 'Selecione o tipo de veículo.';
      notifyListeners();
      return;
    }

    _setLoadingVehicleFipe(true);
    _vehicleFipeError = null;

    try {
      _vehicleFipeBrands = await _vehicleFipeRepository.listBrands(
        vehicleTypeId: _selectedVehicleTypeId!,
      );
      _vehicleFipeModels = <VehicleFipeOptionModel>[];
      _vehicleFipeYears = <VehicleFipeOptionModel>[];
    } on VehicleFipeRepositoryException catch (e) {
      _vehicleFipeError = e.message;
    } catch (_) {
      _vehicleFipeError = 'Não foi possível carregar as marcas da FIPE.';
    } finally {
      _setLoadingVehicleFipe(false);
    }
  }

  Future<void> loadVehicleFipeModels() async {
    if (_selectedVehicleTypeId == null || _selectedVehicleFipeBrandCode == null) {
      _vehicleFipeError = 'Selecione o tipo e a marca do veículo.';
      notifyListeners();
      return;
    }

    _setLoadingVehicleFipe(true);
    _vehicleFipeError = null;

    try {
      _vehicleFipeModels = await _vehicleFipeRepository.listModels(
        vehicleTypeId: _selectedVehicleTypeId!,
        brandId: _selectedVehicleFipeBrandCode!,
      );
      _vehicleFipeYears = <VehicleFipeOptionModel>[];
    } on VehicleFipeRepositoryException catch (e) {
      _vehicleFipeError = e.message;
    } catch (_) {
      _vehicleFipeError = 'Não foi possível carregar os modelos da FIPE.';
    } finally {
      _setLoadingVehicleFipe(false);
    }
  }

  Future<void> loadVehicleFipeYears() async {
    if (_selectedVehicleTypeId == null ||
        _selectedVehicleFipeBrandCode == null ||
        _selectedVehicleFipeModelCode == null) {
      _vehicleFipeError = 'Selecione tipo, marca e modelo do veículo.';
      notifyListeners();
      return;
    }

    _setLoadingVehicleFipe(true);
    _vehicleFipeError = null;

    try {
      _vehicleFipeYears = await _vehicleFipeRepository.listYears(
        vehicleTypeId: _selectedVehicleTypeId!,
        brandId: _selectedVehicleFipeBrandCode!,
        modelId: _selectedVehicleFipeModelCode!,
      );
    } on VehicleFipeRepositoryException catch (e) {
      _vehicleFipeError = e.message;
    } catch (_) {
      _vehicleFipeError = 'Não foi possível carregar os anos da FIPE.';
    } finally {
      _setLoadingVehicleFipe(false);
    }
  }

  void selectVehicleFipeBrand(String? brandCode) {
    _selectedVehicleFipeBrandCode = brandCode;
    _selectedVehicleFipeModelCode = null;
    _selectedVehicleFipeYearCode = null;
    _vehicleFipeModels = <VehicleFipeOptionModel>[];
    _vehicleFipeYears = <VehicleFipeOptionModel>[];
    notifyListeners();
  }

  void selectVehicleFipeModel(String? modelCode) {
    _selectedVehicleFipeModelCode = modelCode;
    _selectedVehicleFipeYearCode = null;
    _vehicleFipeYears = <VehicleFipeOptionModel>[];
    notifyListeners();
  }

  void selectVehicleFipeYear(String? yearCode) {
    _selectedVehicleFipeYearCode = yearCode;
    notifyListeners();
  }

  void clearSelection() {
    _selectedVehicleTypeId = null;
    _resetVehicleFipeSelection();
    notifyListeners();
  }

  Future<bool> registerVehicle({
    required String registerMode,
    required String brand,
    required String model,
    required String year,
    required String plate,
    required String loadCapacityKg,
    required String? color,
    required String? widthCm,
    required String? heightCm,
    required String? lengthCm,
    required bool status,
  }) async {
    if (_selectedVehicleTypeId == null) {
      _registerVehicleError = 'Selecione o tipo de veículo.';
      notifyListeners();
      return false;
    }

    final bool isFipeMode = registerMode == 'fipe';
    final String trimmedBrand = brand.trim();
    final String trimmedModel = model.trim();
    final String trimmedYear = year.trim();
    final String trimmedPlate = plate.trim();
    final int? parsedLoadCapacity = int.tryParse(loadCapacityKg.trim());
    final int? parsedWidth = _parseOptionalInt(widthCm);
    final int? parsedHeight = _parseOptionalInt(heightCm);
    final int? parsedLength = _parseOptionalInt(lengthCm);

    final String? selectedBrandLabel = _selectedLabel(
      _vehicleFipeBrands,
      _selectedVehicleFipeBrandCode,
    );
    final String? selectedModelLabel = _selectedLabel(
      _vehicleFipeModels,
      _selectedVehicleFipeModelCode,
    );
    final String? selectedYearLabel = _selectedLabel(
      _vehicleFipeYears,
      _selectedVehicleFipeYearCode,
    );

    if (isFipeMode) {
      if (_selectedVehicleFipeBrandCode == null ||
          _selectedVehicleFipeModelCode == null ||
          _selectedVehicleFipeYearCode == null) {
        _registerVehicleError = 'Selecione marca, modelo e ano pela FIPE.';
        notifyListeners();
        return false;
      }
    } else {
      if (trimmedBrand.isEmpty || trimmedModel.isEmpty || trimmedYear.isEmpty) {
        _registerVehicleError = 'Informe marca, modelo e ano para continuar.';
        notifyListeners();
        return false;
      }
    }

    if (trimmedPlate.isEmpty) {
      _registerVehicleError = 'Informe a placa para continuar.';
      notifyListeners();
      return false;
    }

    if (parsedLoadCapacity == null || parsedLoadCapacity <= 0) {
      _registerVehicleError = 'Informe uma capacidade de carga válida.';
      notifyListeners();
      return false;
    }

    final int parsedYear = isFipeMode
        ? _extractYearFromLabel(selectedYearLabel)
        : int.tryParse(trimmedYear) ?? -1;

    if (!isFipeMode && parsedYear <= 0) {
      _registerVehicleError = 'Informe um ano válido.';
      notifyListeners();
      return false;
    }

    _setRegistering(true);
    _registerVehicleError = null;

    try {
      final RegisterVehicleModel payload = isFipeMode
          ? RegisterVehicleModel(
              userId: _fixedUserId,
              vehicleTypeId: _selectedVehicleTypeId!,
              brand: selectedBrandLabel ?? trimmedBrand,
              brandCode: _selectedVehicleFipeBrandCode,
              model: selectedModelLabel ?? trimmedModel,
              modelCode: _selectedVehicleFipeModelCode,
              year: parsedYear,
              yearCode: _selectedVehicleFipeYearCode,
              yearLabel: selectedYearLabel,
              color: _normalizeOptional(color),
              plate: trimmedPlate,
              loadCapacityKg: parsedLoadCapacity,
              widthCm: parsedWidth,
              heightCm: parsedHeight,
              lengthCm: parsedLength,
              status: status,
            )
          : RegisterVehicleModel(
              userId: _fixedUserId,
              vehicleTypeId: _selectedVehicleTypeId!,
              brand: trimmedBrand,
              model: trimmedModel,
              year: parsedYear,
              yearLabel: trimmedYear,
              color: _normalizeOptional(color),
              plate: trimmedPlate,
              loadCapacityKg: parsedLoadCapacity,
              widthCm: parsedWidth,
              heightCm: parsedHeight,
              lengthCm: parsedLength,
              status: status,
            );

      _registeredVehicle = await _registerVehicleRepository.registerVehicle(
        payload,
      );
      return true;
    } on RegisterVehicleRepositoryException catch (e) {
      _registerVehicleError = e.message;
      return false;
    } catch (_) {
      _registerVehicleError = 'Não foi possível cadastrar o veículo agora.';
      return false;
    } finally {
      _setRegistering(false);
    }
  }

  void _setLoading(bool value) {
    _isLoadingVehicleTypes = value;
    notifyListeners();
  }

  void _setLoadingVehicleFipe(bool value) {
    _isLoadingVehicleFipe = value;
    notifyListeners();
  }

  void _setRegistering(bool value) {
    _isRegisteringVehicle = value;
    notifyListeners();
  }

  void _resetVehicleFipeSelection() {
    _vehicleFipeBrands = <VehicleFipeOptionModel>[];
    _vehicleFipeModels = <VehicleFipeOptionModel>[];
    _vehicleFipeYears = <VehicleFipeOptionModel>[];
    _selectedVehicleFipeBrandCode = null;
    _selectedVehicleFipeModelCode = null;
    _selectedVehicleFipeYearCode = null;
    _vehicleFipeError = null;
  }

  String? _selectedLabel(
    List<VehicleFipeOptionModel> options,
    String? selectedValue,
  ) {
    if (selectedValue == null) {
      return null;
    }

    for (final VehicleFipeOptionModel option in options) {
      if (option.value == selectedValue) {
        return option.label;
      }
    }

    return null;
  }

  int _extractYearFromLabel(String? label) {
    if (label == null || label.trim().isEmpty) {
      return -1;
    }

    final Match? match = RegExp(r'\d{4}').firstMatch(label);
    if (match == null) {
      return -1;
    }

    return int.tryParse(match.group(0) ?? '') ?? -1;
  }

  int? _parseOptionalInt(String? value) {
    final String cleaned = (value ?? '').trim();
    if (cleaned.isEmpty) {
      return null;
    }
    return int.tryParse(cleaned);
  }

  String? _normalizeOptional(String? value) {
    final String cleaned = (value ?? '').trim();
    if (cleaned.isEmpty) {
      return null;
    }
    return cleaned;
  }
}
