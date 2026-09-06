class RegisterVehicleModel {
  final int? id;
  final int userId;
  final int vehicleTypeId;
  final int versionId;
  final int year;
  final String? color;
  final String plate;
  final bool status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const RegisterVehicleModel({
    this.id,
    required this.userId,
    required this.vehicleTypeId,
    required this.versionId,
    required this.year,
    this.color,
    required this.plate,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory RegisterVehicleModel.fromJson(Map<String, dynamic> json) {
    return RegisterVehicleModel(
      id: _readInt(json['id']),
      userId: _readInt(json['user_id']) ?? 0,
      vehicleTypeId: _readInt(json['vehicle_type_id']) ?? 0,
      versionId: _readInt(json['version_id']) ?? 0,
      year: _readInt(json['year']) ?? 0,
      color: _readString(json['color']),
      plate: (json['plate'] as String?) ?? '',
      status: json['status'] as bool? ?? false,
      createdAt: _readDateTime(json['created_at']),
      updatedAt: _readDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'user_id': userId,
      'vehicle_type_id': vehicleTypeId,
      'version_id': versionId,
      'year': year,
      'color': color,
      'plate': plate,
      'status': status,
    };
  }

  static int? _readInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  static String? _readString(dynamic value) {
    if (value is String) {
      final String cleaned = value.trim();
      return cleaned.isEmpty ? null : cleaned;
    }
    return null;
  }

  static DateTime? _readDateTime(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
