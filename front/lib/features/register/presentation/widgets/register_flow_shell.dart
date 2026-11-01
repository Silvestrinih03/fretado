import 'package:flutter/material.dart';
import '../../../../app/design_system/design_system.dart';

class RegisterFlowShell extends StatelessWidget {
  final Widget child;
  final int stepIndex;
  final int totalSteps;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Color activeDotColor;
  const RegisterFlowShell({
    super.key,
    required this.child,
    required this.stepIndex,
    this.totalSteps = 3,
    this.showBackButton = false,
    this.onBackPressed,
    required this.activeDotColor,
  });

  @override
  Widget build(BuildContext context) => FretScreenTheme(
    child: Scaffold(
      backgroundColor: FretColors.screenBackground,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: FretColors.screenBorder),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 42,
                    child: showBackButton
                        ? IconButton(
                            tooltip: 'Voltar',
                            onPressed: onBackPressed,
                            padding: EdgeInsets.zero,
                            icon: const Icon(
                              Icons.chevron_left_rounded,
                              color: FretColors.screenDark,
                              size: 24,
                            ),
                          )
                        : null,
                  ),
                  const Expanded(
                    child: Text(
                      'Crie sua conta',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: FretColors.screenDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 42),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 10),
                child: child,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 18, 0, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(totalSteps, (index) {
                  final active = index == stepIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 4.5),
                    width: active ? 18 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: active ? activeDotColor : const Color(0xFFD3D1CC),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
