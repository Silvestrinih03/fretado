import 'package:flutter/material.dart' hide NavigationDestination;

import '../../../../app/design_system/design_system.dart';
import '../../../../core/services/session/session_storage.dart';
import '../../../driver_operations/data/models/driver_operation_models.dart';
import '../../data/driver_navigation_models.dart';
import '../pages/driver_navigation_page.dart';

class DriverNavigationAccessButton extends StatelessWidget {
  final DriverRideModel ride;
  final ValueChanged<bool>? onChanged;
  final VoidCallback? beforeOpen;

  const DriverNavigationAccessButton({
    super.key,
    required this.ride,
    this.onChanged,
    this.beforeOpen,
  });

  @override
  Widget build(BuildContext context) {
    final destination = NavigationDestination.fromRide(ride);
    final userId = SessionStorage.instance.currentUserId;
    if (destination == null || userId == null || ride.driverUserId != userId) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Destino: ${destination.title}',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          ),
          const SizedBox(height: 3),
          Text(
            destination.address,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: FretColors.textSecondary,
            ),
          ),
          const SizedBox(height: 7),
          OutlinedButton.icon(
            icon: const Icon(Icons.map_outlined),
            label: Text(destination.routeLabel),
            style: OutlinedButton.styleFrom(
              foregroundColor: FretColors.screenDark,
              minimumSize: const Size.fromHeight(44),
            ),
            onPressed: () async {
              final navigator = Navigator.of(context);
              beforeOpen?.call();
              final finished = await navigator.push<bool>(
                MaterialPageRoute<bool>(
                  builder: (_) =>
                      DriverNavigationPage(rideId: ride.id, userId: userId),
                ),
              );
              onChanged?.call(finished == true);
            },
          ),
        ],
      ),
    );
  }
}
