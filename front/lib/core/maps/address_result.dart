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
  final bool pointApproximate;

  const AddressResult({
    required this.label,
    required this.baseAddress,
    required this.point,
    this.number,
    this.street,
    this.state,
    this.source,
    this.placeId,
    this.pointApproximate = false,
  });

  factory AddressResult.fromJson(Map<String, dynamic> json) => AddressResult(
    label: json['label'] as String,
    baseAddress:
        json['address_without_number'] as String? ?? json['label'] as String,
    number: json['house_number']?.toString(),
    street: json['street']?.toString(),
    state:
        normalizeFreightState(json['state']?.toString()) ??
        freightAddressState(
          json['address_without_number'] as String? ?? json['label'] as String,
        ),
    source: json['source']?.toString(),
    placeId: json['place_id']?.toString(),
    point: LatLng(
      (json['latitude'] as num).toDouble(),
      (json['longitude'] as num).toDouble(),
    ),
  );
}

String normalizeFreightAddressText(String text) {
  const accented = 'áàâãäéèêëíìîïóòôõöúùûüç';
  const plain = 'aaaaaeeeeiiiiooooouuuuc';
  final result = StringBuffer();
  for (final rune in text.toLowerCase().runes) {
    if (rune >= 0x0300 && rune <= 0x036f) continue;
    final character = String.fromCharCode(rune);
    final index = accented.indexOf(character);
    result.write(index < 0 ? character : plain[index]);
  }
  return result.toString().trim().replaceAll(RegExp(r'\s+'), ' ');
}

/// Accept only known Brazilian codes, never arbitrary substrings of an address.
String? normalizeFreightState(String? value) {
  const states = {
    'ac',
    'al',
    'ap',
    'am',
    'ba',
    'ce',
    'df',
    'es',
    'go',
    'ma',
    'mt',
    'ms',
    'mg',
    'pa',
    'pb',
    'pr',
    'pe',
    'pi',
    'rj',
    'rn',
    'rs',
    'ro',
    'rr',
    'sc',
    'sp',
    'se',
    'to',
  };
  var code = value?.trim().toLowerCase();
  if (code != null && code.startsWith('br-')) code = code.substring(3);
  return states.contains(code) ? code!.toUpperCase() : null;
}

/// The backend formats base addresses as street, [district], city, UF, [CEP].
/// Ambiguous/partial locations are not used to silently move a selected pin.
(String, String, String)? _streetAndLocality(String address) {
  final parts = address
      .split(',')
      .map(normalizeFreightAddressText)
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isNotEmpty && RegExp(r'^\d{5}-?\d{3}$').hasMatch(parts.last)) {
    parts.removeLast();
  }
  if (parts.length < 3) return null;
  final state = normalizeFreightState(parts.last);
  if (state == null) return null;
  return (parts.first, parts[parts.length - 2], state.toLowerCase());
}

/// Recover only the explicit UF component of a structured selected address.
String? freightAddressState(String address) =>
    _streetAndLocality(address)?.$3.toUpperCase();

bool sameFreightAddressIdentity(String first, String second) {
  if (normalizeFreightAddressText(first) ==
      normalizeFreightAddressText(second)) {
    return true;
  }
  final locality = _streetAndLocality(first);
  return locality != null && locality == _streetAndLocality(second);
}

bool matchesFreightAddressNumber(
  String baseAddress,
  String number,
  AddressResult candidate,
) {
  final expected = _streetAndLocality(baseAddress);
  final found = _streetAndLocality(candidate.baseAddress);
  return expected != null &&
      found == expected &&
      normalizeFreightAddressText(candidate.number ?? '').replaceAll(' ', '') ==
          normalizeFreightAddressText(number).replaceAll(' ', '');
}

/// The base address returned by our geocoder excludes the house number.
String formatFreightAddress(String baseAddress, String? number) {
  final value = number?.trim();
  if (value == null || value.isEmpty) return baseAddress;
  final separator = baseAddress.indexOf(',');
  if (separator < 0) return '$baseAddress, $value';
  return '${baseAddress.substring(0, separator)}, $value${baseAddress.substring(separator)}';
}
