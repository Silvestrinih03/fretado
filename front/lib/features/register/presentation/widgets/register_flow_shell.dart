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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FretColors.neutral100,
      body: SafeArea(
        child: Column(
          children: [
            _RegisterHeader(
              showBackButton: showBackButton,
              onBackPressed: onBackPressed,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                child: child,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: _StepDots(
                currentStep: stepIndex,
                totalSteps: totalSteps,
                activeColor: activeDotColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegisterHeader extends StatelessWidget {
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const _RegisterHeader({
    required this.showBackButton,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: FretColors.neutral200),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: showBackButton
                ? IconButton(
                    onPressed: onBackPressed,
                    splashRadius: 18,
                    icon: const Icon(
                      Icons.arrow_back,
                      color: FretColors.loginFooterLink,
                      size: 22,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Crie sua conta',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: FretColors.loginFooterLink,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _StepDots extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final Color activeColor;

  const _StepDots({
    required this.currentStep,
    required this.totalSteps,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps, (index) {
        final bool isActive = index == currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: isActive ? activeColor : FretColors.neutral300,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}
