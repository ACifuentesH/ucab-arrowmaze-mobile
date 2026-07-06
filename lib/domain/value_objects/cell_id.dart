/// Value Object: identidad de una celda dentro del tablero.
/// No es un primitivo: encapsula la regla "una celda se identifica por su valor"
/// y la comparación por valor. (Millett, cap.15: los VO se definen por sus
/// atributos, son inmutables y se comparan por igualdad estructural).
class CellId {
  final String value;

  const CellId._(this.value);

  factory CellId(String value) {
    if (value.trim().isEmpty) {
      throw ArgumentError('CellId no puede estar vacío.');
    }
    return CellId._(value);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is CellId && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'CellId($value)';
}
