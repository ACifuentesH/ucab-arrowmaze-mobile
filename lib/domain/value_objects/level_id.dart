/// Value Object: identidad de un nivel.
class LevelId {
  final String value;
  const LevelId._(this.value);

  factory LevelId(String value) {
    if (value.trim().isEmpty) throw ArgumentError('LevelId vacío.');
    return LevelId._(value);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is LevelId && other.value == value);
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => 'LevelId($value)';
}
