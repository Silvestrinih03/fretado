import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../extensions/fret_text_styles_extension.dart';
import 'fret_colors.dart';

export 'fret_radius.dart';
export 'fret_colors.dart';
export 'fret_icons.dart';
export 'fret_spacements.dart';

abstract class FretTheme {
  static ThemeData light() {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: FretColors.brandGold,
      brightness: Brightness.light,
    ).copyWith(
      primary: FretColors.brandGraphite,
      secondary: FretColors.brandGold,
      surface: FretColors.appSurface,
      error: FretColors.destructive600,
    );

    final TextTheme textTheme = GoogleFonts.mavenProTextTheme().apply(
      bodyColor: FretColors.textPrimary,
      displayColor: FretColors.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      scaffoldBackgroundColor: FretColors.appBackground,
      colorScheme: colorScheme,
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[
        FretTextStylesExtension.get(),
      ],
      dividerTheme: const DividerThemeData(
        color: FretColors.appDivider,
        thickness: 1,
      ),
      iconTheme: const IconThemeData(color: FretColors.brandGraphite),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: FretColors.brandGraphite,
          foregroundColor: FretColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: FretColors.brandGraphite,
          side: const BorderSide(color: FretColors.appBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: FretColors.brandGoldDark,
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        errorMaxLines: 2,
        filled: true,
        fillColor: FretColors.appSurfaceSoft,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        hintStyle: const TextStyle(
          color: FretColors.neutral400,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        labelStyle: const TextStyle(
          color: FretColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        errorStyle: const TextStyle(
          color: FretColors.destructive600,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 1.25,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: FretColors.appBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: FretColors.appBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: FretColors.brandGold,
            width: 1.3,
          ),
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
