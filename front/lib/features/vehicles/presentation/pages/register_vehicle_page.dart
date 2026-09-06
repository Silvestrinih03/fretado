import 'package:flutter/material.dart';

import '../../../../app/design_system/design_system.dart';
import '../../../../core/services/http_service.dart';
import '../../../../core/services/myself/services/myself_service.dart';
import '../../data/datasources/vehicle_type_datasource.dart';
import '../../data/datasources/register_vehicle_datasource.dart';
import '../../data/datasources/vehicle_catalog_datasource.dart';
import '../../data/repositories/register_vehicle_repository_impl.dart';
import '../../data/repositories/vehicle_catalog_repository_impl.dart';
import '../../data/repositories/vehicle_type_repository_impl.dart';
import '../stores/register_vehicle_store.dart';
import '../widgets/select_vehicle_type.dart';
import '../widgets/fill_vehicle_brand_data.dart';
import '../widgets/fill_vehicle_plate.dart';
import '../widgets/fill_vehicle_detailed_data.dart';

class RegisterVehiclePage extends StatefulWidget {
  final int? userId;
  const RegisterVehiclePage({super.key, this.userId});

  @override
  State<RegisterVehiclePage> createState() => _RegisterVehiclePageState();
}

class _RegisterVehiclePageState extends State<RegisterVehiclePage> {
  final _formKey = GlobalKey<FormState>();
  final _plateController = TextEditingController();
  final _colorController = TextEditingController();
  late final HttpService _httpService;
  late final RegisterVehicleStore _store;

  @override
  void initState() {
    super.initState();
    _httpService = HttpService();
    final myself = MyselfService();
    if (widget.userId != null) myself.currentUserId = widget.userId;
    _store = RegisterVehicleStore(
      VehicleTypeRepositoryImpl(VehicleTypeDatasource(_httpService)),
      VehicleCatalogRepositoryImpl(VehicleCatalogDatasource(_httpService)),
      RegisterVehicleRepositoryImpl(RegisterVehicleDatasource(_httpService)),
      myself,
    );
    _store.loadVehicleTypes();
    _store.loadBrands();
  }

  @override
  void dispose() {
    _store.dispose();
    _httpService.dispose();
    _plateController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_store.isRegisteringVehicle) return;
    if (!_formKey.currentState!.validate()) return;
    if (_store.selectedVehicleTypeId == null) {
      showFretErrorPopup(context, message: 'Selecione o tipo de veículo.');
      return;
    }
    FocusScope.of(context).unfocus();
    final success = await _store.registerVehicle(
      plate: _plateController.text,
      color: _colorController.text,
    );
    if (!mounted) return;
    if (success) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop(true);
      messenger.showSnackBar(
        const SnackBar(content: Text('Ve?culo cadastrado com sucesso.')),
      );
    } else {
      showFretErrorPopup(
        context,
        message:
            _store.registerVehicleError ??
            'Não foi possível cadastrar o veículo.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _store,
      builder: (context, _) => PopScope(
        canPop: !_store.isRegisteringVehicle,
        child: Scaffold(
          backgroundColor: FretColors.appBackground,
          appBar: AppBar(
            backgroundColor: FretColors.appBackground,
            foregroundColor: FretColors.textPrimary,
            title: const Text('Adicionar veículo'),
          ),
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Selecione os dados do veículo. As informações técnicas serão identificadas automaticamente.',
                    style: TextStyle(
                      color: FretColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  AbsorbPointer(
                    absorbing: _store.isRegisteringVehicle,
                    child: Column(
                      children: [
                        FretSurfaceCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SelectVehicleType(
                                isLoading: _store.isLoadingVehicleTypes,
                                errorMessage: _store.vehicleTypesError,
                                vehicleTypes: _store.vehicleTypes,
                                selectedVehicleTypeId:
                                    _store.selectedVehicleTypeId,
                                onSelected: _store.selectVehicleType,
                              ),
                              if (!_store.isLoadingVehicleTypes &&
                                  (_store.vehicleTypesError != null ||
                                      _store.vehicleTypes.isEmpty))
                                TextButton(
                                  onPressed: _store.loadVehicleTypes,
                                  child: const Text('Tentar novamente'),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        FillVehicleBrandData(store: _store),
                        const SizedBox(height: 16),
                        FillVehicleDetailedData(
                          colorController: _colorController,
                          enabled: _store.selectedYear != null,
                        ),
                        const SizedBox(height: 16),
                        FillVehiclePlate(
                          controller: _plateController,
                          enabled: _store.selectedYear != null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  FretPrimaryButton(
                    label: 'Cadastrar veículo',
                    loading: _store.isRegisteringVehicle,
                    onPressed: _save,
                    trailingIcon: null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
