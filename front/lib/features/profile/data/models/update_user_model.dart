class UpdateUserModel {
  final String firstName;
  final String lastName;
  final String email;
  final String? birthDate;
  final String? phone;

  const UpdateUserModel({
    required this.firstName,
    required this.lastName,
    required this.email,
    this.birthDate,
    this.phone,
  });

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'birth_date': birthDate,
      'phone': phone,
    };
  }
}
