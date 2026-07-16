import 'package:flutter/material.dart';
import 'package:arrow_maze/domain/entities/arrow.dart';
import 'package:arrow_maze/domain/value_objects/cell_id.dart';

/// CustomPainter del tablero:
///   - Fondo oscuro + punto pequeño por cada celda (la flecha los tapa)
///   - Flechas delgadas con punta V abierta
///   - Escape: el cuerpo recorre su propio camino y sale del tablero
///   - Bloqueada: shake horizontal
class BoardPainter extends CustomPainter {
  final int boundingRows;
  final int boundingCols;
  final Set<CellId> existingCells;
  final Map<String, Arrow> arrows;
  final Arrow? escapingArrow;
  final double escapeProgress; // 0 → 1
  final String? blockedArrowId;
  final double shakeOffsetX;

  // N=0, E=1, S=2, O=3
  static const List<Offset> _dir = [
    Offset(0, -1),
    Offset(1,  0),
    Offset(0,  1),
    Offset(-1, 0),
  ];

  const BoardPainter({
    required this.boundingRows,
    required this.boundingCols,
    required this.existingCells,
    required this.arrows,
    this.escapingArrow,
    this.escapeProgress = 0,
    this.blockedArrowId,
    this.shakeOffsetX = 0,
  });

  // ── paint ────────────────────────────────────────────────────────────────────

  @override
  void paint(Canvas canvas, Size size) {
    final cs = size.width / boundingCols; // cell size (siempre cuadrada)

    canvas.clipRect(Offset.zero & size);
    _drawBackground(canvas, cs);
    _drawDots(canvas, cs);

    for (final arrow in arrows.values) {
      if (arrow.id == blockedArrowId) continue;
      _drawArrow(canvas, arrow, cs, _baseCenters(arrow, cs));
    }

    if (blockedArrowId != null && arrows.containsKey(blockedArrowId)) {
      final shaken = _baseCenters(arrows[blockedArrowId!]!, cs)
          .map((c) => c + Offset(shakeOffsetX, 0))
          .toList();
      _drawArrow(canvas, arrows[blockedArrowId!]!, cs, shaken);
    }

    if (escapingArrow != null && escapeProgress > 0) {
      _drawEscaping(canvas, escapingArrow!, cs, escapeProgress);
    }
  }

  // ── background & dots ────────────────────────────────────────────────────────

  /// Fondo unicolor: se pinta SOLO en las celdas que existen (la forma real del
  /// nivel), no en todo el rectángulo contenedor. Así las celdas fuera de la
  /// forma quedan transparentes y muestran el fondo del Scaffold, sin dejar un
  /// bloque rectangular visible detrás de niveles irregulares (corazón, rombo…).
  /// El color coincide con ThemeConfig.boardBackground.
  void _drawBackground(Canvas canvas, double cs) {
    final path = Path();
    for (final id in existingCells) {
      final rc = _parseId(id.value);
      if (rc == null) continue;
      path.addRect(Rect.fromLTWH(rc.$2 * cs, rc.$1 * cs, cs, cs));
    }
    canvas.drawPath(path, Paint()..color = const Color(0xFF232328));
  }

  void _drawDots(Canvas canvas, double cs) {
    final paint = Paint()..color = const Color(0xFF48454C);
    final r = cs * 0.09; // pequeño para que la flecha lo tape
    for (final id in existingCells) {
      final rc = _parseId(id.value);
      if (rc == null) continue;
      canvas.drawCircle(_center(rc.$1, rc.$2, cs), r, paint);
    }
  }

  // ── arrow drawing ─────────────────────────────────────────────────────────────

  void _drawArrow(Canvas canvas, Arrow arrow, double cs, List<Offset> pts) {
    final color = _color(arrow.color);
    _drawArrowAt(canvas, pts, arrow.headDirection.index, color, cs);
  }

  /// Dibuja cuerpo + cabeza garantizando que se toquen. El cuerpo se prolonga
  /// hasta el ápice de la cabeza (en dirección [dirIndex]), de modo que la línea
  /// entra en la punta de la flecha sin dejar hueco — incluso cuando el último
  /// tramo del camino llega desde otra dirección (flechas dobladas/en L).
  void _drawArrowAt(
    Canvas canvas,
    List<Offset> pts,
    int dirIndex,
    Color color,
    double cs,
  ) {
    final head = _headPoints(pts.last, dirIndex, cs);
    _drawBody(canvas, [...pts, head.apex], color, cs);
    _drawHead(canvas, head, color, cs);
  }

  /// Animación que recorre el camino: cada celda avanza `t*n` pasos en el
  /// camino extendido (original + continuación en dirección de la punta).
  void _drawEscaping(Canvas canvas, Arrow arrow, double cs, double t) {
    final base = _baseCenters(arrow, cs);
    final n = base.length;
    final d = _dir[arrow.headDirection.index];

    // Camino extendido: n puntos extra en dirección de la punta
    final ext = [...base];
    for (int i = 1; i <= n; i++) {
      ext.add(Offset(base.last.dx + d.dx * i * cs,
                     base.last.dy + d.dy * i * cs));
    }

    final advance = t * n;
    final pts = List.generate(n, (i) {
      final pos = i + advance;
      final lo = pos.floor().clamp(0, ext.length - 2);
      final frac = (pos - lo).clamp(0.0, 1.0);
      return Offset.lerp(ext[lo], ext[lo + 1], frac)!;
    });

    // Desvanece solo en el último 30 % para que se vea limpio
    final alpha = t < 0.7
        ? 255
        : ((1.0 - (t - 0.7) / 0.3) * 255).round().clamp(0, 255);
    final color = _color(arrow.color).withAlpha(alpha);
    _drawArrowAt(canvas, pts, arrow.headDirection.index, color, cs);
  }

