import 'package:flutter/material.dart';

import '../../../../core/services/http_service.dart';
import '../../../../core/services/myself/services/myself_service.dart';
import '../../data/datasources/vehicle_type_datasource.dart';
import '../../data/datasources/register_vehicle_datasource.dart';
import '../../data/datasources/vehicle_fipe_datasource.dart';
import '../../data/repositories/register_vehicle_repository_impl.dart';
import '../../data/repositories/vehicle_fipe_repository_impl.dart';
import '../../data/repositories/vehicle_type_repository_impl.dart';
import '../stores/register_vehicle_store.dart';
import 'package:front/features/vehicles/presentation/widgets/select_vehicle_type.dart';
import 'package:front/features/vehicles/presentation/widgets/fill_vehicle_brand_data.dart';
import 'package:front/features/vehicles/presentation/widgets/fill_vehicle_load_capacity.dart';
import 'package:front/features/vehicles/presentation/widgets/fill_vehicle_plate.dart';
import 'package:front/features/vehicles/presentation/widgets/fill_vehicle_detailed_data.dart';
//import 'package:front/features/vehicles/presentation/widgets/fill_vehicle_activation.dart';

class RegisterVehiclePage extends StatefulWidget {
  final int? userId;

  const RegisterVehiclePage({super.key, this.userId});

  @override
  State<RegisterVehiclePage> createState() => _RegisterVehiclePageState();
}

