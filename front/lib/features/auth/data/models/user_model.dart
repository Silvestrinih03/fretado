class UserModel {
  final int id;
  final String email;
  final String cpf;
  final int userTypeId;
  final String? accessToken;

  const UserModel({
    required this.id,
    required this.email,
    required this.cpf,
    required this.userTypeId,
    this.accessToken,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: _readInt(json['id']) ?? 0,
      email: json['email']?.toString() ?? '',
      cpf: json['cpf']?.toString() ?? '',
      userTypeId: _readInt(json['user_type_id']) ?? 1,
      accessToken: json['access_token']?.toString(),
    );
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
