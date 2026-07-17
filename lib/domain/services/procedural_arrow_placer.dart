import 'dart:math';

import 'package:arrow_maze/domain/factories/arrow_spec.dart';
import 'package:arrow_maze/domain/ports/i_arrow_placer.dart';

/// Cubre TODA la forma con flechas válidas y SIEMPRE resolubles — sin celdas
/// vacías — de manera determinista, sin IA.
///
/// Estrategia — "pelado en orden de resolución": las flechas se construyen
/// directamente en el orden en que un jugador podría tocarlas. En cada paso
/// se elige una cabeza y una dirección de salida cuyo rayo de escape
/// (cabeza → borde del tablero) no cruce NINGUNA celda aún sin pelar: las
/// celdas ya peladas pertenecen a flechas que se tocan antes, así que cuando
/// le toque salir a esta ya estarán vacías. La cola se crece doblando por el
/// interior de lo que queda (nunca puede caer sobre el rayo de la propia
/// cabeza, porque el rayo ya no contiene celdas sin pelar). Se repite hasta
/// consumir la forma completa; las celdas sueltas que queden se fusionan a la
/// cola de una flecha vecina (seguro: ningún rayo de escape pasa por ellas,
/// porque estuvieron sin pelar hasta el final). Si un intento deja celdas
/// imposibles de cubrir, se reintenta con otra semilla y se devuelve el mejor
/// resultado (cobertura total en la práctica para siluetas macizas).
class ProceduralArrowPlacer implements IArrowPlacer {
  // N, E, S, O — coincide con la codificación de ArrowFactory.
  static const List<List<int>> _dirs = [
    [-1, 0],
    [0, 1],
    [1, 0],
    [0, -1],
  ];

  static const List<String> _palette = [
    '#EF476F',
    '#06D6A0',
    '#118AB2',
    '#FFD166',
    '#8338EC',
    '#FB5607',
    '#3A86FF',
    '#FF006E',
  ];

  static const int _maxAttempts = 40;

  @override
  List<ArrowSpec> place(List<List<int>> cells, {Random? random}) {
    final rng = random ?? Random();
    if (cells.length < 2) return const [];

    final shape = <String>{for (final c in cells) '${c[0]},${c[1]}'};

    // Reintenta con semillas derivadas (determinista dado [random]) y se
    // queda con el intento de mayor cobertura; cobertura total corta.
    List<List<List<int>>> best = const [];
    var bestUncovered = 1 << 30;
    for (var attempt = 0; attempt < _maxAttempts; attempt++) {
      // 1 << 30 y no 1 << 32: en web (dart2js) los shifts siguen la
      // semántica de JS y 1 << 32 se desborda a 0 → RangeError en nextInt.
      final result = _tile(cells, shape, Random(rng.nextInt(1 << 30)));
      if (result.uncovered < bestUncovered) {
        best = result.paths;
        bestUncovered = result.uncovered;
      }
      if (bestUncovered == 0) break;
    }

    return [
      for (var i = 0; i < best.length; i++)
        ArrowSpec(
          id: 'a${i + 1}',
          // path va tail → head (cabeza al final) para ArrowSpec/ArrowFactory.
          path: best[i].reversed.map((c) => [c[0], c[1]]).toList(),
          color: _palette[i % _palette.length],
        ),
    ];
  }

