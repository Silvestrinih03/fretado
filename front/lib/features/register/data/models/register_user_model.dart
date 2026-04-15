class RegisterUserModel {
  final int id;
  final String cpf;
  final String email;
  final int userTypeId;
  final String firstName;
  final String lastName;
  final String? birthDate;
  final String? phone;

  const RegisterUserModel({
    required this.id,
    required this.cpf,
    required this.email,
    required this.userTypeId,
    required this.firstName,
    required this.lastName,
    this.birthDate,
    this.phone,
  });

  factory RegisterUserModel.fromJson(Map<String, dynamic> json) {
    return RegisterUserModel(
      id: json['id'] as int,
      cpf: json['cpf'] as String,
      email: json['email'] as String,
      userTypeId: json['user_type_id'] as int,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      birthDate: json['birth_date'] as String?,
      phone: json['phone'] as String?,
    );
  }
}
