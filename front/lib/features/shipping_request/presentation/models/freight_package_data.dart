class FreightPackageData {
  final double widthCm;
  final double heightCm;
  final double lengthCm;
  final double weightKg;

  const FreightPackageData({
    required this.widthCm,
    required this.heightCm,
    required this.lengthCm,
    required this.weightKg,
  });

  double get volumeCm3 => widthCm * heightCm * lengthCm;

  double get volumeM3 => volumeCm3 / 1000000;

  Map<String, dynamic> toQuoteJson() {
    return {
      'package_width': widthCm.toStringAsFixed(2),
      'package_height': heightCm.toStringAsFixed(2),
      'package_length': lengthCm.toStringAsFixed(2),
      'package_weight': weightKg.toStringAsFixed(2),
    };
  }
}
