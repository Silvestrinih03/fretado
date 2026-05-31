class UserCardCreateModel {
  final int userId;
  final String cardholderName;
  final String cardNumber;
  final int expirationMonth;
  final int expirationYear;
  final String cvv;
  final bool isDefault;

  const UserCardCreateModel({
    required this.userId,
    required this.cardholderName,
    required this.cardNumber,
    required this.expirationMonth,
    required this.expirationYear,
    required this.cvv,
    required this.isDefault,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'user_id': userId,
      'cardholder_name': cardholderName,
      'card_number': cardNumber,
      'expiration_month': expirationMonth,
      'expiration_year': expirationYear,
      'cvv': cvv,
      'is_default': isDefault,
    };
  }
}