  /// Un intento de teselado completo. Devuelve los caminos (cabeza primero)
  /// en orden de toque y cuántas celdas quedaron sin cubrir.
  ({List<List<List<int>>> paths, int uncovered}) _tile(
    List<List<int>> cells,
    Set<String> shape,
    Random rng,
  ) {
    final free = <String>{...shape};
    final paths = <List<List<int>>>[];

    while (free.isNotEmpty) {
      // Candidatas: cabeza con celda de atrás sin pelar y rayo de escape
      // libre de celdas sin pelar.
      final candidates = <(List<int>, List<int>)>[];
      for (final cell in cells) {
        final hr = cell[0];
        final hc = cell[1];
        if (!free.contains('$hr,$hc')) continue;
        for (final d in _dirs) {
          if (!free.contains('${hr - d[0]},${hc - d[1]}')) continue;
          if (_rayBlocked(hr, hc, d, shape, free)) continue;
          candidates.add(([hr, hc], d));
        }
      }
      if (candidates.isEmpty) break;

      final (head, d) = candidates[rng.nextInt(candidates.length)];
      final path = _growTail(head, [head[0] - d[0], head[1] - d[1]], free, rng);
      for (final c in path) {
        free.remove('${c[0]},${c[1]}');
      }
      paths.add(path);
    }

    _mergeLeftovers(free, paths);
    return (paths: paths, uncovered: free.length);
  }

  /// ¿El rayo de escape (desde la cabeza, en [d], hasta salir de la forma)
  /// cruza alguna celda sin pelar?
  bool _rayBlocked(int hr, int hc, List<int> d, Set<String> shape, Set<String> free) {
    for (var k = 1;; k++) {
      final key = '${hr + d[0] * k},${hc + d[1] * k}';
      if (!shape.contains(key)) return false; // salió de la forma → escapable
      if (free.contains(key)) return true;
    }
  }

  /// Crece la cola desde [behind] por celdas sin pelar (puede doblar).
  /// Devuelve el camino cabeza-primero. Al elegir el siguiente paso prefiere
  /// vecinas con menos vecinas libres (estilo Warnsdorff): consume los
  /// callejones sin salida antes de que queden huérfanos.
  List<List<int>> _growTail(
    List<int> head,
    List<int> behind,
    Set<String> free,
    Random rng,
  ) {
    final headFirst = <List<int>>[head, behind];
    final used = <String>{'${head[0]},${head[1]}', '${behind[0]},${behind[1]}'};
    final targetLen = 3 + rng.nextInt(3); // 3..5 celdas

    var cur = behind;
    while (headFirst.length < targetLen) {
      List<int>? next;
      var bestDegree = 1 << 30;
      for (final d in _dirs) {
        final nr = cur[0] + d[0];
        final nc = cur[1] + d[1];
        final nk = '$nr,$nc';
        if (!free.contains(nk) || used.contains(nk)) continue;
        final degree = _freeDegree(nr, nc, free, used);
        if (degree < bestDegree || (degree == bestDegree && rng.nextBool())) {
          bestDegree = degree;
          next = [nr, nc];
        }
      }
      if (next == null) break;
      headFirst.add(next);
      used.add('${next[0]},${next[1]}');
      cur = next;
    }
    return headFirst;
  }

  int _freeDegree(int r, int c, Set<String> free, Set<String> used) {
    var degree = 0;
    for (final d in _dirs) {
      final key = '${r + d[0]},${c + d[1]}';
      if (free.contains(key) && !used.contains(key)) degree++;
    }
    return degree;
  }

  /// Fusiona celdas sueltas restantes en la cola de una flecha adyacente.
  /// Es seguro porque una celda sin pelar hasta este punto no está en el rayo
  /// de escape de NINGUNA flecha (todos los rayos se validaron contra ella),
  /// y anexarla al final de la cola mantiene el camino como cadena simple.
  void _mergeLeftovers(Set<String> free, List<List<List<int>>> paths) {
    var progress = true;
    while (free.isNotEmpty && progress) {
      progress = false;
      for (final key in free.toList()) {
        final parts = key.split(',');
        final r = int.parse(parts[0]);
        final c = int.parse(parts[1]);
        for (final path in paths) {
          final tail = path.last; // cabeza-primero: la cola es el último
          final adjacent = (tail[0] - r).abs() + (tail[1] - c).abs() == 1;
          if (adjacent) {
            path.add([r, c]);
            free.remove(key);
            progress = true;
            break;
          }
        }
        if (progress) break;
      }
    }
  }
}
