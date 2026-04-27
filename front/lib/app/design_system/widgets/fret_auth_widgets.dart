import 'package:flutter/material.dart';

import '../theme/fret_colors.dart';

class FretAuthCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const FretAuthCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(32, 34, 32, 28),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: FretColors.white,
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: child,
    );
  }
}

class FretAuthBrandHeader extends StatelessWidget {
  final String assetPath;
  final double height;

  const FretAuthBrandHeader({
    super.key,
    this.assetPath = 'assets/images/logo.png',
    this.height = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Image.asset(
        assetPath,
        height: height,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}

class FretAuthHeading extends StatelessWidget {
  final String text;

  const FretAuthHeading({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 40,
        height: 1.05,
        fontWeight: FontWeight.w600,
        color: FretColors.loginTitle,
        letterSpacing: -1.1,
      ),
    );
  }
}

class FretAuthSubtitle extends StatelessWidget {
  final String text;

  const FretAuthSubtitle({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 22,
        height: 1.3,
        fontWeight: FontWeight.w400,
        color: FretColors.loginSubtitle,
        letterSpacing: -0.3,
      ),
    );
  }
}

class FretAuthFieldLabel extends StatelessWidget {
  final String text;

  const FretAuthFieldLabel({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 22,
        height: 1.15,
        fontWeight: FontWeight.w600,
        color: FretColors.loginFieldLabel,
        letterSpacing: -0.2,
      ),
    );
  }
}

class FretAuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final IconData prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;

  const FretAuthTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.keyboardType,
    this.suffixIcon,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(
        fontSize: 18,
        height: 1.2,
        fontWeight: FontWeight.w500,
        color: FretColors.loginInputText,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: FretColors.loginInputHint,
        ),
        filled: true,
        fillColor: FretColors.loginInputBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        prefixIcon: Padding(
          padding: const EdgeInsetsDirectional.only(start: 18, end: 14),
          child: Icon(
            prefixIcon,
            size: 28,
            color: FretColors.loginInputIcon,
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: suffixIcon == null
            ? null
            : Padding(
                padding: const EdgeInsetsDirectional.only(end: 12),
                child: suffixIcon,
              ),
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class FretPrimaryGradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData trailingIcon;

  const FretPrimaryGradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.trailingIcon = Icons.arrow_forward_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [FretColors.loginButtonStart, FretColors.loginButtonEnd],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: FretColors.loginButtonEnd.withOpacity(0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: SizedBox(
        height: 72,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: FretColors.white,
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.arrow_forward_rounded,
                color: FretColors.white,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FretAuthForgotPasswordLink extends StatelessWidget {
  final VoidCallback onPressed;

  const FretAuthForgotPasswordLink({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: FretColors.loginForgotPassword,
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: const Text(
          'Esqueci minha senha',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class FretAuthFooterPrompt extends StatelessWidget {
  final VoidCallback onSignUpPressed;

  const FretAuthFooterPrompt({super.key, required this.onSignUpPressed});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 6,
        children: [
          const Text(
            'Não possui uma conta?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: FretColors.loginFooterText,
            ),
          ),
          TextButton(
            onPressed: onSignUpPressed,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: FretColors.loginFooterLink,
            ),
            child: const Text(
              'Cadastre-se',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}