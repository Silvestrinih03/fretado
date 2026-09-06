import 'package:flutter/material.dart';

import '../../../../app/design_system/design_system.dart';

import '../../../../core/services/http_service.dart';
import '../../../../core/services/myself/services/myself_service.dart';
import '../../data/datasources/vehicle_datasource.dart';
import '../../data/repositories/vehicle_repository_impl.dart';
import '../stores/my_vehicles_store.dart';
import 'register_vehicle_page.dart';
import '../widgets/vehicle_card.dart';

class MyVehiclesPage extends StatefulWidget {
  final int? userId;

  const MyVehiclesPage({super.key, this.userId});

  @override
  State<MyVehiclesPage> createState() => _MyVehiclesPageState();
}

class _MyVehiclesPageState extends State<MyVehiclesPage> {
  late final HttpService _httpService;
  late final VehicleDatasource _vehicleDatasource;
  late final VehicleRepositoryImpl _vehicleRepository;
  late final MyselfService _myselfService;
  late final MyVehiclesStore _store;

  @override
  void initState() {
    super.initState();
    _httpService = HttpService();
    _vehicleDatasource = VehicleDatasource(_httpService);
    _vehicleRepository = VehicleRepositoryImpl(_vehicleDatasource);
    _myselfService = MyselfService();
    if (widget.userId != null) {
      _myselfService.currentUserId = widget.userId;
    }
    _store = MyVehiclesStore(
      _vehicleRepository,
      _myselfService,
      fallbackUserId: widget.userId,
    );
    _store.loadVehicles();
  }

  @override
  void dispose() {
    _store.dispose();
    _httpService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _store,
      builder: (context, _) => Scaffold(
        backgroundColor: FretColors.appBackground,
        appBar: AppBar(
          title: const Text('Meus veículos'),
          backgroundColor: FretColors.appBackground,
          foregroundColor: FretColors.textPrimary,
          actions: [
            IconButton(
              tooltip: 'Adicionar veículo',
              onPressed: _openRegisterVehicle,
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _store.loadVehicles,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Gerencie seus veículos',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: FretColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                if (_store.isLoading)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_store.errorMessage != null)
                  _VehiclesState(
                    icon: Icons.error_outline_rounded,
                    title: 'Não foi possível carregar seus veículos',
                    subtitle: _store.errorMessage!,
                    action: 'Tentar novamente',
                    onPressed: _store.loadVehicles,
                  )
                else if (_store.vehicles.isEmpty)
                  _VehiclesState(
                    icon: Icons.local_shipping_outlined,
                    title: 'Nenhum veículo cadastrado',
                    subtitle: 'Adicione seu primeiro veículo para começar.',
                    action: 'Adicionar veículo',
                    onPressed: _openRegisterVehicle,
                  )
                else ...[
                  Text(
                    '${_store.vehicles.length} ${_store.vehicles.length == 1 ? 'veículo cadastrado' : 'veículos cadastrados'}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 16),
                  for (final vehicle in _store.vehicles)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: VehicleCard(
                        key: ValueKey(vehicle.id),
                        vehicle: vehicle,
                      ),
                    ),
                  const SizedBox(height: 8),
                  FretPrimaryButton(
                    label: 'Adicionar veículo',
                    trailingIcon: Icons.add_rounded,
                    onPressed: _openRegisterVehicle,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openRegisterVehicle() async {
    final didRegister = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => RegisterVehiclePage(userId: widget.userId),
      ),
    );
    if (!mounted) return;
    if (didRegister == true) await _store.loadVehicles();
  }
}

class _VehiclesState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String action;
  final VoidCallback onPressed;

  const _VehiclesState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.action,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FretSurfaceCard(
      child: Column(
        children: [
          FretIconBox(icon: icon, size: 48, iconSize: 26),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: FretColors.textSecondary),
          ),
          const SizedBox(height: 24),
          FretPrimaryButton(
            label: action,
            onPressed: onPressed,
            trailingIcon: null,
          ),
        ],
      ),
    );
  }
}
