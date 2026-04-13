enum VehicleType {
  mini(
    label: 'Mini',
    description: 'Compact, best value',
    seats: 4,
    imagePath: 'assets/images/vehicles/mini.jpg',
    baseFare: 40,
    perKm: 12,
    perMinute: 2,
    multiplier: 1.0,
  ),
  sedan(
    label: 'Sedan',
    description: 'Comfort rides',
    seats: 4,
    imagePath: 'assets/images/vehicles/sedan.jpg',
    baseFare: 60,
    perKm: 15,
    perMinute: 2.5,
    multiplier: 1.2,
  ),
  suv(
    label: 'SUV',
    description: 'Extra space',
    seats: 7,
    imagePath: 'assets/images/vehicles/suv.png',
    baseFare: 80,
    perKm: 18,
    perMinute: 3,
    multiplier: 1.45,
  );

  const VehicleType({
    required this.label,
    required this.description,
    required this.seats,
    required this.imagePath,
    required this.baseFare,
    required this.perKm,
    required this.perMinute,
    required this.multiplier,
  });

  final String label;
  final String description;
  final int seats;
  final String imagePath;
  final double baseFare;
  final double perKm;
  final double perMinute;
  final double multiplier;

  String get firestoreValue => name;

  static VehicleType fromString(String? v) {
    for (final t in VehicleType.values) {
      if (t.name == v) return t;
    }
    return VehicleType.mini;
  }
}
