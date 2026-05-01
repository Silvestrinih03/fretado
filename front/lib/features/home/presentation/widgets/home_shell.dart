import 'package:flutter/material.dart';

import '../../../../app/design_system/design_system.dart';
import 'home_drawer.dart';

class HomeShell extends StatelessWidget {
  final Widget content;

  const HomeShell({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F7),
      drawer: const HomeDrawer(),
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
