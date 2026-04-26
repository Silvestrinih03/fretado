import 'package:flutter/material.dart';

import 'fret_text_styles_extension.dart';

extension ContextThemeExtension on BuildContext {
  FretTextStylesExtension get texts =>
      Theme.of(this).extension<FretTextStylesExtension>() ??
      FretTextStylesExtension.get();
  ColorScheme get colors => Theme.of(this).colorScheme;
}