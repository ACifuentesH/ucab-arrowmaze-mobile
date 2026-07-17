/// Especificación declarativa de una flecha tal como viene del JSON del nivel.
/// path es una lista de [row, col] ordenada tail→head.
class ArrowSpec {
  final String id;
  final List<List<int>> path;
  final String color;

  const ArrowSpec({
    required this.id,
    required this.path,
    required this.color,
  });

  factory ArrowSpec.fromJson(Map<String, dynamic> json) {
    return ArrowSpec(
      id: json['id'] as String,
      path: (json['path'] as List<dynamic>)
          .map((e) => [
                (e as List<dynamic>)[0] as int,
                e[1] as int,
              ])
          .toList(),
      color: (json['color'] as String?) ?? '#4FC3F7',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'path': path,
        'color': color,
      };
}
