class VehicleListItemModel {
  final int id;
  final int userId;
  final int? vehicleModelId;
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
    this.vehicleModelId,
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
    final nestedModel = json['vehicle_model'];
    final details = nestedModel is Map
        ? Map<String, dynamic>.from(nestedModel)
        : json;
    return VehicleListItemModel(
      id: _readInt(json['id']) ?? 0,
      userId: _readInt(json['user_id']) ?? 0,
      vehicleModelId: _readInt(json['vehicle_model_id']),
      vehicleTypeId: _readInt(details['vehicle_type_id']) ?? 0,
      brand: _readString(details['brand']) ?? '',
      brandCode: _readString(details['brand_code']),
      model: _readString(details['model']) ?? '',
      modelCode: _readString(details['model_code']),
      year: _readInt(details['year']) ?? 0,
      yearCode: _readString(details['year_code']),
      yearLabel: _readString(details['year_label']),
      color: _readString(json['color']),
      plate: _readString(json['plate']) ?? '',
      loadCapacityKg: _readInt(details['load_capacity_kg']) ?? 0,
      widthCm: _readInt(details['cargo_width_cm'] ?? details['width_cm']),
      heightCm: _readInt(details['cargo_height_cm'] ?? details['height_cm']),
      lengthCm: _readInt(details['cargo_length_cm'] ?? details['length_cm']),
      status: json['status'] as bool? ?? false,
      createdAt: _readDateTime(json['created_at']),
      updatedAt: _readDateTime(json['updated_at']),
    );
  }

  String get title {
    final name = [
      brand,
      model,
    ].where((item) => item.trim().isNotEmpty).join(' ');
    return name.isEmpty ? 'Dados do veículo indisponíveis' : name;
  }

  String get subtitle =>
      [brand, model].where((item) => item.trim().isNotEmpty).join(' - ');

  String get yearText =>
      yearLabel ?? (year > 0 ? year.toString() : 'Não informado');

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