  // ── primitives ────────────────────────────────────────────────────────────────

  void _drawBody(Canvas canvas, List<Offset> pts, Color color, double cs) {
    if (pts.length < 2) return;
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx, pts[i].dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = cs * 0.11
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
  }

  /// Geometría de la punta V (apex + dos alas) para una cabeza en [tip] que
  /// apunta hacia [dirIndex]. Función pura y determinista (testeable).
  static ({Offset apex, Offset left, Offset right}) _headPoints(
    Offset tip,
    int dirIndex,
    double cs,
  ) {
    final d = _dir[dirIndex];
    final perp = Offset(-d.dy, d.dx);
    final sz = cs * 0.30;

    // La punta avanza un poco más allá del centro de la celda cabeza.
    final apex = tip + Offset(d.dx * sz * 0.6, d.dy * sz * 0.6);
    final left = apex +
        Offset((-d.dx + perp.dx * 0.7) * sz, (-d.dy + perp.dy * 0.7) * sz);
    final right = apex +
        Offset((-d.dx - perp.dx * 0.7) * sz, (-d.dy - perp.dy * 0.7) * sz);
    return (apex: apex, left: left, right: right);
  }

  /// Punta V abierta (no rellena).
  void _drawHead(
    Canvas canvas,
    ({Offset apex, Offset left, Offset right}) head,
    Color color,
    double cs,
  ) {
    canvas.drawPath(
      Path()
        ..moveTo(head.left.dx, head.left.dy)
        ..lineTo(head.apex.dx, head.apex.dy)
        ..lineTo(head.right.dx, head.right.dy),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = cs * 0.11
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  // ── helpers ───────────────────────────────────────────────────────────────────

  List<Offset> _baseCenters(Arrow arrow, double cs) =>
      arrow.path.map((id) {
        final rc = _parseId(id.value)!;
        return _center(rc.$1, rc.$2, cs);
      }).toList();

  Offset _center(int r, int c, double cs) =>
      Offset((c + 0.5) * cs, (r + 0.5) * cs);

  /// Niveles generados con IA pueden traer el color como nombre CSS
  /// ("crimson", "hotpink"...) en vez de hex — el modelo no siempre respeta
  /// el formato pedido. Se soportan ambos; si no se puede interpretar, cae a
  /// un color de la paleta en vez de tirar una excepción a mitad del paint().
  static const Map<String, int> _cssColors = {
    'red': 0xFFFF0000, 'crimson': 0xFFDC143C, 'deeppink': 0xFFFF1493,
    'hotpink': 0xFFFF69B4, 'pink': 0xFFFFC0CB, 'orange': 0xFFFFA500,
    'orangered': 0xFFFF4500, 'gold': 0xFFFFD700, 'yellow': 0xFFFFFF00,
    'green': 0xFF008000, 'limegreen': 0xFF32CD32, 'lime': 0xFF00FF00,
    'teal': 0xFF008080, 'turquoise': 0xFF40E0D0, 'cyan': 0xFF00FFFF,
    'blue': 0xFF0000FF, 'royalblue': 0xFF4169E1, 'dodgerblue': 0xFF1E90FF,
    'navy': 0xFF000080, 'indigo': 0xFF4B0082, 'purple': 0xFF800080,
    'violet': 0xFFEE82EE, 'magenta': 0xFFFF00FF, 'orchid': 0xFFDA70D6,
    'brown': 0xFFA52A2A, 'coral': 0xFFFF7F50, 'salmon': 0xFFFA8072,
    'white': 0xFFFFFFFF, 'black': 0xFF000000, 'gray': 0xFF808080,
    'grey': 0xFF808080,
  };

  static const List<int> _fallbackPalette = [
    0xFFEF476F, 0xFF06D6A0, 0xFF118AB2, 0xFFFFD166,
    0xFF8338EC, 0xFFFB5607, 0xFF3A86FF, 0xFFFF006E,
  ];

  Color _color(String raw) {
    final s = raw.trim();
    if (s.startsWith('#')) {
      final parsed = int.tryParse('FF${s.substring(1)}', radix: 16);
      if (parsed != null) return Color(parsed);
    } else {
      final named = _cssColors[s.toLowerCase()];
      if (named != null) return Color(named);
      final parsed = int.tryParse('FF$s', radix: 16);
      if (parsed != null) return Color(parsed);
    }
    return Color(_fallbackPalette[s.hashCode.abs() % _fallbackPalette.length]);
  }

  static (int, int)? _parseId(String id) {
    final m = RegExp(r'^r(\d+)c(\d+)$').firstMatch(id);
    if (m == null) return null;
    return (int.parse(m.group(1)!), int.parse(m.group(2)!));
  }

  @override
  bool shouldRepaint(BoardPainter old) =>
      old.boundingRows != boundingRows ||
      old.boundingCols != boundingCols ||
      old.existingCells != existingCells ||
      old.arrows != arrows ||
      old.escapingArrow != escapingArrow ||
      old.escapeProgress != escapeProgress ||
      old.blockedArrowId != blockedArrowId ||
      old.shakeOffsetX != shakeOffsetX;
}
