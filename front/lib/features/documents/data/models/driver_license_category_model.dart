import '../../../../core/enums/drivers_license_categories.dart';

class DriverLicenseCategoryModel {
  final int id;
  final String code;
  final String description;

  const DriverLicenseCategoryModel({
    required this.id,
    required this.code,
    required this.description,
  });

  factory DriverLicenseCategoryModel.fromJson(Map<String, dynamic> json) {
    return DriverLicenseCategoryModel(
      id: _readInt(json['id']) ?? -1,
      code: (json['code'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
    );
  }

  DriversLicenseCategoryEnum? get category {
    final categoryById = DriversLicenseCategoryEnumMapper.fromId(id);
    if (categoryById != null) {
      return categoryById;
    }

    return DriversLicenseCategoryEnumMapper.fromCode(code);
  }

  String get label {
    final mappedCategory = category;
    if (mappedCategory != null) {
      return mappedCategory.code;
    }

    final normalizedCode = code.trim().toUpperCase();
    if (normalizedCode.isEmpty) {
      return 'Categoria';
    }

    return normalizedCode;
  }

  String get fullLabel {
    final normalizedDescription = description.trim().isEmpty
        ? category?.description ?? ''
        : description.trim();

    if (normalizedDescription.isEmpty) {
      return label;
    }

    return '$label - $normalizedDescription';
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
