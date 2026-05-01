import '../../../../core/enums/vehicle_type.dart';

class VehicleTypeModel {
  final int id;
  final String type;

  const VehicleTypeModel({required this.id, required this.type});

  factory VehicleTypeModel.fromJson(Map<String, dynamic> json) {
    return VehicleTypeModel(
      id: _readInt(json['id']) ?? -1,
      type: (json['type'] as String?) ?? '',
    );
  }

  VehicleType? get vehicleType => VehicleTypeExtension.fromValue(id);

  String get label {
    final VehicleType? mappedType = vehicleType;
    if (mappedType != null) {
      return mappedType.label;
    }

    final String trimmed = type.trim();
    if (trimmed.isEmpty) {
      return 'Tipo de veículo';
    }

    final String normalized = trimmed.replaceAll('_', ' ').replaceAll('-', ' ');
    return normalized[0].toUpperCase() + normalized.substring(1);
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
}
