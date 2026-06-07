class FreightAddressData {
  final String pickupAddress;
  final String? pickupAddressComplement;
  final String? pickupReferencePoint;
  final double pickupLatitude;
  final double pickupLongitude;
  final String? pickupPlaceId;
  final String deliveryAddress;
  final String? deliveryAddressComplement;
  final String? deliveryReferencePoint;
  final double deliveryLatitude;
  final double deliveryLongitude;
  final String? deliveryPlaceId;

  const FreightAddressData({
    required this.pickupAddress,
    this.pickupAddressComplement,
    this.pickupReferencePoint,
    required this.pickupLatitude,
    required this.pickupLongitude,
    this.pickupPlaceId,
    required this.deliveryAddress,
    this.deliveryAddressComplement,
    this.deliveryReferencePoint,
    required this.deliveryLatitude,
    required this.deliveryLongitude,
    this.deliveryPlaceId,
  });

  FreightAddressData copyWith({
    String? pickupAddress,
    String? pickupAddressComplement,
    String? pickupReferencePoint,
    double? pickupLatitude,
    double? pickupLongitude,
    String? pickupPlaceId,
    String? deliveryAddress,
    String? deliveryAddressComplement,
    String? deliveryReferencePoint,
    double? deliveryLatitude,
    double? deliveryLongitude,
    String? deliveryPlaceId,
  }) {
    return FreightAddressData(
      pickupAddress: pickupAddress ?? this.pickupAddress,
      pickupAddressComplement:
          pickupAddressComplement ?? this.pickupAddressComplement,
      pickupReferencePoint: pickupReferencePoint ?? this.pickupReferencePoint,
      pickupLatitude: pickupLatitude ?? this.pickupLatitude,
      pickupLongitude: pickupLongitude ?? this.pickupLongitude,
      pickupPlaceId: pickupPlaceId ?? this.pickupPlaceId,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryAddressComplement:
          deliveryAddressComplement ?? this.deliveryAddressComplement,
      deliveryReferencePoint:
          deliveryReferencePoint ?? this.deliveryReferencePoint,
      deliveryLatitude: deliveryLatitude ?? this.deliveryLatitude,
      deliveryLongitude: deliveryLongitude ?? this.deliveryLongitude,
      deliveryPlaceId: deliveryPlaceId ?? this.deliveryPlaceId,
    );
  }

  String get originAddress => pickupAddress;

  String get destinationAddress => deliveryAddress;

  Map<String, dynamic> toJson() {
    return toRideJson();
  }

  Map<String, dynamic> toRideJson() {
    return {
      'origin_address': pickupAddress,
      'origin_address_complement': _blankToNull(pickupAddressComplement),
      'origin_reference_point': _blankToNull(pickupReferencePoint),
      'origin_latitude': pickupLatitude,
      'origin_longitude': pickupLongitude,
      'destination_address': deliveryAddress,
      'destination_address_complement':
          _blankToNull(deliveryAddressComplement),
      'destination_reference_point': _blankToNull(deliveryReferencePoint),
      'destination_latitude': deliveryLatitude,
      'destination_longitude': deliveryLongitude,
    };
  }
}

String? _blankToNull(String? value) {
  final cleaned = value?.trim();
  if (cleaned == null || cleaned.isEmpty) {
    return null;
  }

  return cleaned;
}
