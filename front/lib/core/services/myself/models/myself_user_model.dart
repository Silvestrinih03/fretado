class MyselfUserModel {
  final String firstName;
  final String lastName;
  final String email;
  final String cpf;
  final int userTypeId;
  final String? birthDate;
  final String? phone;

  const MyselfUserModel({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.cpf,
    required this.userTypeId,
    this.birthDate,
    this.phone,
  });

  factory MyselfUserModel.fromJson(Map<String, dynamic> json) {
    return MyselfUserModel(
      firstName: _readString(json['first_name']) ?? '',
      lastName: _readString(json['last_name']) ?? '',
      email: _readString(json['email']) ?? '',
      cpf: _readString(json['cpf']) ?? '',
      userTypeId: _readInt(json['user_type_id']) ?? 1,
      birthDate: _readString(json['birth_date']),
      phone: _readString(json['phone']),
    );
  }

  String get fullName => '$firstName $lastName'.trim();

  static String? _readString(dynamic value) {
    if (value == null) {
      return null;
    }

    final String cleaned = value.toString().trim();
    return cleaned.isEmpty ? null : cleaned;
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
