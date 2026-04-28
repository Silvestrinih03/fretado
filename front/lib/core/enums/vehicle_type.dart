enum VehicleType {
  motorcycle(1),
  hatchback(2),
  sedan(3),
  pickup(4),
  van(5),
  utility(6),
  truck(7);

  final int value;

  const VehicleType(this.value);

  String get label {
    switch (this) {
      case VehicleType.motorcycle:
        return 'Moto';
      case VehicleType.hatchback:
        return 'Hatch';
      case VehicleType.sedan:
        return 'Sedan';
      case VehicleType.pickup:
        return 'Pickup';
      case VehicleType.van:
        return 'Van';
      case VehicleType.utility:
        return 'Utilitário';
      case VehicleType.truck:
        return 'Caminhão';
    }
  }
}

extension VehicleTypeExtension on VehicleType {
  static VehicleType? fromValue(int value) {
    for (final VehicleType vehicleType in VehicleType.values) {
      if (vehicleType.value == value) {
        return vehicleType;
      }
    }
    return null;
  }
}
