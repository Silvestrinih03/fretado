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
      backgroundColor: FretColors.appBackground,
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
      height: 72,
      color: FretColors.appBackground,
      child: Row(
        children: [
          const SizedBox(width: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/logo_fretado.png',
              width: 32,
              height: 32,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
            ),
          ),
          const SizedBox(width: 10),
          RichText(
            text: const TextSpan(
              text: 'Frete',
              style: TextStyle(
                color: FretColors.brandBlack,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
              children: [
                TextSpan(
                  text: 'J\u00e1',
                  style: TextStyle(color: FretColors.brandGold),
                ),
              ],
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
          const SizedBox(width: 18),
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
            color: FretColors.brandBlack,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.person_outline_rounded,
            color: FretColors.white,
            size: 19,
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
                border: Border.all(color: FretColors.appBackground, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}
