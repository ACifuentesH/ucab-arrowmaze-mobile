/// Value Object: vidas restantes del jugador. Inmutable.
/// Cada operación devuelve una nueva instancia (Millett, cap.15).
class Lives {
  static const int defaultCount = 3;

  final int value;
  const Lives._(this.value);

  factory Lives([int value = defaultCount]) {
    if (value < 0) throw ArgumentError('Lives no puede ser negativo.');
    return Lives._(value);
  }

  Lives decrement() => Lives._(value > 0 ? value - 1 : 0);

  bool get isExhausted => value == 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Lives && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Lives($value)';
}
