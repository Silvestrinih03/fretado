class FreightAddressData {
  final String pickupAddress;
  final double pickupLatitude;
  final double pickupLongitude;
  final String? pickupPlaceId;
  final String deliveryAddress;
  final double deliveryLatitude;
  final double deliveryLongitude;
  final String? deliveryPlaceId;

  const FreightAddressData({
    required this.pickupAddress,
    required this.pickupLatitude,
    required this.pickupLongitude,
    this.pickupPlaceId,
    required this.deliveryAddress,
    required this.deliveryLatitude,
    required this.deliveryLongitude,
    this.deliveryPlaceId,
  });

  Map<String, dynamic> toJson() {
    return {
      'pickup_address': pickupAddress,
      'pickup_latitude': pickupLatitude,
      'pickup_longitude': pickupLongitude,
      'pickup_place_id': pickupPlaceId,
      'delivery_address': deliveryAddress,
      'delivery_latitude': deliveryLatitude,
      'delivery_longitude': deliveryLongitude,
      'delivery_place_id': deliveryPlaceId,
    };
  }
}
