class VehicleCatalogOptionModel {
  final String value;
  final String label;
  final List<int> years;

  const VehicleCatalogOptionModel({
    required this.value,
    required this.label,
    this.years = const [],
  });

  factory VehicleCatalogOptionModel.fromJson(Map<String, dynamic> json) {
    return VehicleCatalogOptionModel(
      value: json['id'].toString(),
      label: json['name'] as String,
      years: List<int>.unmodifiable(
        (json['years'] as List? ?? const [])
            .map((year) => int.parse(year.toString())).toSet(),
      ),
    );
  }
}
