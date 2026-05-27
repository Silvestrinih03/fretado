class DriverDocumentModel {
  final int? id;
  final int? userId;
  final String licenseNumber;
  final int licenseCategoryId;
  final String issueDate;
  final String expirationDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DriverDocumentModel({
    this.id,
    this.userId,
    required this.licenseNumber,
    required this.licenseCategoryId,
    required this.issueDate,
    required this.expirationDate,
    this.createdAt,
    this.updatedAt,
  });

  factory DriverDocumentModel.fromJson(Map<String, dynamic> json) {
    return DriverDocumentModel(
      id: _readInt(json['id']),
      userId: _readInt(json['user_id']),
      licenseNumber: (json['license_number'] as String?) ?? '',
      licenseCategoryId: _readInt(json['license_category_id']) ?? 0,
      issueDate: (json['issue_date'] as String?) ?? '',
      expirationDate: (json['expiration_date'] as String?) ?? '',
      createdAt: _readDateTime(json['created_at']),
      updatedAt: _readDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'license_number': licenseNumber,
      'license_category_id': licenseCategoryId,
      'issue_date': issueDate,
      'expiration_date': expirationDate,
    };
  }

  DateTime? get issueDateValue => _readDateTime(issueDate);

  DateTime? get expirationDateValue => _readDateTime(expirationDate);

  static int? _readInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is String) {
      return int.tryParse(value);
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
