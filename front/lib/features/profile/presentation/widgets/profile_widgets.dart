import 'package:flutter/material.dart';

import '../../../../app/design_system/design_system.dart';

class ProfileSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  const ProfileSurface({super.key, required this.child,
    this.padding = const EdgeInsets.all(16), this.radius = 16});

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: FretColors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: FretColors.screenBorder),
      boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6, offset: Offset(0, 1))],
    ),
    child: child,
  );
}

class ProfileHeader extends StatelessWidget {
  final String title;
  const ProfileHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
    child: Row(children: [
      ProfileSurface(
        radius: 12,
        padding: EdgeInsets.zero,
        child: IconButton(
          tooltip: 'Voltar',
          onPressed: () => Navigator.of(context).maybePop(),
          constraints: const BoxConstraints.tightFor(width: 36, height: 36),
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.chevron_left_rounded, size: 22, color: FretColors.screenDark),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(child: Text(title, style: const TextStyle(
        fontSize: 17, fontWeight: FontWeight.w700, color: FretColors.screenDark, letterSpacing: -0.3))),
    ]),
  );
}

class ProfileAvatar extends StatelessWidget {
  final String name;
  final double size;
  const ProfileAvatar({super.key, required this.name, this.size = 60});

  @override
  Widget build(BuildContext context) {
    final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    final initials = parts.isEmpty ? '?' :
      '${parts.first.characters.first}${parts.length > 1 ? parts.last.characters.first : ''}'.toUpperCase();
    return SizedBox(width: size, height: size, child: Stack(children: [
      Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle, color: FretColors.screenDark,
          border: Border.all(color: const Color(0x52C9A227), width: 2)),
        child: Text(initials, style: TextStyle(fontSize: size * 0.28,
          fontWeight: FontWeight.w700, color: FretColors.screenGold, letterSpacing: 1)),
      ),
      Positioned(right: 0, bottom: 0, child: Container(
        width: 24, height: 24,
        decoration: BoxDecoration(shape: BoxShape.circle, color: FretColors.screenGold,
          border: Border.all(color: FretColors.screenBackground, width: 2)),
        child: const Icon(Icons.photo_camera_outlined, size: 12, color: FretColors.screenDark),
      )),
    ]));
  }
}

class ProfileIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  const ProfileIcon({super.key, required this.icon, this.size = 44});

  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(color: FretColors.screenDark, borderRadius: BorderRadius.circular(13)),
    child: Icon(icon, size: 20, color: FretColors.screenGold),
  );
}

class ProfileSaveBar extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;
  const ProfileSaveBar({super.key, required this.label, required this.onPressed, this.isLoading = false});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
    decoration: const BoxDecoration(color: FretColors.screenBackground,
      border: Border(top: BorderSide(color: FretColors.screenBorder))),
    child: ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        elevation: 0, backgroundColor: FretColors.screenGold, foregroundColor: FretColors.screenDark,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.56),
      ),
      child: Text(isLoading ? 'Salvando...' : label),
    ),
  );
}

class ProfileField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool readOnly;
  final bool password;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final VoidCallback? onIconTap;

  const ProfileField({super.key, required this.label, required this.controller,
    this.keyboardType, this.readOnly = false, this.password = false,
    this.icon = Icons.edit_outlined, this.validator, this.textInputAction,
    this.onFieldSubmitted, this.onIconTap});

  @override
  State<ProfileField> createState() => _ProfileFieldState();
}

class _ProfileFieldState extends State<ProfileField> {
  final FocusNode _focusNode = FocusNode();
  bool _visible = false;

  @override
  void dispose() { _focusNode.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: FretColors.screenBorder));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(widget.label.toUpperCase(), style: const TextStyle(fontSize: 10,
        fontWeight: FontWeight.w600, color: FretColors.screenMuted, letterSpacing: 0.7)),
      const SizedBox(height: 6),
      TextFormField(
        controller: widget.controller, focusNode: _focusNode,
        keyboardType: widget.keyboardType, readOnly: widget.readOnly,
        obscureText: widget.password && !_visible,
        enableSuggestions: !widget.password, autocorrect: !widget.password,
        validator: widget.validator, textInputAction: widget.textInputAction,
        onFieldSubmitted: widget.onFieldSubmitted,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400,
          color: widget.readOnly ? const Color(0xFFAAAAAA) : FretColors.screenDark),
        decoration: InputDecoration(
          isDense: true, filled: true, fillColor: FretColors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: border, enabledBorder: border,
          focusedBorder: border.copyWith(borderSide: const BorderSide(color: FretColors.screenGold)),
          errorBorder: border.copyWith(borderSide: const BorderSide(color: FretColors.destructive600)),
          focusedErrorBorder: border.copyWith(borderSide: const BorderSide(color: FretColors.destructive600)),
          suffixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 44),
          suffixIcon: IconButton(
            tooltip: widget.password ? (_visible ? 'Ocultar senha' : 'Mostrar senha') : widget.label,
            onPressed: widget.readOnly ? null : widget.password
              ? () => setState(() => _visible = !_visible)
              : widget.onIconTap ?? () => _focusNode.requestFocus(),
            icon: Icon(widget.password
              ? (_visible ? Icons.visibility_off_outlined : Icons.visibility_outlined) : widget.icon,
              size: 16, color: widget.readOnly ? FretColors.screenGold : FretColors.screenMuted),
          ),
        ),
      ),
    ]);
  }
}
