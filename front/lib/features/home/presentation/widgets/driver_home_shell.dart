import 'package:flutter/material.dart';

import '../../../../app/design_system/design_system.dart';
import '../../../driver_operations/presentation/pages/driver_operations_page.dart';
import '../../../profile/presentation/pages/driver_profile_page.dart';
import '../../../rides/presentation/pages/ride_history_page.dart';
import '../controllers/driver_availability_controller.dart';
import 'driver_home_content.dart';

class DriverHomeShell extends StatefulWidget {
  final String userName;
  final int userId;
  final DriverAvailabilityController availabilityController;
  final int cancellationRefreshVersion;

  const DriverHomeShell({
    super.key,
    required this.userName,
    required this.userId,
    required this.availabilityController,
    this.cancellationRefreshVersion = 0,
  });

  @override
  State<DriverHomeShell> createState() => _DriverHomeShellState();
}

class _DriverHomeShellState extends State<DriverHomeShell>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;
  int _homeRefreshVersion = 0;
  int _historyRefreshVersion = 0;
  int _walletRefreshVersion = 0;
  final List<bool> _visitedTabs = <bool>[true, false, false, false];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _selectedIndex == 0) {
      setState(() => _homeRefreshVersion++);
    }
  }

  void _selectTab(int index) {
    if (_selectedIndex == index) {
      if (index == 0 || index == 1 || index == 2) {
        setState(() {
          if (index == 0) _homeRefreshVersion++;
          if (index == 1) _historyRefreshVersion++;
          if (index == 2) _walletRefreshVersion++;
        });
      }
      return;
    }

    setState(() {
      _selectedIndex = index;
      _visitedTabs[index] = true;
      if (index == 0) _homeRefreshVersion++;
      if (index == 1) _historyRefreshVersion++;
      if (index == 2) _walletRefreshVersion++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FretColors.screenBackground,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          SafeArea(
            child: Column(
              children: [
                _DriverHomeHeader(
                  availabilityController: widget.availabilityController,
                  onProfileTap: () => _selectTab(3),
                ),
                Expanded(
                  child: DriverHomeContent(
                    firstName: widget.userName,
                    userId: widget.userId,
                    availabilityController: widget.availabilityController,
                    refreshVersion: _homeRefreshVersion,
                    cancellationRefreshVersion:
                        widget.cancellationRefreshVersion,
                    onHistoryTap: () => _selectTab(1),
                    onWalletTap: () => _selectTab(2),
                  ),
                ),
              ],
            ),
          ),
          _visitedTabs[1]
              ? RideHistoryPage(
                  showBackButton: false,
                  refreshVersion: _historyRefreshVersion,
                )
              : const SizedBox.shrink(),
          _visitedTabs[2]
              ? DriverOperationsPage(
                  userId: widget.userId,
                  showBackButton: false,
                  refreshVersion: _walletRefreshVersion,
                )
              : const SizedBox.shrink(),
          _visitedTabs[3]
              ? DriverProfilePage(userId: widget.userId)
              : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: _DriverBottomNavigation(
        currentIndex: _selectedIndex,
        onTap: _selectTab,
      ),
    );
  }
}

class _DriverHomeHeader extends StatelessWidget {
  final DriverAvailabilityController availabilityController;
  final VoidCallback onProfileTap;

  const _DriverHomeHeader({
    required this.availabilityController,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
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
              ),
              children: [
                TextSpan(
                  text: 'Já',
                  style: TextStyle(color: FretColors.screenGold),
                ),
              ],
            ),
          ),
          const Spacer(),
          AnimatedBuilder(
            animation: availabilityController,
            builder: (context, _) {
              return IconButton(
                tooltip: 'Perfil',
                onPressed: onProfileTap,
                icon: _DriverHeaderAvatar(
                  isOnline: availabilityController.isOnline,
                  showStatus: availabilityController.hasLoadedStatus,
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

class _DriverHeaderAvatar extends StatelessWidget {
  final bool isOnline;
  final bool showStatus;

  const _DriverHeaderAvatar({required this.isOnline, required this.showStatus});

  @override
  Widget build(BuildContext context) {
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
                color: isOnline ? FretColors.success500 : FretColors.neutral400,
                shape: BoxShape.circle,
                border: Border.all(color: FretColors.brandBlack, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

class _DriverBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _DriverBottomNavigation({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const labels = ['Início', 'Corridas', 'Carteira', 'Perfil'];
    const icons = [
      Icons.home_outlined,
      Icons.local_shipping_outlined,
      Icons.account_balance_wallet_outlined,
      Icons.person_outline_rounded,
    ];

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: FretColors.white,
        border: Border(top: BorderSide(color: FretColors.screenBorder)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Row(
            children: List.generate(labels.length, (index) {
              final selected = currentIndex == index;
              final color = selected
                  ? FretColors.screenGold
                  : FretColors.screenMuted;

              return Expanded(
                child: Semantics(
                  selected: selected,
                  button: true,
                  child: InkWell(
                    onTap: () => onTap(index),
                    child: Column(
                      children: [
                        Container(
                          width: 20,
                          height: 2,
                          color: selected
                              ? FretColors.screenGold
                              : Colors.transparent,
                        ),
                        const SizedBox(height: 12),
                        Icon(icons[index], size: 22, color: color),
                        const SizedBox(height: 5),
                        Text(
                          labels[index],
                          style: TextStyle(
                            fontSize: 10,
                            color: color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
