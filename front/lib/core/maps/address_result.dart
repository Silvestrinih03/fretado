import 'package:latlong2/latlong.dart';

class AddressResult {
  final String label;
  final String baseAddress;
  final String? number;
  final String? street;
  final String? state;
  final String? source;
  final String? placeId;
  final LatLng point;

  const AddressResult({
    required this.label,
    required this.baseAddress,
    required this.point,
    this.number,
    this.street,
    this.state,
    this.source,
    this.placeId,
  });

  factory AddressResult.fromJson(Map<String, dynamic> json) => AddressResult(
    label: json['label'] as String,
    baseAddress:
        json['address_without_number'] as String? ?? json['label'] as String,
    number: json['house_number']?.toString(),
    street: json['street']?.toString(),
    state: json['state']?.toString(),
    source: json['source']?.toString(),
    placeId: json['place_id']?.toString(),
    point: LatLng(
      (json['latitude'] as num).toDouble(),
      (json['longitude'] as num).toDouble(),
    ),
  );
}

/// The base address returned by our geocoder excludes the house number.
String formatFreightAddress(String baseAddress, String? number) {
  final value = number?.trim();
  if (value == null || value.isEmpty) return baseAddress;
  final separator = baseAddress.indexOf(',');
  if (separator < 0) return '$baseAddress, $value';
  return '${baseAddress.substring(0, separator)}, $value${baseAddress.substring(separator)}';
}
