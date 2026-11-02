import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;

/// The Android Navigation SDK reads this same asset for a consistent basemap.
class FretMapTheme {
  static const assetPath = 'assets/maps/fret_map_theme.json';
  static const styleUri = mb.MapboxStyles.MAPBOX_STREETS;
  static final Future<Map<String, dynamic>> _theme = _load();

  static Future<Map<String, dynamic>> _load() async {
    try {
      return jsonDecode(await rootBundle.loadString(assetPath))
          as Map<String, dynamic>;
    } catch (_) {
      return {'layers': <dynamic>[]};
    }
  }

  static Future<int> routeColor() async {
    final hex =
        (await _theme)['routeColor']?.toString().replaceFirst('#', '') ?? '';
    return RegExp(r'^[a-fA-F0-9]{6}$').hasMatch(hex)
        ? int.parse('ff$hex', radix: 16)
        : 0xFFA98618;
  }

  static Future<void> apply(mb.MapboxMap map) async {
    final theme = await _theme;
    for (final row in theme['layers'] as List) {
      final layer = Map<String, dynamic>.from(row as Map);
      try {
        final id = layer['id'] as String;
        if (await map.style.styleLayerExists(id)) {
          await map.style.setStyleLayerProperty(
            id,
            layer['property'] as String,
            layer['value'] as Object,
          );
        }
      } catch (_) {
        // A provider style may rename a layer; keep the usable Streets map.
      }
    }
  }

  static Future<void> configureOrnaments(mb.MapboxMap map) async {
    try {
      await map.scaleBar.updateSettings(mb.ScaleBarSettings(enabled: false));
      await map.logo.updateSettings(
        mb.LogoSettings(
          position: mb.OrnamentPosition.BOTTOM_LEFT,
          marginLeft: 8,
          marginBottom: 8,
        ),
      );
      await map.attribution.updateSettings(
        mb.AttributionSettings(
          position: mb.OrnamentPosition.BOTTOM_LEFT,
          marginLeft: 96,
          marginBottom: 8,
          iconColor: 0xFF77746C,
        ),
      );
    } catch (_) {
      // Disposing a preview may race plugin initialization. SDK defaults retain credits.
    }
  }
}
