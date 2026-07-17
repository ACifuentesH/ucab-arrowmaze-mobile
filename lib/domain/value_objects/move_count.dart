/// Value Object: número de movimientos. Base del sistema de puntuación.
/// Inmutable: cada operación devuelve una NUEVA instancia (Millett, cap.15).
class MoveCount {
  final int value;
  const MoveCount._(this.value);

  factory MoveCount([int value = 0]) {
    if (value < 0) throw ArgumentError('MoveCount no puede ser negativo.');
    return MoveCount._(value);
  }

  MoveCount increment() => MoveCount._(value + 1);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is MoveCount && other.value == value);
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => 'MoveCount($value)';
}
