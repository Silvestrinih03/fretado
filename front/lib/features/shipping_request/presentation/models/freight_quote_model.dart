import 'package:latlong2/latlong.dart';

class FreightQuoteModel {
  final double distanceKm;
  final int estimatedTimeMinutes;
  final String vehicleTypeName;
  final String deliveryClassification;
  final double packageVolumeCm3;
  final double packageVolumeM3;
  final double fuelCost;
  final double operationalCost;
  final double driverMarginValue;
  final double appFeeValue;
  final double driverNetValue;
  final double totalPrice;
  final List<LatLng> routePoints;

  const FreightQuoteModel({
    required this.distanceKm,
    required this.estimatedTimeMinutes,
    required this.vehicleTypeName,
    required this.deliveryClassification,
    required this.packageVolumeCm3,
    required this.packageVolumeM3,
    required this.fuelCost,
    required this.operationalCost,
    required this.driverMarginValue,
    required this.appFeeValue,
    required this.driverNetValue,
    required this.totalPrice,
    required this.routePoints,
  });

  factory FreightQuoteModel.fromJson(Map<String, dynamic> json) {
    final pricing = json['pricing'] is Map<String, dynamic>
        ? json['pricing'] as Map<String, dynamic>
        : <String, dynamic>{};
    final route = json['route'] is Map<String, dynamic>
        ? json['route'] as Map<String, dynamic>
        : <String, dynamic>{};

    return FreightQuoteModel(
      distanceKm: _readDouble(json['distance_km']),
      estimatedTimeMinutes: _readInt(json['estimated_time_minutes']),
      vehicleTypeName: json['required_vehicle_type_name']?.toString() ?? '',
      deliveryClassification: json['delivery_classification']?.toString() ?? '',
      packageVolumeCm3: _readDouble(json['package_volume_cm3']),
      packageVolumeM3: _readDouble(json['package_volume_m3']),
      fuelCost: _readRequiredAmount(pricing['fuel_cost']),
      operationalCost: _readRequiredAmount(pricing['operational_cost']),
      driverMarginValue: _readRequiredAmount(pricing['driver_margin_value']),
      appFeeValue: _readRequiredAmount(pricing['app_fee_value']),
      driverNetValue: _readRequiredAmount(pricing['driver_net_value']),
      totalPrice: _readRequiredAmount(json['total_price']),
      routePoints: _readRoutePoints(route['geometry']),
    );
  }

  String get vehicleLabel {
    if (vehicleTypeName.isEmpty) {
      return 'Veiculo';
    }

    return '${vehicleTypeName[0].toUpperCase()}${vehicleTypeName.substring(1)}';
  }

  static double _readRequiredAmount(dynamic value) {
    final amount = double.tryParse(value?.toString() ?? '');
    if (amount == null || !amount.isFinite || amount < 0) {
      throw const FormatException('A cotacao retornou valores invalidos.');
    }
    return amount;
  }

  static double _readDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _readInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static List<LatLng> _readRoutePoints(dynamic geometry) {
    if (geometry is! List<dynamic>) {
      return <LatLng>[];
    }

    final points = <LatLng>[];

    for (final coordinate in geometry) {
      if (coordinate is! List<dynamic> || coordinate.length < 2) {
        continue;
      }

      final double? longitude = _tryReadDouble(coordinate[0]);
      final double? latitude = _tryReadDouble(coordinate[1]);

      if (latitude == null || longitude == null) {
        continue;
      }

      points.add(LatLng(latitude, longitude));
    }

    return points;
  }

  static double? _tryReadDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '');
  }
}
