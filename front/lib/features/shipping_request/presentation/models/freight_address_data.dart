import '../../../../core/maps/address_result.dart';

class FreightAddressData {
  final String? pickupState;
  final String pickupAddress;
  final String? pickupAddressNumber;
  final String? pickupAddressSource;
  final String? pickupAddressComplement;
  final String? pickupReferencePoint;
  final double pickupLatitude;
  final double pickupLongitude;
  final String? pickupPlaceId;
  final bool pickupPointApproximate;
  final String deliveryAddress;
  final String? deliveryAddressNumber;
  final String? deliveryAddressSource;
  final String? deliveryAddressComplement;
  final String? deliveryReferencePoint;
  final double deliveryLatitude;
  final double deliveryLongitude;
  final String? deliveryPlaceId;
  final bool deliveryPointApproximate;

  const FreightAddressData({
    this.pickupState,
    required this.pickupAddress,
    this.pickupAddressNumber,
    this.pickupAddressSource,
    this.pickupAddressComplement,
    this.pickupReferencePoint,
    required this.pickupLatitude,
    required this.pickupLongitude,
    this.pickupPlaceId,
    this.pickupPointApproximate = false,
    required this.deliveryAddress,
    this.deliveryAddressNumber,
    this.deliveryAddressSource,
    this.deliveryAddressComplement,
    this.deliveryReferencePoint,
    required this.deliveryLatitude,
    required this.deliveryLongitude,
    this.deliveryPlaceId,
    this.deliveryPointApproximate = false,
  });

  FreightAddressData copyWith({
    String? pickupState,
    String? pickupAddress,
    String? pickupAddressNumber,
    String? pickupAddressSource,
    String? pickupAddressComplement,
    String? pickupReferencePoint,
    double? pickupLatitude,
    double? pickupLongitude,
    String? pickupPlaceId,
    bool? pickupPointApproximate,
    String? deliveryAddress,
    String? deliveryAddressNumber,
    String? deliveryAddressSource,
    String? deliveryAddressComplement,
    String? deliveryReferencePoint,
    double? deliveryLatitude,
    double? deliveryLongitude,
    String? deliveryPlaceId,
    bool? deliveryPointApproximate,
  }) {
    return FreightAddressData(
      pickupState:
          pickupState ??
          ((pickupLatitude != null && pickupLatitude != this.pickupLatitude) ||
                  (pickupLongitude != null &&
                      pickupLongitude != this.pickupLongitude)
              ? null
              : this.pickupState),
      pickupAddress: pickupAddress ?? this.pickupAddress,
      pickupAddressNumber: pickupAddressNumber ?? this.pickupAddressNumber,
      pickupAddressSource: pickupAddressSource ?? this.pickupAddressSource,
      pickupAddressComplement:
          pickupAddressComplement ?? this.pickupAddressComplement,
      pickupReferencePoint: pickupReferencePoint ?? this.pickupReferencePoint,
      pickupLatitude: pickupLatitude ?? this.pickupLatitude,
      pickupLongitude: pickupLongitude ?? this.pickupLongitude,
      pickupPlaceId: pickupPlaceId ?? this.pickupPlaceId,
      pickupPointApproximate:
          pickupPointApproximate ?? this.pickupPointApproximate,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryAddressNumber:
          deliveryAddressNumber ?? this.deliveryAddressNumber,
      deliveryAddressSource:
          deliveryAddressSource ?? this.deliveryAddressSource,
      deliveryAddressComplement:
          deliveryAddressComplement ?? this.deliveryAddressComplement,
      deliveryReferencePoint:
          deliveryReferencePoint ?? this.deliveryReferencePoint,
      deliveryLatitude: deliveryLatitude ?? this.deliveryLatitude,
      deliveryLongitude: deliveryLongitude ?? this.deliveryLongitude,
      deliveryPlaceId: deliveryPlaceId ?? this.deliveryPlaceId,
      deliveryPointApproximate:
          deliveryPointApproximate ?? this.deliveryPointApproximate,
    );
  }

  String get originAddress =>
      formatFreightAddress(pickupAddress, pickupAddressNumber);

  String get destinationAddress =>
      formatFreightAddress(deliveryAddress, deliveryAddressNumber);

  Map<String, dynamic> toJson() {
    return toRideJson();
  }

  Map<String, dynamic> toRideJson() {
    final originState =
        normalizeFreightState(pickupState) ??
        freightAddressState(pickupAddress);
    return {
      if (originState != null) 'origin_state': originState,
      'origin_address': originAddress,
      'origin_address_number': pickupAddressNumber,
      'origin_address_source': pickupAddressSource,
      'origin_address_complement': _blankToNull(pickupAddressComplement),
      'origin_reference_point': _blankToNull(pickupReferencePoint),
      'origin_latitude': pickupLatitude,
      'origin_longitude': pickupLongitude,
      'destination_address': destinationAddress,
      'destination_address_number': deliveryAddressNumber,
      'destination_address_source': deliveryAddressSource,
      'destination_address_complement': _blankToNull(deliveryAddressComplement),
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

/// Keeps even partially entered text when returning to the route selection.
class FreightDetailsDraft {
  final FreightAddressData addressData;
  final Map<String, String> fields;
  final bool pickupWithoutNumber;
  final bool deliveryWithoutNumber;

  const FreightDetailsDraft({
    required this.addressData,
    required this.fields,
    required this.pickupWithoutNumber,
    required this.deliveryWithoutNumber,
  });
}
