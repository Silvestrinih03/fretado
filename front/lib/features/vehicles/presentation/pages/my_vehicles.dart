import 'package:flutter/material.dart';

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
    void openRegisterVehicle() {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => RegisterVehiclePage(userId: widget.userId),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _store,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF3F4F8),
          body: SafeArea(
            child: Column(
              children: [
                _MyVehiclesHeader(onAddTap: openRegisterVehicle),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
                    children: [
                      if (_store.isLoading) ...[
                        const Padding(
                          padding: EdgeInsets.only(top: 24),
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      ] else if (_store.errorMessage != null) ...[
                        _EmptyState(
                          title: 'Não foi possível carregar seus veículos',
                          subtitle: _store.errorMessage!,
                          onTap: _store.loadVehicles,
                        ),
                      ] else if (_store.vehicles.isEmpty) ...[
                        _EmptyState(
                          title: 'Nenhum veículo cadastrado',
                          subtitle:
                              'Cadastre o primeiro veículo para começar.',
                          onTap: openRegisterVehicle,
                        ),
                      ] else ...[
                        ..._store.vehicles.asMap().entries.map((entry) {
                          final index = entry.key;
                          final vehicle = entry.value;

                          return Column(
                            children: [
                              VehicleCard(
                                plate: vehicle.plate,
                                year: vehicle.yearText,
                                brand: vehicle.brand,
                                model: vehicle.model,
                                statusLabel: vehicle.statusLabel,
                                statusBackgroundColor: vehicle.isActive
                                    ? const Color(0xFFF2D45C)
                                    : const Color(0xFFE4E6EC),
                                statusTextColor: vehicle.isActive
                                    ? const Color(0xFF4A3D00)
                                    : const Color(0xFF4B505D),
                              ),
                              if (index != _store.vehicles.length - 1)
                                const SizedBox(height: 16),
                            ],
                          );
                        }),
                        const SizedBox(height: 20),
                        _NewVehicleCallout(onTap: openRegisterVehicle),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _EmptyState({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E6EE)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.local_shipping_outlined,
            size: 44,
            color: Color(0xFF9CA0C8),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF121E84),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF6B7285),
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0E1386),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Cadastrar veículo'),
          ),
        ],
      ),
    );
  }
}

class _MyVehiclesHeader extends StatelessWidget {
  final VoidCallback onAddTap;

  const _MyVehiclesHeader({required this.onAddTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 94,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      decoration: const BoxDecoration(
        color: Color(0xFFF3F4F8),
        border: Border(
          bottom: BorderSide(color: Color(0xFFE7E9F0), width: 1),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF121E84),
              size: 24,
            ),
          ),
          const SizedBox(width: 6),
          const Expanded(
            child: Text(
              'Meus veículos',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Color(0xFF121E84),
              ),
            ),
          ),
          InkWell(
            onTap: onAddTap,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: 78,
              height: 62,
              decoration: BoxDecoration(
                color: const Color(0xFF0E1386),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NewVehicleCallout extends StatelessWidget {
  final VoidCallback onTap;

  const _NewVehicleCallout({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFD8DBE6),
            width: 1.2,
            strokeAlign: BorderSide.strokeAlignOutside,
          ),
        ),
        child: const Column(
          children: [
            CircleAvatar(
              radius: 21,
              backgroundColor: Color(0xFF6C74B7),
              child: Icon(Icons.add_rounded, color: Colors.white, size: 30),
            ),
            SizedBox(height: 14),
            Text(
              'Novo Veículo',
              style: TextStyle(
                fontSize: 20,
                color: Color(0xFF5A61A3),
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Cadastre um novo veículo no sistema.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                height: 1.3,
                color: Color(0xFF8B8F9E),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
