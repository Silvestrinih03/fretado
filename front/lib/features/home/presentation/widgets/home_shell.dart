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
      endDrawer: const HomeDrawer(),
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
              return IconButton(
                onPressed: () => Scaffold.of(context).openEndDrawer(),
                icon: Container(
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
              );
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }
}
