class VehicleFipeOptionModel {
  final String value;
  final String label;

  const VehicleFipeOptionModel({
    required this.value,
    required this.label,
  });

  factory VehicleFipeOptionModel.fromJson(
    Map<String, dynamic> json, {
    required String valueKey,
  }) {
    return VehicleFipeOptionModel(
      value: _readString(json[valueKey]) ?? '',
      label: _readString(json['name']) ?? '',
    );
  }

  static String? _readString(dynamic value) {
    if (value == null) {
      return null;
    }

    final String cleaned = value.toString().trim();
    return cleaned.isEmpty ? null : cleaned;
  }
}