import 'package:flutter/material.dart';

import '../../../../app/design_system/design_system.dart';

class RegisterSectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color titleColor;

  const RegisterSectionTitle({
    super.key,
    required this.title,
    required this.subtitle,
    this.titleColor = FretColors.neutral900,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 40,
            height: 1.1,
            fontWeight: FontWeight.w700,
            color: titleColor,
            letterSpacing: -1.2,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 22,
            height: 1.35,
            color: FretColors.neutral700,
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
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: FretColors.neutral700,
        letterSpacing: 1.2,
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

  const RegisterInputField({
    super.key,
    required this.controller,
    required this.hintText,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontSize: 20,
        color: FretColors.neutral700,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          fontSize: 20,
          color: FretColors.neutral500,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: FretColors.neutral200,
        contentPadding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
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
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      decoration: BoxDecoration(
        color: FretColors.neutral100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FretColors.neutral200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 20,
                height: 1.32,
                color: FretColors.neutral700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
