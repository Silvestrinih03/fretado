class DriverRideModel {
  final int id;
  final int clientUserId;
  final int? driverUserId;
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
  final double totalPrice;
  final int statusId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final DateTime? cancelledAt;

  const DriverRideModel({
    required this.id,
    required this.clientUserId,
    required this.driverUserId,
    required this.originAddress,
    required this.originAddressComplement,
    required this.originReferencePoint,
    required this.originLatitude,
    required this.originLongitude,
    required this.destinationAddress,
    required this.destinationAddressComplement,
    required this.destinationReferencePoint,
    required this.destinationLatitude,
    required this.destinationLongitude,
    required this.packageWidth,
    required this.packageHeight,
    required this.packageLength,
    required this.packageWeight,
    required this.totalPrice,
    required this.statusId,
    this.createdAt,
    this.updatedAt,
    this.startedAt,
    this.finishedAt,
    this.cancelledAt,
  });

  factory DriverRideModel.fromJson(Map<String, dynamic> json) {
    return DriverRideModel(
      id: _readInt(json['id']),
      clientUserId: _readInt(json['client_user_id']),
      driverUserId: _readNullableInt(json['driver_user_id']),
      originAddress: _readString(json['origin_address']),
      originAddressComplement:
          _readNullableString(json['origin_address_complement']),
      originReferencePoint: _readNullableString(json['origin_reference_point']),
      originLatitude: _readDouble(json['origin_latitude']),
      originLongitude: _readDouble(json['origin_longitude']),
      destinationAddress: _readString(json['destination_address']),
      destinationAddressComplement:
          _readNullableString(json['destination_address_complement']),
      destinationReferencePoint:
          _readNullableString(json['destination_reference_point']),
      destinationLatitude: _readDouble(json['destination_latitude']),
      destinationLongitude: _readDouble(json['destination_longitude']),
      packageWidth: _readDouble(json['package_width']),
      packageHeight: _readDouble(json['package_height']),
      packageLength: _readDouble(json['package_length']),
      packageWeight: _readDouble(json['package_weight']),
      totalPrice: _readDouble(json['total_price']),
      statusId: _readInt(json['status_id']),
      createdAt: _readDateTime(json['created_at']),
      updatedAt: _readDateTime(json['updated_at']),
      startedAt: _readDateTime(json['started_at']),
      finishedAt: _readDateTime(json['finished_at']),
      cancelledAt: _readDateTime(json['cancelled_at']),
    );
  }

  String get statusLabel {
    return switch (statusId) {
      1 => 'AGUARDANDO ACEITE',
      2 => 'AGUARDANDO INICIO',
      3 => 'A CAMINHO DA COLETA',
      4 => 'A CAMINHO DA ENTREGA',
      5 => 'FINALIZADA',
      6 => 'CANCELADA',
      _ => 'STATUS $statusId',
    };
  }

  String get originLabel {
    return _buildAddressLabel(
      address: originAddress,
      complement: originAddressComplement,
      referencePoint: originReferencePoint,
      latitude: originLatitude,
      longitude: originLongitude,
    );
  }

  String get destinationLabel {
    return _buildAddressLabel(
      address: destinationAddress,
      complement: destinationAddressComplement,
      referencePoint: destinationReferencePoint,
      latitude: destinationLatitude,
      longitude: destinationLongitude,
    );
  }
}

class RideOfferModel {
  final int id;
  final int rideId;
  final int driverUserId;
  final int statusId;
  final DateTime? expiresAt;
  final int attemptOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const RideOfferModel({
    required this.id,
    required this.rideId,
    required this.driverUserId,
    required this.statusId,
    required this.expiresAt,
    required this.attemptOrder,
    this.createdAt,
    this.updatedAt,
  });

  factory RideOfferModel.fromJson(Map<String, dynamic> json) {
    return RideOfferModel(
      id: _readInt(json['id']),
      rideId: _readInt(json['ride_id']),
      driverUserId: _readInt(json['driver_user_id']),
      statusId: _readInt(json['status_id']),
      expiresAt: _readDateTime(json['expires_at']),
      attemptOrder: _readInt(json['attempt_order']),
      createdAt: _readDateTime(json['created_at']),
      updatedAt: _readDateTime(json['updated_at']),
    );
  }

  bool get isPending => statusId == 1;

  String get statusLabel {
    return switch (statusId) {
      1 => 'PENDENTE',
      2 => 'ACEITA',
      3 => 'RECUSADA',
      4 => 'EXPIRADA',
      _ => 'STATUS $statusId',
    };
  }
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

  const DriverEarningModel({
    required this.id,
    required this.driverUserId,
    required this.rideId,
    required this.grossValue,
    required this.appFeeValue,
    required this.netValue,
    this.createdAt,
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
    );
  }
}

class WalletWithdrawRequestModel {
  final double value;
  final String pixKey;

  const WalletWithdrawRequestModel({
    required this.value,
    required this.pixKey,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'value': value,
      'pix_key': pixKey,
    };
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
    return DateTime.tryParse(value);
  }
  return null;
}
