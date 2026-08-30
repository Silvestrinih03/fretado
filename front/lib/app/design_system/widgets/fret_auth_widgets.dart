import 'package:flutter/material.dart';

import '../theme/fret_colors.dart';

class FretAuthCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const FretAuthCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(24, 24, 24, 22),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: FretColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
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
    this.assetPath = 'assets/images/logo_fretado.png',
    this.height = 104,
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
        fontSize: 22,
        height: 1.15,
        fontWeight: FontWeight.w700,
        color: FretColors.loginTitle,
        letterSpacing: 0,
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
        fontSize: 13,
        height: 1.35,
        fontWeight: FontWeight.w400,
        color: FretColors.loginSubtitle,
        letterSpacing: 0,
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
        fontSize: 13,
        height: 1.15,
        fontWeight: FontWeight.w700,
        color: FretColors.loginFieldLabel,
        letterSpacing: 0,
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
  final String? Function(String?)? validator;
  final AutovalidateMode? autovalidateMode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;

  const FretAuthTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.keyboardType,
    this.suffixIcon,
    this.obscureText = false,
    this.validator,
    this.autovalidateMode,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      autovalidateMode: autovalidateMode,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      style: const TextStyle(
        fontSize: 14,
        height: 1.2,
        fontWeight: FontWeight.w500,
        color: FretColors.loginInputText,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: FretColors.loginInputHint,
        ),
        filled: true,
        fillColor: FretColors.loginInputBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsetsDirectional.only(start: 14, end: 10),
          child: Icon(prefixIcon, size: 22, color: FretColors.loginInputIcon),
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
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: FretColors.destructive500,
            width: 1.2,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: FretColors.destructive600,
            width: 1.4,
          ),
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
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: FretColors.loginButtonEnd.withOpacity(0.22),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: SizedBox(
        height: 52,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: FretColors.white,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_rounded,
                color: FretColors.white,
                size: 22,
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
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
              fontSize: 14,
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
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
