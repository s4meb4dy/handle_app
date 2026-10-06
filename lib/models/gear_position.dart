class GearPosition {
  final String gear;
  final double? x;
  final double? y;

  const GearPosition({
    required this.gear,
    this.x,
    this.y,
  });

  bool get configured => x != null && y != null;

  factory GearPosition.fromBle(String line) {
    final parts = line.split(';');

    if (parts.length < 3) {
      return GearPosition(gear: '');
    }

    final gear = parts[1];

    if (parts[2] == 'NA') {
      return GearPosition(gear: gear);
    }

    final x = double.tryParse(parts[2]);

    double? y;

    if (parts.length >= 4) {
      y = double.tryParse(parts[3]);
    }

    return GearPosition(
      gear: gear,
      x: x,
      y: y,
    );
  }
}