class _RegisterVehiclePageState extends State<RegisterVehiclePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final HttpService _httpService;
  late final VehicleTypeDatasource _vehicleTypeDatasource;
  late final VehicleTypeRepositoryImpl _vehicleTypeRepository;
  late final VehicleFipeDatasource _vehicleFipeDatasource;
  late final VehicleFipeRepositoryImpl _vehicleFipeRepository;
  late final RegisterVehicleDatasource _registerVehicleDatasource;
  late final RegisterVehicleRepositoryImpl _registerVehicleRepository;
  late final MyselfService _myselfService;
  late final RegisterVehicleStore _store;

  String _registerMode = 'fipe';
  bool _isActive = true;

  final TextEditingController _plateController = TextEditingController();
  final TextEditingController _loadCapacityController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _widthController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _lengthController = TextEditingController();

  final TextEditingController _manualBrandController = TextEditingController();
  final TextEditingController _manualModelController = TextEditingController();
  final TextEditingController _manualYearController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _httpService = HttpService();
    _vehicleTypeDatasource = VehicleTypeDatasource(_httpService);
    _vehicleTypeRepository = VehicleTypeRepositoryImpl(_vehicleTypeDatasource);
    _vehicleFipeDatasource = VehicleFipeDatasource(_httpService);
    _vehicleFipeRepository = VehicleFipeRepositoryImpl(_vehicleFipeDatasource);
    _registerVehicleDatasource = RegisterVehicleDatasource(_httpService);
    _registerVehicleRepository = RegisterVehicleRepositoryImpl(
      _registerVehicleDatasource,
    );
    _myselfService = MyselfService();
    if (widget.userId != null) {
      _myselfService.currentUserId = widget.userId;
    }
    _store = RegisterVehicleStore(
      _vehicleTypeRepository,
      _vehicleFipeRepository,
      _registerVehicleRepository,
      _myselfService,
    );
    _store.loadVehicleTypes();
  }

  @override
  void dispose() {
    _store.dispose();
    _httpService.dispose();
    _plateController.dispose();
    _loadCapacityController.dispose();
    _colorController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _lengthController.dispose();
    _manualBrandController.dispose();
    _manualModelController.dispose();
    _manualYearController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_store.selectedVehicleTypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione o tipo de veículo.')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final bool success = await _store.registerVehicle(
      registerMode: _registerMode,
      brand: _manualBrandController.text,
      model: _manualModelController.text,
      year: _manualYearController.text,
      plate: _plateController.text,
      loadCapacityKg: _loadCapacityController.text,
      color: _colorController.text,
      widthCm: _widthController.text,
      heightCm: _heightController.text,
      lengthCm: _lengthController.text,
      status: _isActive,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veículo cadastrado com sucesso.')),
      );
      return;
    }

    final String errorMessage =
        _store.registerVehicleError ?? 'Não foi possível cadastrar o veículo.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(errorMessage)));
  }

  String? _requiredValidator(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe $fieldName';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _store,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF1F2F6),
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 14),
                  SelectVehicleType(
                    isLoading: _store.isLoadingVehicleTypes,
                    errorMessage: _store.vehicleTypesError,
                    vehicleTypes: _store.vehicleTypes,
                    selectedVehicleTypeId: _store.selectedVehicleTypeId,
                    onSelected: (id) async {
                      _store.selectVehicleType(id);
                      if (_registerMode == 'fipe') {
                        await _store.loadVehicleFipeBrands();
                      }
                    },
                  ),
                  const SizedBox(height: 18),
                  FillVehicleBrandData(
                    registerMode: _registerMode,
                    onRegisterModeChanged: (value) {
                      setState(() => _registerMode = value);
                      if (value == 'fipe' && _store.selectedVehicleTypeId != null) {
                        _store.loadVehicleFipeBrands();
                      }
                    },
                    isLoadingFipe: _store.isLoadingVehicleFipe,
                    errorMessage: _store.vehicleFipeError,
                    selectedBrand: _store.selectedVehicleFipeBrandCode,
                    selectedModel: _store.selectedVehicleFipeModelCode,
                    selectedYear: _store.selectedVehicleFipeYearCode,
                    brands: _store.vehicleFipeBrands,
                    models: _store.vehicleFipeModels,
                    years: _store.vehicleFipeYears,
                    manualBrandController: _manualBrandController,
                    manualModelController: _manualModelController,
                    manualYearController: _manualYearController,
                    onBrandChanged: (value) {
                      _store.selectVehicleFipeBrand(value);
                      if (value != null && _registerMode == 'fipe') {
                        _store.loadVehicleFipeModels();
                      }
                    },
                    onModelChanged: (value) {
                      _store.selectVehicleFipeModel(value);
                      if (value != null && _registerMode == 'fipe') {
                        _store.loadVehicleFipeYears();
                      }
                    },
                    onYearChanged: (value) {
                      _store.selectVehicleFipeYear(value);
                    },
                    requiredValidator: _requiredValidator,
                  ),
                  const SizedBox(height: 16),
                  FillVehiclePlate(
                    controller: _plateController,
                    requiredValidator: _requiredValidator,
                  ),
                  const SizedBox(height: 14),
                  FillVehicleLoadCapacity(
                    controller: _loadCapacityController,
                    requiredValidator: _requiredValidator,
                  ),
                  const SizedBox(height: 14),
                  FillVehicleDetailedData(
                    colorController: _colorController,
                    widthController: _widthController,
                    heightController: _heightController,
                    lengthController: _lengthController,
                  ),
                  const SizedBox(height: 14),
                  // FillVehicleActivation(
                  //   isActive: _isActive,
                  //   onChanged: (value) {
                  //     setState(() => _isActive = value);
                  //   },
                  // ),
                  const SizedBox(height: 18),
                  _buildBottomActionBar(context),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        color: Color(0xFFF1F2F6),
        border: Border(bottom: BorderSide(color: Color(0xFFE2E4EC))),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: Color(0xFF111B83),
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'Cadastrar veículo',
            style: TextStyle(
              color: Color(0xFF111B83),
              fontSize: 34,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(BuildContext context) {
    // mudar para widget separado, melhorar tbm
    return Container(
      color: const Color(0xFFF1F2F6),
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF121B85),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _store.isRegisteringVehicle ? null : _save,
                child: Text(
                  _store.isRegisteringVehicle
                      ? 'Cadastrando...'
                      : 'Cadastrar veículo',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  color: Color(0xFFB15D16),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'FreteJá - 2026',
              style: TextStyle(
                color: Color(0xFFB4B8C6),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
