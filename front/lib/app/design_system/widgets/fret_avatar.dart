import 'package:flutter/material.dart';

import '../theme/fret_colors.dart';

/// Read-only avatar shared by headers, ride participants and chat.
class FretAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? initials;
  final double size;
  final BorderRadius? borderRadius;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;
  final double? fontSize;
  final IconData fallbackIcon;
  final double? iconSize;

  const FretAvatar({
    super.key,
    this.imageUrl,
    this.initials,
    this.size = 40,
    this.borderRadius,
    this.backgroundColor = FretColors.screenDark,
    this.foregroundColor = FretColors.screenGold,
    this.borderColor,
    this.fontSize,
    this.fallbackIcon = Icons.person_outline_rounded,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(size / 2);
    final fallback = Center(
      child: initials == null || initials!.trim().isEmpty
          ? Icon(
              fallbackIcon,
              color: foregroundColor,
              size: iconSize ?? size * .55,
            )
          : Text(
              initials!,
              style: TextStyle(
                color: foregroundColor,
                fontSize: fontSize ?? size * .28,
                fontWeight: FontWeight.w900,
              ),
            ),
    );
    final url = imageUrl?.trim();
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: backgroundColor, borderRadius: radius),
      foregroundDecoration: borderColor == null
          ? null
          : BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: borderColor!),
            ),
      child: url == null || url.isEmpty
          ? fallback
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => fallback,
              loadingBuilder: (_, child, progress) =>
                  progress == null ? child : fallback,
            ),
    );
  }
}
