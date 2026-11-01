import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/design_system/design_system.dart';

class RegisterSectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color titleColor;

  const RegisterSectionTitle({
    super.key,
    required this.title,
    required this.subtitle,
    this.titleColor = FretColors.screenDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 25,
            height: 1.16,
            fontWeight: FontWeight.w800,
            color: titleColor,
            letterSpacing: .3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            height: 1.5,
            color: FretColors.screenMuted,
          ),
        ),
      ],
    );
  }
}

class RegisterInputLabel extends StatelessWidget {
  final String text;

  const RegisterInputLabel({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: FretColors.screenDark,
        letterSpacing: 0,
      ),
    );
  }
}

class RegisterInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final AutovalidateMode? autovalidateMode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final TextCapitalization textCapitalization;

  const RegisterInputField({
    super.key,
    required this.controller,
    required this.hintText,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.autovalidateMode,
    this.textInputAction,
    this.onFieldSubmitted,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      autovalidateMode: autovalidateMode,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      textCapitalization: textCapitalization,
      style: const TextStyle(
        fontSize: 13,
        color: FretColors.screenDark,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          fontSize: 13,
          color: FretColors.screenMuted,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: FretColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: FretColors.screenBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: FretColors.screenBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: FretColors.screenGold),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(
            color: FretColors.destructive500,
            width: 1.2,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(
            color: FretColors.destructive600,
            width: 1.4,
          ),
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }
}

class RegisterInfoBanner extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;

  const RegisterInfoBanner({
    super.key,
    required this.icon,
    required this.text,
    this.iconColor = FretColors.loginFooterLink,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: FretColors.neutral100,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: FretColors.neutral200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.32,
                color: FretColors.screenDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
