import 'package:flutter/material.dart';

import '../../../../app/design_system/design_system.dart';
import '../controllers/driver_availability_controller.dart';
import 'home_drawer.dart';

class HomeShell extends StatelessWidget {
  final Widget content;
  final int? userId;
  final int? userTypeId;
  final DriverAvailabilityController? driverAvailabilityController;

  const HomeShell({
    super.key,
    required this.content,
    this.userId,
    this.userTypeId,
    this.driverAvailabilityController,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F7),
      endDrawer: HomeDrawer(
        userId: userId,
        userTypeId: userTypeId,
        driverAvailabilityController: driverAvailabilityController,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _HomeHeader(
              driverAvailabilityController: driverAvailabilityController,
            ),
            Expanded(child: content),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  final DriverAvailabilityController? driverAvailabilityController;

  const _HomeHeader({this.driverAvailabilityController});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      decoration: const BoxDecoration(
        color: FretColors.neutral050,
        border: Border(bottom: BorderSide(color: FretColors.neutral200)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          const Text(
            'FreteJá',
            style: TextStyle(
              color: FretColors.loginFooterLink,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
          const Spacer(),
          Builder(
            builder: (context) {
              final controller = driverAvailabilityController;
              final Widget avatarButton = IconButton(
                tooltip: 'Menu',
                onPressed: () => Scaffold.of(context).openEndDrawer(),
                icon: _HeaderAvatar(
                  isOnline: controller?.isOnline,
                ),
              );

              if (controller == null) {
                return avatarButton;
              }

              return AnimatedBuilder(
                animation: controller,
                builder: (_, __) => IconButton(
                  tooltip: 'Menu',
                  onPressed: () => Scaffold.of(context).openEndDrawer(),
                  icon: _HeaderAvatar(isOnline: controller.isOnline),
                ),
              );
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }
}

class _HeaderAvatar extends StatelessWidget {
  final bool? isOnline;

  const _HeaderAvatar({required this.isOnline});

  @override
  Widget build(BuildContext context) {
    final bool showStatus = isOnline != null;
    final Color statusColor = isOnline == true
        ? FretColors.success500
        : FretColors.destructive600;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: FretColors.primary100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.person,
            color: FretColors.loginFooterLink,
          ),
        ),
        if (showStatus)
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
                border: Border.all(color: FretColors.neutral050, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}
