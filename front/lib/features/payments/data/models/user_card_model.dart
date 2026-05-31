class UserCardModel {
  final int id;
  final String cardholderName;
  final String brand;
  final String lastFour;
  final int expirationMonth;
  final int expirationYear;
  final bool isDefault;

  const UserCardModel({
    required this.id,
    required this.cardholderName,
    required this.brand,
    required this.lastFour,
    required this.expirationMonth,
    required this.expirationYear,
    required this.isDefault,
  });

  factory UserCardModel.fromJson(Map<String, dynamic> json) {
    return UserCardModel(
      id: _readInt(json['id']) ?? 0,
      cardholderName: (json['cardholder_name'] as String?) ?? '',
      brand: (json['brand'] as String?) ?? 'unknown',
      lastFour: (json['last_four'] as String?) ?? '',
      expirationMonth: _readInt(json['expiration_month']) ?? 0,
      expirationYear: _readInt(json['expiration_year']) ?? 0,
      isDefault: json['is_default'] as bool? ?? false,
    );
  }

  String get brandLabel {
    return switch (brand.toLowerCase()) {
      'visa' => 'Visa',
      'mastercard' => 'Mastercard',
      'amex' => 'American Express',
      'discover' => 'Discover',
      _ => 'Cartao',
    };
  }

  String get expirationText {
    final month = expirationMonth.toString().padLeft(2, '0');
    return '$month/$expirationYear';
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
