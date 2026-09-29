import 'dart:math' as math;

class RideDetailModel {
  final int id;
  final int rideId;
  final String originAddress;
  final String? originAddressComplement;
  final String? originReferencePoint;
  final double originLatitude;
  final double originLongitude;
  final String destinationAddress;
  final String? destinationAddressComplement;
  final String? destinationReferencePoint;
  final double destinationLatitude;
  final double destinationLongitude;
  final double packageWidth;
  final double packageHeight;
  final double packageLength;
  final double packageWeight;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  RideDetailModel.fromJson(Map<String, dynamic> json)
    : id = _readInt(json['id']),
      rideId = _readInt(json['ride_id']),
      originAddress = _readString(json['origin_address']),
      originAddressComplement = _readNullableString(
        json['origin_address_complement'],
      ),
      originReferencePoint = _readNullableString(
        json['origin_reference_point'],
      ),
      originLatitude = _readDouble(json['origin_latitude']),
      originLongitude = _readDouble(json['origin_longitude']),
      destinationAddress = _readString(json['destination_address']),
      destinationAddressComplement = _readNullableString(
        json['destination_address_complement'],
      ),
      destinationReferencePoint = _readNullableString(
        json['destination_reference_point'],
      ),
      destinationLatitude = _readDouble(json['destination_latitude']),
      destinationLongitude = _readDouble(json['destination_longitude']),
      packageWidth = _readDouble(json['package_width']),
      packageHeight = _readDouble(json['package_height']),
      packageLength = _readDouble(json['package_length']),
      packageWeight = _readDouble(json['package_weight']),
      createdAt = _readDateTime(json['created_at']),
      updatedAt = _readDateTime(json['updated_at']);

  String get originLabel => _buildAddressLabel(
    address: originAddress,
    complement: originAddressComplement,
    referencePoint: originReferencePoint,
    latitude: originLatitude,
    longitude: originLongitude,
  );

  String get destinationLabel => _buildAddressLabel(
    address: destinationAddress,
    complement: destinationAddressComplement,
    referencePoint: destinationReferencePoint,
    latitude: destinationLatitude,
    longitude: destinationLongitude,
  );

  double get approximateDistanceKm => _distanceKm(
    originLatitude,
    originLongitude,
    destinationLatitude,
    destinationLongitude,
  );
}

class DriverRideModel {
  final int id;
  final int clientUserId;
  final int? driverUserId;
  final int requiredVehicleTypeId;
  final String? requiredVehicleTypeName;
  final RideDetailModel? details;
  final double totalPrice;
  final double? appFeeValue;
  final int statusId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final DateTime? cancelledAt;
  final String ridePurpose;
  final int? sourceRideId;

  DriverRideModel.fromJson(Map<String, dynamic> json)
    : id = _readInt(json['id']),
      clientUserId = _readInt(json['client_user_id']),
      driverUserId = _readNullableInt(json['driver_user_id']),
      requiredVehicleTypeId = _readInt(json['required_vehicle_type_id']),
      requiredVehicleTypeName = _readNullableString(
        json['required_vehicle_type_name'],
      ),
      details = json['details'] is Map
          ? RideDetailModel.fromJson(
              Map<String, dynamic>.from(json['details'] as Map),
            )
          : null,
      totalPrice = _readAmount(json['total_price']),
      appFeeValue = json['app_fee_value'] == null
          ? null
          : _readAmount(json['app_fee_value']),
      statusId = _readInt(json['status_id']),
      createdAt = _readDateTime(json['created_at']),
      updatedAt = _readDateTime(json['updated_at']),
      startedAt = _readDateTime(json['started_at']),
      finishedAt = _readDateTime(json['finished_at']),
      cancelledAt = _readDateTime(json['cancelled_at']),
      ridePurpose = _readNullableString(json['ride_purpose']) ?? 'standard',
      sourceRideId = _readNullableInt(json['source_ride_id']);

  bool get isActive => statusId >= 1 && statusId <= 4;
  bool get isCancellationReturn => ridePurpose == 'cancellation_return';
  String get vehicleCategoryLabel =>
      requiredVehicleTypeName ?? 'Categoria #$requiredVehicleTypeId';
  String get originLabel => details?.originLabel ?? 'Coleta não informada';
  String get destinationLabel =>
      details?.destinationLabel ?? 'Entrega não informada';
  double get packageWeight => details?.packageWeight ?? 0;
  double get driverNetValue => math.max(0.0, totalPrice - (appFeeValue ?? 0.0));

  String get statusLabel => switch (statusId) {
    1 => 'AGUARDANDO ACEITE',
    2 => 'AGUARDANDO INÍCIO',
    3 => 'A CAMINHO DA COLETA',
    4 => 'A CAMINHO DA ENTREGA',
    5 => 'FINALIZADA',
    6 => 'CANCELADA',
    7 => 'NÃO ATENDIDA',
    _ => 'STATUS $statusId',
  };
}

class RideOfferModel {
  final int id;
  final int rideId;
  final int driverUserId;
  final int vehicleId;
  final int statusId;
  final DateTime expiresAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  RideOfferModel.fromJson(Map<String, dynamic> json)
    : id = _readInt(json['id']),
      rideId = _readInt(json['ride_id']),
      driverUserId = _readInt(json['driver_user_id']),
      vehicleId = _readInt(json['vehicle_id']),
      statusId = _readInt(json['status_id']),
      expiresAt =
          _readDateTime(json['expires_at']) ??
          (throw const FormatException(
            'Oferta sem prazo de expiração válido.',
          )),
      createdAt =
          _readDateTime(json['created_at']) ??
          (throw const FormatException('Oferta sem data de criação válida.')),
      updatedAt = _readDateTime(json['updated_at']);

