import 'package:flutter/material.dart';

import '../theme/fret_colors.dart';
import 'fret_surface.dart';

/// Applies the prototype's form styling only to the wrapped screen.
class FretScreenTheme extends StatelessWidget {
  final Widget child;
  const FretScreenTheme({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(13),
      borderSide: const BorderSide(color: FretColors.screenBorder),
    );
    return Theme(
      data: theme.copyWith(
        scaffoldBackgroundColor: FretColors.screenBackground,
        colorScheme: theme.colorScheme.copyWith(
          primary: FretColors.screenDark,
          onPrimary: FretColors.white,
          secondary: FretColors.screenGold,
          surface: FretColors.white,
          onSurface: FretColors.screenDark,
        ),
        textTheme: theme.textTheme
            .apply(
              bodyColor: FretColors.screenDark,
              displayColor: FretColors.screenDark,
            )
            .copyWith(
              titleMedium: theme.textTheme.titleMedium?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
              bodyMedium: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 13,
                color: FretColors.screenDark,
              ),
              bodyLarge: theme.textTheme.bodyLarge?.copyWith(
                fontSize: 13,
                color: FretColors.screenDark,
              ),
            ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: FretColors.screenBackground,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 15,
          ),
          hintStyle: const TextStyle(
            fontSize: 13,
            color: FretColors.screenMuted,
          ),
          labelStyle: const TextStyle(
            fontSize: 13,
            color: FretColors.screenMuted,
          ),
          border: border,
          enabledBorder: border,
          disabledBorder: border,
          focusedBorder: border.copyWith(
            borderSide: const BorderSide(color: FretColors.screenGold),
          ),
          errorMaxLines: 3,
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: FretColors.screenGold,
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: FretColors.screenDark),
        ),
      ),
      child: child,
    );
  }
}

class FretSecondaryAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  const FretSecondaryAppBar({super.key, required this.title});

  @override
  Size get preferredSize => const Size.fromHeight(62);

  @override
  Widget build(BuildContext context) => AppBar(
    backgroundColor: FretColors.screenBackground,
    foregroundColor: FretColors.screenDark,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    toolbarHeight: 62,
    leadingWidth: 66,
    titleSpacing: 0,
    leading: Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 10, 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: FretColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: FretColors.screenBorder),
        ),
        child: IconButton(
          tooltip: 'Voltar',
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.chevron_left_rounded, size: 22),
        ),
      ),
    ),
    title: Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
    ),
  );
}

class FretScreenCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  const FretScreenCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(15),
    this.radius = 18,
  });

  @override
  Widget build(BuildContext context) => FretSurfaceCard(
    radius: radius,
    padding: padding,
    border: Border.all(color: FretColors.screenBorder),
    boxShadow: const [
      BoxShadow(color: Color(0x0A000000), blurRadius: 14, offset: Offset(0, 3)),
    ],
    child: child,
  );
}

class FretScreenButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool gold;
  final bool loading;
  final IconData? icon;
  const FretScreenButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.gold = false,
    this.loading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) => FretPrimaryButton(
    label: label,
    onPressed: onPressed,
    loading: loading,
    trailingIcon: icon,
    height: 50,
    radius: 14,
    backgroundColor: gold ? FretColors.screenGold : FretColors.screenDark,
    foregroundColor: gold ? FretColors.screenDark : FretColors.white,
    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
  );
}
