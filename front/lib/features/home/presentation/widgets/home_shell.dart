import 'package:flutter/material.dart';

import '../../../../app/design_system/design_system.dart';

class HomeShell extends StatelessWidget {
  final Widget content;

  const HomeShell({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F7),
      drawer: const _HomeDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            const _HomeHeader(),
            Expanded(child: content),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      decoration: const BoxDecoration(
        color: FretColors.neutral050,
        border: Border(bottom: BorderSide(color: FretColors.neutral200)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Builder(
            builder: (context) {
              return IconButton(
                onPressed: () => Scaffold.of(context).openDrawer(),
                icon: const Icon(
                  Icons.menu_rounded,
                  color: FretColors.loginFooterLink,
                ),
              );
            },
          ),
          const SizedBox(width: 10),
          const Text(
            'FreteJá',
            style: TextStyle(
              color: FretColors.loginFooterLink,
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const Spacer(),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: FretColors.primary100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.person, color: FretColors.loginFooterLink),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}

class _HomeDrawer extends StatelessWidget {
  const _HomeDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: FretColors.loginFooterLink,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: FretColors.white,
                    child: Icon(
                      Icons.person,
                      color: FretColors.loginFooterLink,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Menu lateral',
                    style: TextStyle(
                      color: FretColors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Placeholder até receber o protótipo',
                    style: TextStyle(color: FretColors.primary100),
                  ),
                ],
              ),
            ),
            _DrawerItem(
              icon: Icons.home_outlined,
              label: 'Início',
              onTap: () => Navigator.of(context).pop(),
            ),
            _DrawerItem(
              icon: Icons.directions_bus_outlined,
              label: 'Corridas',
              onTap: () => Navigator.of(context).pop(),
            ),
            _DrawerItem(
              icon: Icons.settings_outlined,
              label: 'Configurações',
              onTap: () => Navigator.of(context).pop(),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.logout),
                label: const Text('Sair'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: FretColors.loginFooterLink),
      title: Text(
        label,
        style: const TextStyle(
          color: FretColors.neutral800,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
    );
  }
}
