import 'package:flutter/material.dart';

import '../../../../app/design_system/design_system.dart';
import '../../../../core/enums/home_profile.dart';
import '../../../payments/presentation/pages/my_payment_methods_page.dart';
import '../../../profile/presentation/pages/client_profile_page.dart';
import '../../../rides/presentation/pages/ride_history_page.dart';
import 'client_home_content.dart';

class ClientHomeShell extends StatefulWidget {
  final String userName;
  final int userId;

  const ClientHomeShell({
    super.key,
    required this.userName,
    required this.userId,
  });

  @override
  State<ClientHomeShell> createState() => _ClientHomeShellState();
}

class _ClientHomeShellState extends State<ClientHomeShell> {
  int _selectedIndex = 0;
  final List<bool> _visitedTabs = <bool>[true, false, false, false];

  void _selectTab(int index) {
    if (_selectedIndex == index) {
      return;
    }

    setState(() {
      _selectedIndex = index;
      _visitedTabs[index] = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FretColors.appBackground,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          SafeArea(
            child: Column(
              children: [
                _ClientHomeHeader(onProfileTap: () => _selectTab(3)),
                Expanded(
                  child: ClientHomeContent(
                    userName: widget.userName,
                    userId: widget.userId,
                    onHistoryTap: () => _selectTab(1),
                    onPaymentMethodsTap: () => _selectTab(2),
                  ),
                ),
              ],
            ),
          ),
          _visitedTabs[1]
              ? RideHistoryPage(
                  userId: widget.userId,
                  profile: HomeProfileEnum.client,
                  showBackButton: false,
                )
              : const SizedBox.shrink(),
          _visitedTabs[2]
              ? MyPaymentMethodsPage(
                  userId: widget.userId,
                  showBackButton: false,
                )
              : const SizedBox.shrink(),
          _visitedTabs[3]
              ? ClientProfilePage(userId: widget.userId)
              : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: _ClientBottomNavigation(
        currentIndex: _selectedIndex,
        onTap: _selectTab,
      ),
    );
  }
}

class _ClientHomeHeader extends StatelessWidget {
  final VoidCallback onProfileTap;

  const _ClientHomeHeader({required this.onProfileTap});

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
          IconButton(
            tooltip: 'Perfil',
            onPressed: onProfileTap,
            icon: Container(
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
          ),
          const SizedBox(width: 18),
        ],
      ),
    );
  }
}

class _ClientBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _ClientBottomNavigation({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const labels = ['Início', 'Corridas', 'Pagamentos', 'Perfil'];
    const icons = [
      Icons.home_outlined,
      Icons.local_shipping_outlined,
      Icons.credit_card_outlined,
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
