class RideCancellationPreviewModel {
  final int rideId;
  final int rideStatusId;
  final bool allowed;
  final String? flow;
  final bool reasonRequired;
  final bool returnDestinationRequired;
  final double feePercentage;
  final double cancellationCharge;
  final double refundAmount;

  const RideCancellationPreviewModel({
    required this.rideId,
    required this.rideStatusId,
    required this.allowed,
    required this.flow,
    required this.reasonRequired,
    required this.returnDestinationRequired,
    required this.feePercentage,
    required this.cancellationCharge,
    required this.refundAmount,
  });

  factory RideCancellationPreviewModel.fromJson(Map<String, dynamic> json) =>
      RideCancellationPreviewModel(
        rideId: _int(json['ride_id']),
        rideStatusId: _int(json['ride_status_id']),
        allowed: json['allowed'] == true,
        flow: json['flow']?.toString(),
        reasonRequired: json['reason_required'] == true,
        returnDestinationRequired: json['return_destination_required'] == true,
        feePercentage: _double(json['cancellation_fee_percentage']),
        cancellationCharge: _double(json['cancellation_charge']),
        refundAmount: _double(json['refund_amount']),
      );
}

class RideCancellationModel {
  final int id;
  final int rideId;
  final int previousRideStatusId;
  final String status;
  final String phase;
  final String? reason;
  final String? returnDestinationType;
  final String? returnAddress;
  final String? returnAddressComplement;
  final String? returnReferencePoint;
  final String? originalDestinationAddress;
  final String? originalDestinationAddressComplement;
  final String? originalDestinationReferencePoint;
  final double? returnLatitude;
  final double? returnLongitude;
  final double? traveledDistanceKm;
  final double? returnDistanceKm;
  final double cancellationCharge;
  final double driverCompensation;
  final double refundAmount;
  final double additionalChargeAmount;
  final String financialStatus;
  final int? returnRideId;
  final DateTime? quotePreparedAt;
  final DateTime? returnStartedAt;
  final DateTime? returnCompletedAt;
  final String? distanceCalculationSource;
  final DateTime? driverConfirmedAt;
  final DateTime? driverAcknowledgedAt;
  final DateTime? resolvedAt;
  final DateTime? updatedAt;

  const RideCancellationModel({
    required this.id,
    required this.rideId,
    required this.previousRideStatusId,
    required this.status,
    required this.phase,
    required this.reason,
    required this.returnDestinationType,
    required this.returnAddress,
    required this.returnAddressComplement,
    required this.returnReferencePoint,
    required this.originalDestinationAddress,
    required this.originalDestinationAddressComplement,
    required this.originalDestinationReferencePoint,
    required this.returnLatitude,
    required this.returnLongitude,
    required this.traveledDistanceKm,
    required this.returnDistanceKm,
    required this.cancellationCharge,
    required this.driverCompensation,
    required this.refundAmount,
    required this.additionalChargeAmount,
    required this.financialStatus,
    required this.returnRideId,
    required this.quotePreparedAt,
    required this.returnStartedAt,
    required this.returnCompletedAt,
    required this.distanceCalculationSource,
    required this.driverConfirmedAt,
    required this.driverAcknowledgedAt,
    required this.resolvedAt,
    required this.updatedAt,
  });

  factory RideCancellationModel.fromJson(Map<String, dynamic> json) =>
      RideCancellationModel(
        id: _int(json['id']),
        rideId: _int(json['ride_id']),
        previousRideStatusId: _int(json['previous_ride_status_id']),
        status: json['status']?.toString() ?? '',
        phase: json['phase']?.toString() ?? json['status']?.toString() ?? '',
        reason: json['reason']?.toString(),
        returnDestinationType: json['return_destination_type']?.toString(),
        returnAddress: json['return_address']?.toString(),
        returnAddressComplement: json['return_address_complement']?.toString(),
        returnReferencePoint: json['return_reference_point']?.toString(),
        originalDestinationAddress: json['original_destination_address']
            ?.toString(),
        originalDestinationAddressComplement:
            json['original_destination_address_complement']?.toString(),
        originalDestinationReferencePoint:
            json['original_destination_reference_point']?.toString(),
        returnLatitude: _nullableDouble(json['return_latitude']),
        returnLongitude: _nullableDouble(json['return_longitude']),
        traveledDistanceKm: _nullableDouble(json['traveled_distance_km']),
        returnDistanceKm: _nullableDouble(json['return_distance_km']),
        cancellationCharge: _double(json['cancellation_charge']),
        driverCompensation: _double(json['driver_compensation']),
        refundAmount: _double(json['refund_amount']),
        additionalChargeAmount: _double(json['additional_charge_amount']),
        financialStatus: json['financial_status']?.toString() ?? '',
        returnRideId: _nullableInt(json['return_ride_id']),
        quotePreparedAt: _date(json['quote_prepared_at']),
        returnStartedAt: _date(json['return_started_at']),
        returnCompletedAt: _date(json['return_completed_at']),
        distanceCalculationSource: json['distance_calculation_source']
            ?.toString(),
        driverConfirmedAt: _date(json['driver_confirmed_at']),
        driverAcknowledgedAt: _date(json['driver_acknowledged_at']),
        resolvedAt: _date(json['resolved_at']),
        updatedAt: _date(json['updated_at']),
      );

  bool get isAwaitingDriver => status == 'awaiting_driver_confirmation';
  bool get isAwaitingClient => status == 'awaiting_client_confirmation';
  bool get isCompleted => status == 'completed';
  bool get isDeclined => status == 'declined_by_client';
}

class CancellationAddressModel {
  final String label;
  final double latitude;
  final double longitude;

  const CancellationAddressModel({
    required this.label,
    required this.latitude,
    required this.longitude,
  });

  factory CancellationAddressModel.fromJson(Map<String, dynamic> json) =>
      CancellationAddressModel(
        label: json['label']?.toString() ?? '',
        latitude: _double(json['latitude']),
        longitude: _double(json['longitude']),
      );
}

class RideCancellationRequestModel {
  final String? reason;
  final String? returnDestinationType;
  final CancellationAddressModel? returnAddress;

  const RideCancellationRequestModel({
    this.reason,
    this.returnDestinationType,
    this.returnAddress,
  });

  Map<String, dynamic> toJson() => {
    if (reason != null) 'reason': reason,
    if (returnDestinationType != null)
      'return_destination_type': returnDestinationType,
    if (returnAddress != null) ...{
      'return_address': returnAddress!.label,
      'return_latitude': returnAddress!.latitude,
      'return_longitude': returnAddress!.longitude,
    },
  };
}

int _int(dynamic value) => _nullableInt(value) ?? 0;
int? _nullableInt(dynamic value) =>
    value is num ? value.toInt() : int.tryParse(value?.toString() ?? '');
double _double(dynamic value) => value is num
    ? value.toDouble()
    : double.tryParse(value?.toString() ?? '') ?? 0;
double? _nullableDouble(dynamic value) => value == null
    ? null
    : value is num
    ? value.toDouble()
    : double.tryParse(value.toString());
DateTime? _date(dynamic value) =>
    value is String ? DateTime.tryParse(value)?.toLocal() : null;
