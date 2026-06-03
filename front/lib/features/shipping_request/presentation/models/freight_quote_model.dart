class FreightQuoteModel {
  final double distanceKm;
  final int estimatedTimeMinutes;
  final String vehicleTypeName;
  final String deliveryClassification;
  final double packageVolumeCm3;
  final double packageVolumeM3;
  final double basePrice;
  final double distancePrice;
  final double durationPrice;
  final double totalPrice;

  const FreightQuoteModel({
    required this.distanceKm,
    required this.estimatedTimeMinutes,
    required this.vehicleTypeName,
    required this.deliveryClassification,
    required this.packageVolumeCm3,
    required this.packageVolumeM3,
    required this.basePrice,
    required this.distancePrice,
    required this.durationPrice,
    required this.totalPrice,
  });

  factory FreightQuoteModel.fromJson(Map<String, dynamic> json) {
    final pricing = json['pricing'] is Map<String, dynamic>
        ? json['pricing'] as Map<String, dynamic>
        : <String, dynamic>{};

    return FreightQuoteModel(
      distanceKm: _readDouble(json['distance_km']),
      estimatedTimeMinutes: _readInt(json['estimated_time_minutes']),
      vehicleTypeName: json['required_vehicle_type_name']?.toString() ?? '',
      deliveryClassification: json['delivery_classification']?.toString() ?? '',
      packageVolumeCm3: _readDouble(json['package_volume_cm3']),
      packageVolumeM3: _readDouble(json['package_volume_m3']),
      basePrice: _readDouble(pricing['base_price']),
      distancePrice: _readDouble(pricing['distance_price']),
      durationPrice: _readDouble(pricing['duration_price']),
      totalPrice: _readDouble(json['total_price']),
    );
  }

  String get deliveryClassificationLabel {
    return switch (deliveryClassification) {
      'SCHEDULED_FREIGHT' => 'Frete agendado',
      'IMMEDIATE_DELIVERY' => 'Entrega imediata',
      _ => 'Entrega',
    };
  }

  String get vehicleLabel {
    if (vehicleTypeName.isEmpty) {
      return 'Veiculo';
    }

    return '${vehicleTypeName[0].toUpperCase()}${vehicleTypeName.substring(1)}';
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
}
