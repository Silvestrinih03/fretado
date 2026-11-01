class DriverEligibilityModel {
  final bool canGoOnline;
  final List<String> pendingRequirements;
  final bool hasActiveRide;
  final String message;

  const DriverEligibilityModel({
    required this.canGoOnline,
    required this.pendingRequirements,
    required this.hasActiveRide,
    required this.message,
  });

  factory DriverEligibilityModel.fromJson(Map<String, dynamic> json) =>
      DriverEligibilityModel(
        canGoOnline: json['can_go_online'] == true,
        pendingRequirements: List<String>.unmodifiable(
          json['pending_requirements'] is List
              ? (json['pending_requirements'] as List).map(
                  (item) => item.toString(),
                )
              : <String>[],
        ),
        hasActiveRide: json['has_active_ride'] == true,
        message: (json['message']?.toString() ?? '').trim(),
      );

  bool get needsVehicle =>
      pendingRequirements.contains('missing_active_vehicle');
  bool get needsLicense =>
      pendingRequirements.contains('missing_driver_license') || licenseExpired;
  bool get licenseExpired =>
      pendingRequirements.contains('expired_driver_license');
}
