class VehicleListItemModel {
  final int id;
  final int userId;
  final int vehicleTypeId;
  final String brand;
  final String? brandCode;
  final String model;
  final String? modelCode;
  final int year;
  final String? yearCode;
  final String? yearLabel;
  final String? color;
  final String plate;
  final int loadCapacityKg;
  final int? widthCm;
  final int? heightCm;
  final int? lengthCm;
  final bool status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const VehicleListItemModel({
    required this.id,
    required this.userId,
    required this.vehicleTypeId,
    required this.brand,
    this.brandCode,
    required this.model,
    this.modelCode,
    required this.year,
    this.yearCode,
    this.yearLabel,
    this.color,
    required this.plate,
    required this.loadCapacityKg,
    this.widthCm,
    this.heightCm,
    this.lengthCm,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory VehicleListItemModel.fromJson(Map<String, dynamic> json) {
    return VehicleListItemModel(
      id: _readInt(json['id']) ?? 0,
      userId: _readInt(json['user_id']) ?? 0,
      vehicleTypeId: _readInt(json['vehicle_type_id']) ?? 0,
      brand: _readString(json['brand']) ?? '',
      brandCode: _readString(json['brand_code']),
      model: _readString(json['model']) ?? '',
      modelCode: _readString(json['model_code']),
      year: _readInt(json['year']) ?? 0,
      yearCode: _readString(json['year_code']),
      yearLabel: _readString(json['year_label']),
      color: _readString(json['color']),
      plate: _readString(json['plate']) ?? '',
      loadCapacityKg: _readInt(json['load_capacity_kg']) ?? 0,
      widthCm: _readInt(json['width_cm']),
      heightCm: _readInt(json['height_cm']),
      lengthCm: _readInt(json['length_cm']),
      status: json['status'] as bool? ?? false,
      createdAt: _readDateTime(json['created_at']),
      updatedAt: _readDateTime(json['updated_at']),
    );
  }

  String get title => [brand, model].where((item) => item.trim().isNotEmpty).join(' ');

  String get subtitle => [brand, model].where((item) => item.trim().isNotEmpty).join(' - ');

  String get yearText => yearLabel ?? year.toString();

  String get statusLabel => status ? 'ATIVO' : 'INATIVO';

  bool get isActive => status;

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