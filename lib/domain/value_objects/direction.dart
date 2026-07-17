/// Value Object: una dirección/puerto del tablero, definida de forma GENÉRICA.
/// En vez de fijar 4 direcciones (N/S/E/O), una dirección es un índice dentro de
/// un total de puertos que define la topología:
///   - cuadrícula cuadrada  -> total = 4
///   - cuadrícula hexagonal -> total = 6
///   - topologías 3D u otras -> total = N
/// Así el dominio NO queda acoplado a una forma de tablero concreta.
/// 
class Direction {
  final int index;
  final int total;

  const Direction._(this.index, this.total);

  factory Direction({required int index, required int total}) {
    if (total <= 0) throw ArgumentError('total de puertos debe ser > 0.');
    if (index < 0 || index >= total) {
      throw ArgumentError('index ($index) fuera de rango [0, $total).');
    }
    return Direction._(index, total);
  }

  /// Siguiente puerto en sentido horario. Base genérica para rotar flechas.
  Direction next() => Direction(index: (index + 1) % total, total: total);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Direction && other.index == index && other.total == total);

  @override
  int get hashCode => Object.hash(index, total);

  @override
  String toString() => 'Direction($index/$total)';
}
