enum DriversLicenseCategoryEnum {
  motorcycle(1, 'A'),
  automobile(2, 'B'),
  cargoVehicle(3, 'C'),
  passengerTransport(4, 'D'),
  coupledVehicle(5, 'E');

  final int id;
  final String code;

  const DriversLicenseCategoryEnum(this.id, this.code);

  String get description {
    return switch (this) {
      DriversLicenseCategoryEnum.motorcycle => 'Motocicleta',
      DriversLicenseCategoryEnum.automobile => 'Automóvel',
      DriversLicenseCategoryEnum.cargoVehicle => 'Veículo de carga',
      DriversLicenseCategoryEnum.passengerTransport =>
        'Transporte de passageiros',
      DriversLicenseCategoryEnum.coupledVehicle =>
        'Veículos com unidade acoplada',
    };
  }
}

extension DriversLicenseCategoryEnumMapper
    on DriversLicenseCategoryEnum {
  static DriversLicenseCategoryEnum? fromId(int id) {
    for (final category in DriversLicenseCategoryEnum.values) {
      if (category.id == id) {
        return category;
      }
    }

    return null;
  }

  static DriversLicenseCategoryEnum? fromCode(String code) {
    final normalizedCode = code.trim().toUpperCase();

    for (final category in DriversLicenseCategoryEnum.values) {
      if (category.code == normalizedCode) {
        return category;
      }
    }

    return null;
  }
}
