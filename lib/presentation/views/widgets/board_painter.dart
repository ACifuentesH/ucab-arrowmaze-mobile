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
    _drawBackground(canvas, size);
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

  void _drawBackground(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF232328));
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
    _drawBody(canvas, pts, color, cs);
    _drawHead(canvas, pts.last, arrow.headDirection.index, color, cs);
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
    _drawBody(canvas, pts, color, cs);
    _drawHead(canvas, pts.last, arrow.headDirection.index, color, cs);
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

  /// Punta V abierta (no rellena).
  void _drawHead(Canvas canvas, Offset tip, int dirIndex, Color color, double cs) {
    final d = _dir[dirIndex];
    final perp = Offset(-d.dy, d.dx);
    final sz = cs * 0.30;
    final sw = cs * 0.11;

    // La punta avanza un poco más allá del centro de la celda cabeza
    final apex = tip + Offset(d.dx * sz * 0.6, d.dy * sz * 0.6);
    final left  = apex + Offset((-d.dx + perp.dx * 0.7) * sz,
                                 (-d.dy + perp.dy * 0.7) * sz);
    final right = apex + Offset((-d.dx - perp.dx * 0.7) * sz,
                                 (-d.dy - perp.dy * 0.7) * sz);

    canvas.drawPath(
      Path()
        ..moveTo(left.dx, left.dy)
        ..lineTo(apex.dx, apex.dy)
        ..lineTo(right.dx, right.dy),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw
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

  Color _color(String hex) {
    final s = hex.replaceFirst('#', '');
    return Color(int.parse('FF$s', radix: 16));
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
