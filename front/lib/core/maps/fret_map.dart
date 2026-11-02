import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;

import '../../app/design_system/design_system.dart';

const mapboxPublicToken = String.fromEnvironment('MAPBOX_PUBLIC_TOKEN');

/// A small shared camera interface keeps Mapbox details out of the ride flow.
class FretMapController {
  mb.MapboxMap? _map;
  mb.CameraOptions? _pending;
  (List<LatLng>, EdgeInsets, double)? _pendingFit;
  int _version = 0;

  void move(LatLng point, double zoom) {
    _pendingFit = null;
    _version++;
    _pending = mb.CameraOptions(
      center: mb.Point(
        coordinates: mb.Position(point.longitude, point.latitude),
      ),
      zoom: zoom,
    );
    final map = _map;
    if (map != null) unawaited(_setCamera(map, _pending!));
  }

  void fit(
    List<LatLng> points, {
    EdgeInsets padding = const EdgeInsets.all(48),
    double maxZoom = 15,
  }) {
    if (points.isEmpty) return;
    _pending = null;
    _pendingFit = (List<LatLng>.of(points), padding, maxZoom);
    final version = ++_version;
    final map = _map;
    if (map != null) unawaited(_fit(map, _pendingFit!, version));
  }

  void _attach(mb.MapboxMap map) {
    _map = map;
    final fit = _pendingFit;
    if (fit != null) {
      unawaited(_fit(map, fit, _version));
    } else if (_pending != null) {
      unawaited(_setCamera(map, _pending!));
    }
  }

  Future<void> _setCamera(mb.MapboxMap map, mb.CameraOptions camera) async {
    try {
      if (_map == map) await map.setCamera(camera);
    } catch (_) {
      /* Screen disposed. */
    }
  }

  Future<void> _fit(
    mb.MapboxMap map,
    (List<LatLng>, EdgeInsets, double) fit,
    int version,
  ) async {
    try {
      final padding = fit.$2;
      final camera = await map.cameraForCoordinatesPadding(
        fit.$1
            .map(
              (point) => mb.Point(
                coordinates: mb.Position(point.longitude, point.latitude),
              ),
            )
            .toList(),
        mb.CameraOptions(
          padding: mb.MbxEdgeInsets(
            top: padding.top,
            left: padding.left,
            bottom: padding.bottom,
            right: padding.right,
          ),
        ),
        null,
        fit.$3,
        null,
      );
      if (_map == map && _version == version) await _setCamera(map, camera);
    } catch (_) {
      /* A map can be disposed while fitting the selected addresses. */
    }
  }

  void dispose() {
    _version++;
    _map = null;
  }
}

class FretMap extends StatefulWidget {
  final FretMapController? controller;
  final LatLng initialCenter;
  final LatLng? pickup;
  final LatLng? delivery;
  final LatLng? position;
  final List<LatLng> routePoints;
  final ValueChanged<LatLng>? onTap;
  final VoidCallback? onReady;

  const FretMap({
    super.key,
    this.controller,
    required this.initialCenter,
    this.pickup,
    this.delivery,
    this.position,
    this.routePoints = const [],
    this.onTap,
    this.onReady,
  });

  @override
  State<FretMap> createState() => _FretMapState();
}

class _FretMapState extends State<FretMap> {
  mb.MapboxMap? _map;
  bool _ready = false;
  bool _drawing = false;
  bool _redraw = false;

  @override
  void initState() {
    super.initState();
    if (mapboxPublicToken.startsWith('pk.')) {
      mb.MapboxOptions.setAccessToken(mapboxPublicToken);
    }
  }

  @override
  void didUpdateWidget(covariant FretMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    unawaited(_draw());
  }

  String _data(List<LatLng> points, {bool line = false}) => jsonEncode({
    'type': 'FeatureCollection',
    'features': points.isEmpty || (line && points.length < 2)
        ? []
        : [
            {
              'type': 'Feature',
              'properties': <String, dynamic>{},
              'geometry': {
                'type': line ? 'LineString' : 'Point',
                'coordinates': line
                    ? points.map((p) => [p.longitude, p.latitude]).toList()
                    : [points.first.longitude, points.first.latitude],
              },
            },
          ],
  });