  bool get isPending => statusId == 1;
  bool get isExpired => statusId == 4;

  String get statusLabel => switch (statusId) {
    1 => 'PENDENTE',
    2 => 'ACEITA',
    3 => 'RECUSADA',
    4 => 'EXPIRADA',
    _ => 'STATUS $statusId',
  };
}

class DriverWalletModel {
  final int id;
  final int driverUserId;
  final double availableBalance;
  final DateTime? updatedAt;

  const DriverWalletModel({
    required this.id,
    required this.driverUserId,
    required this.availableBalance,
    this.updatedAt,
  });

  factory DriverWalletModel.fromJson(Map<String, dynamic> json) {
    return DriverWalletModel(
      id: _readInt(json['id']),
      driverUserId: _readInt(json['driver_user_id']),
      availableBalance: _readDouble(json['available_balance']),
      updatedAt: _readDateTime(json['updated_at']),
    );
  }
}

class WalletTransactionModel {
  final int id;
  final int driverUserId;
  final double value;
  final int statusId;
  final String pixKey;
  final DateTime? createdAt;

  const WalletTransactionModel({
    required this.id,
    required this.driverUserId,
    required this.value,
    required this.statusId,
    required this.pixKey,
    this.createdAt,
  });

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
      id: _readInt(json['id']),
      driverUserId: _readInt(json['driver_user_id']),
      value: _readDouble(json['value']),
      statusId: _readInt(json['status_id']),
      pixKey: json['pix_key']?.toString() ?? '',
      createdAt: _readDateTime(json['created_at']),
    );
  }

  String get statusLabel {
    return switch (statusId) {
      1 => 'PROCESSANDO',
      2 => 'FINALIZADO',
      3 => 'FALHA',
      4 => 'CANCELADO',
      _ => 'STATUS $statusId',
    };
  }
}

class DriverEarningModel {
  final int id;
  final int driverUserId;
  final int rideId;
  final double grossValue;
  final double appFeeValue;
  final double netValue;
  final DateTime? createdAt;
  final String earningType;

  const DriverEarningModel({
    required this.id,
    required this.driverUserId,
    required this.rideId,
    required this.grossValue,
    required this.appFeeValue,
    required this.netValue,
    this.createdAt,
    this.earningType = 'ride_completion',
  });

  factory DriverEarningModel.fromJson(Map<String, dynamic> json) {
    return DriverEarningModel(
      id: _readInt(json['id']),
      driverUserId: _readInt(json['driver_user_id']),
      rideId: _readInt(json['ride_id']),
      grossValue: _readDouble(json['gross_value']),
      appFeeValue: _readDouble(json['app_fee_value']),
      netValue: _readDouble(json['net_value']),
      createdAt: _readDateTime(json['created_at']),
      earningType:
          _readNullableString(json['earning_type']) ?? 'ride_completion',
    );
  }

  bool get isCancellationFee => earningType == 'cancellation_fee';
}

class WalletWithdrawRequestModel {
  final double value;
  final String pixKey;

  const WalletWithdrawRequestModel({required this.value, required this.pixKey});

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'value': value, 'pix_key': pixKey};
  }
}

int _readInt(dynamic value) => _readNullableInt(value) ?? 0;

int? _readNullableInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '');
}

double _readDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

class PendingRideOfferModel {
  final RideOfferModel offer;
  final DriverRideModel ride;
  final double distanceKm;
  final bool distanceIsApproximate;

  const PendingRideOfferModel({
    required this.offer,
    required this.ride,
    required this.distanceKm,
    this.distanceIsApproximate = false,
  });
}

String _readString(dynamic value) => _readNullableString(value) ?? '';

String? _readNullableString(dynamic value) {
  final cleaned = value?.toString().trim();
  if (cleaned == null || cleaned.isEmpty) {
    return null;
  }

  return cleaned;
}

String _buildAddressLabel({
  required String address,
  required String? complement,
  required String? referencePoint,
  required double latitude,
  required double longitude,
}) {
  final cleanedAddress = address.trim();
  if (cleanedAddress.isEmpty) {
    return '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
  }

  final parts = <String>[
    cleanedAddress,
    if (complement != null) 'Comp.: $complement',
    if (referencePoint != null) 'Ref.: $referencePoint',
  ];

  return parts.join(' - ');
}

DateTime? _readDateTime(dynamic value) {
  if (value is String && value.trim().isNotEmpty) {
    final text = value.trim();
    final hasZone = RegExp(
      r'(Z|[+-]\d{2}:?\d{2})$',
      caseSensitive: false,
    ).hasMatch(text);
    return DateTime.tryParse(hasZone ? text : '${text}Z')?.toUtc();
  }
  return null;
}

double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
  const earthRadiusKm = 6371.0;
  final firstLatitude = lat1 * math.pi / 180;
  final secondLatitude = lat2 * math.pi / 180;
  final latitudeDelta = (lat2 - lat1) * math.pi / 180;
  final longitudeDelta = (lon2 - lon1) * math.pi / 180;
  final value =
      math.sin(latitudeDelta / 2) * math.sin(latitudeDelta / 2) +
      math.cos(firstLatitude) *
          math.cos(secondLatitude) *
          math.sin(longitudeDelta / 2) *
          math.sin(longitudeDelta / 2);
  final normalized = value.clamp(0.0, 1.0);
  return earthRadiusKm *
      2 *
      math.atan2(math.sqrt(normalized), math.sqrt(1 - normalized));
}

double _readAmount(dynamic value) {
  final amount = double.tryParse(value?.toString() ?? '');
  if (amount == null || !amount.isFinite || amount < 0) {
    throw const FormatException('Valor da corrida inválido.');
  }
  return amount;
}
