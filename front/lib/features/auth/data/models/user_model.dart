class UserModel {
  final int id;
  final String email;
  final String cpf;
  final int userTypeId;

  const UserModel({
    required this.id,
    required this.email,
    required this.cpf,
    required this.userTypeId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      email: json['email'] as String,
      cpf: json['cpf'] as String,
      userTypeId: json['user_type_id'] as int,
    );
  }
}