  Future<void> _draw() async {
    if (!_ready || _map == null) return;
    if (_drawing) {
      _redraw = true;
      return;
    }
    _drawing = true;
    try {
      do {
        _redraw = false;
        final data = <String, String>{
          'freight-route': _data(widget.routePoints, line: true),
          'freight-pickup': _data([if (widget.pickup != null) widget.pickup!]),
          'freight-delivery': _data([
            if (widget.delivery != null) widget.delivery!,
          ]),
          'freight-position': _data([
            if (widget.position != null) widget.position!,
          ]),
        };
        for (final entry in data.entries) {
          if (!mounted) return;
          await _map!.style.setStyleSourceProperty(
            entry.key,
            'data',
            entry.value,
          );
        }
      } while (_redraw && mounted);
    } catch (_) {
      // Map/style disposal can race a response while leaving the screen.
    } finally {
      _drawing = false;
    }
  }

  Future<void> _styleLoaded() async {
    final map = _map;
    if (map == null || !mounted) return;
    for (final id in [
      'freight-route',
      'freight-pickup',
      'freight-delivery',
      'freight-position',
    ]) {
      await map.style.addSource(mb.GeoJsonSource(id: id, data: _data([])));
    }
    await map.style.addLayer(
      mb.LineLayer(
        id: 'route-border',
        sourceId: 'freight-route',
        lineColor: Colors.white.toARGB32(),
        lineWidth: 9,
      ),
    );
    await map.style.addLayer(
      mb.LineLayer(
        id: 'route-line',
        sourceId: 'freight-route',
        lineColor: FretColors.brandGoldDark.toARGB32(),
        lineWidth: 5,
      ),
    );
    for (final stop in [
      ('freight-pickup', 'Coleta', FretColors.brandGoldDark),
      ('freight-delivery', 'Entrega', FretColors.brandGraphite),
      ('freight-position', '', const Color(0xFF3976CC)),
    ]) {
      await map.style.addLayer(
        mb.CircleLayer(
          id: '${stop.$1}-dot',
          sourceId: stop.$1,
          circleRadius: 8,
          circleColor: stop.$3.toARGB32(),
          circleStrokeWidth: 3,
          circleStrokeColor: Colors.white.toARGB32(),
        ),
      );
      if (stop.$2.isNotEmpty) {
        await map.style.addLayer(
          mb.SymbolLayer(
            id: '${stop.$1}-label',
            sourceId: stop.$1,
            textField: stop.$2,
            textSize: 12,
            textOffset: [0, 1.8],
            textColor: stop.$3.toARGB32(),
            textHaloColor: Colors.white.toARGB32(),
            textHaloWidth: 2,
          ),
        );
      }
    }
    if (!mounted) return;
    _ready = true;
    await _draw();
    widget.onReady?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (!mapboxPublicToken.startsWith('pk.')) {
      return const ColoredBox(
        color: FretColors.appBackground,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Mapa temporariamente indisponível. Tente novamente mais tarde.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    return mb.MapWidget(
      key: const ValueKey('fretado-mapbox'),
      styleUri: mb.MapboxStyles.LIGHT,
      cameraOptions: mb.CameraOptions(
        center: mb.Point(
          coordinates: mb.Position(
            widget.initialCenter.longitude,
            widget.initialCenter.latitude,
          ),
        ),
        zoom: 12,
      ),
      onMapCreated: (map) {
        _map = map;
        widget.controller?._attach(map);
      },
      onStyleLoadedListener: (_) => unawaited(_styleLoaded()),
      onTapListener: (event) => widget.onTap?.call(
        LatLng(
          event.point.coordinates.lat.toDouble(),
          event.point.coordinates.lng.toDouble(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    widget.controller?._map = null;
    _map = null;
    super.dispose();
  }
}
