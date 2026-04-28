import 'package:flutter/material.dart';

import 'register_vehicle_page.dart';

class MyVehiclesPage extends StatelessWidget {
  const MyVehiclesPage({super.key});

  @override
  Widget build(BuildContext context) {
    void openRegisterVehicle() {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const RegisterVehiclePage()),
      );
    }

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
                  const _VehicleCard(
                    title: 'Volvo FH 540',
                    plate: 'ABC-1234',
                    year: '2022',
                    brand: 'Volvo Trucks Brazil - FH 540',
                    statusLabel: 'ATIVO',
                    statusBackgroundColor: Color(0xFFF2D45C),
                    statusTextColor: Color(0xFF4A3D00),
                  ),
                  const SizedBox(height: 16),
                  const _VehicleCard(
                    title: 'Scania R500',
                    plate: 'XYZ-9876',
                    year: '2021',
                    brand: 'Scania Latin America - R500',
                    statusLabel: 'MANUTENCAO',
                    statusBackgroundColor: Color(0xFFE4E6EC),
                    statusTextColor: Color(0xFF4B505D),
                  ),
                  const SizedBox(height: 16),
                  const _VehicleCard(
                    title: 'Mercedes Axor',
                    plate: 'KML-4455',
                    year: '2023',
                    brand: 'Mercedes-Benz - Axor',
                    statusLabel: 'ATIVO',
                    statusBackgroundColor: Color(0xFFF2D45C),
                    statusTextColor: Color(0xFF4A3D00),
                  ),
                  const SizedBox(height: 20),
                  _NewVehicleCallout(onTap: openRegisterVehicle),
                ],
              ),
            ),
          ],
        ),
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
        border: Border(bottom: BorderSide(color: Color(0xFFE7E9F0), width: 1)),
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

class _VehicleCard extends StatelessWidget {
  final String title;
  final String plate;
  final String year;
  final String brand;
  final String statusLabel;
  final Color statusBackgroundColor;
  final Color statusTextColor;

  const _VehicleCard({
    required this.title,
    required this.plate,
    required this.year,
    required this.brand,
    required this.statusLabel,
    required this.statusBackgroundColor,
    required this.statusTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4E6EE)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F1A4A),
            blurRadius: 9,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 92,
              decoration: const BoxDecoration(
                color: Color(0xFFF0F1F4),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.local_shipping_rounded,
                  size: 58,
                  color: Color(0xFF9CA0C8),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF121E84),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusBackgroundColor,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              color: statusTextColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _VehicleMetaItem(label: 'PLACA', value: plate),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _VehicleMetaItem(label: 'ANO', value: year),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const _VehicleMetaItem(label: 'MARCA'),
                    const SizedBox(height: 4),
                    Text(
                      brand,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF101114),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleMetaItem extends StatelessWidget {
  final String label;
  final String? value;

  const _VehicleMetaItem({required this.label, this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFF9296A5),
            letterSpacing: 1.5,
          ),
        ),
        if (value != null) ...[
          const SizedBox(height: 3),
          Text(
            value!,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0E1015),
            ),
          ),
        ],
      ],
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
              'Novo Veiculo',
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
