import 'package:flutter/material.dart';

import 'package:arrow_maze/config/theme_config.dart';

/// Logo animado de la Home: el título "Arrow" / "Escape" se revela letra por
/// letra como si una flecha lo estuviera "escribiendo" — la misma flecha de
/// punta en V abierta que dibuja [BoardPainter] recorre cada línea de
/// izquierda a derecha, dejando un trazo debajo, y salta a la siguiente línea
/// al terminar. Al terminar la intro, un único pulso de brillo suave en la
/// punta remata la animación (deliberadamente NO es un loop infinito: un
/// `AnimationController.repeat()` sin fin nunca deja de "tickear" aunque la
/// pantalla quede detrás de otra ruta, lo que colgaría `pumpAndSettle` en
/// cualquier prueba de widgets que mantenga la Home montada).
class AnimatedLogo extends StatefulWidget {
  const AnimatedLogo({super.key});

  @override
  State<AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<AnimatedLogo>
    with TickerProviderStateMixin {
  static const ThemeConfig _t = ThemeConfig.dark;
  static const List<String> _line1 = ['A', 'r', 'r', 'o', 'w'];
  static const List<String> _line2 = ['E', 's', 'c', 'a', 'p', 'e'];
  static const double _fontSize = 60;
  static const double _lineGap = 4;

  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  );
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  final GlobalKey _containerKey = GlobalKey();
  final GlobalKey _line1Key = GlobalKey();
  final GlobalKey _line2Key = GlobalKey();

  Rect? _rect1;
  Rect? _rect2;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    _intro.forward().whenCompleteOrCancel(() {
      // Un único pulso (no repetido) de reposo — ver doc del widget.
      if (mounted) _idle.forward();
    });
  }

  void _measure() {
    final container =
        _containerKey.currentContext?.findRenderObject() as RenderBox?;
    final box1 = _line1Key.currentContext?.findRenderObject() as RenderBox?;
    final box2 = _line2Key.currentContext?.findRenderObject() as RenderBox?;
    if (container == null || box1 == null || box2 == null) return;
    if (!container.hasSize || !box1.hasSize || !box2.hasSize) return;

    final topLeft1 = box1.localToGlobal(Offset.zero, ancestor: container);
    final topLeft2 = box2.localToGlobal(Offset.zero, ancestor: container);

    if (!mounted) return;
    setState(() {
      _rect1 = topLeft1 & box1.size;
      _rect2 = topLeft2 & box2.size;
    });
  }

  @override
  void dispose() {
    _intro.dispose();
    _idle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: _containerKey,
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LetterRow(key: _line1Key, letters: _line1, intro: _intro),
            const SizedBox(height: _lineGap),
            _LetterRow(key: _line2Key, letters: _line2, intro: _intro),
          ],
        ),
        if (_rect1 != null && _rect2 != null)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: Listenable.merge([_intro, _idle]),
              builder: (context, _) => CustomPaint(
                painter: _ArrowWritingPainter(
                  line1: _rect1!,
                  line2: _rect2!,
                  progress: Curves.easeInOutCubic.transform(_intro.value),
                  idlePulse: _idle.value,
                  color: _t.primary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Una línea de texto donde cada letra hace fade-in + pequeño "pop" hacia
/// arriba, escalonado en el tiempo para simular que la flecha va revelando
/// cada carácter a su paso.
class _LetterRow extends StatelessWidget {
  final List<String> letters;
  final Animation<double> intro;

  const _LetterRow({
    required super.key,
    required this.letters,
    required this.intro,
  });

  static const ThemeConfig _t = ThemeConfig.dark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(letters.length, (i) {
        final start = i / letters.length;
        final end = (start + 0.5).clamp(0.0, 1.0);
        return AnimatedBuilder(
          animation: intro,
          builder: (context, child) {
            final raw =
                ((intro.value - start) / (end - start)).clamp(0.0, 1.0);
            final eased = Curves.easeOutBack.transform(raw);
            return Opacity(
              opacity: raw,
              child: Transform.translate(
                offset: Offset(0, (1 - eased) * 16),
                child: child,
              ),
            );
          },
          child: Text(
            letters[i],
            style: TextStyle(
              fontSize: _AnimatedLogoState._fontSize,
              fontWeight: FontWeight.w900,
              color: _t.primary,
              height: 1.05,
              letterSpacing: 2,
            ),
          ),
        );
      }),
    );
  }
}

/// Dibuja el trazo (subrayado) que crece bajo cada línea y la punta en V
/// abierta —mismo lenguaje visual que [BoardPainter]— viajando de izquierda
/// a derecha sobre la línea 1, saltando en arco hacia el inicio de la línea
/// 2, y terminando con un pulso de brillo sutil en reposo.
class _ArrowWritingPainter extends CustomPainter {
  final Rect line1;
  final Rect line2;
  final double progress; // 0..1, intro
  final double idlePulse; // 0..1, loop en reposo
  final Color color;

  // Fracción del progreso total dedicada a cada fase.
  static const double _phase1End = 0.45;
  static const double _phase2End = 0.58; // salto entre líneas

  _ArrowWritingPainter({
    required this.line1,
    required this.line2,
    required this.progress,
    required this.idlePulse,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final y1 = line1.bottom + 6;
    final y2 = line2.bottom + 6;

    late final Offset tip;
    if (progress < _phase1End) {
      final t = progress / _phase1End;
      final x = line1.left + line1.width * t;
      _drawTrail(canvas, Offset(line1.left, y1), Offset(x, y1));
      tip = Offset(x, y1);
    } else if (progress < _phase2End) {
      // Trazo 1 completo; la punta salta en arco hacia el inicio de línea 2.
      _drawTrail(canvas, Offset(line1.left, y1), Offset(line1.right, y1));
      final t = (progress - _phase1End) / (_phase2End - _phase1End);
      final arc = (1 - (2 * t - 1) * (2 * t - 1)) * 22; // parábola, pico ~22
      final x = lerpDouble(line1.right, line2.left, t);
      final y = lerpDouble(y1, y2, t) - arc;
      tip = Offset(x, y);
    } else {
      _drawTrail(canvas, Offset(line1.left, y1), Offset(line1.right, y1));
      final t =
          ((progress - _phase2End) / (1 - _phase2End)).clamp(0.0, 1.0);
      final x = line2.left + line2.width * t;
      _drawTrail(canvas, Offset(line2.left, y2), Offset(x, y2));
      tip = Offset(x, y2);
    }

    final settled = progress >= 0.999;
    final headAlpha = settled ? (0.7 + 0.3 * idlePulse) : 1.0;
    _drawHead(canvas, tip, headAlpha);
  }

  void _drawTrail(Canvas canvas, Offset from, Offset to) {
    canvas.drawLine(
      from,
      to,
      Paint()
        ..color = color.withValues(alpha: 0.85)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  /// Punta en V abierta apuntando a la derecha, igual que la cabeza de
  /// flecha del tablero (trazo, no relleno).
  void _drawHead(Canvas canvas, Offset tip, double alpha) {
    const sz = 11.0;
    final apex = tip + const Offset(sz * 0.6, 0);
    final top = tip + const Offset(-sz * 0.35, -sz * 0.7);
    final bottom = tip + const Offset(-sz * 0.35, sz * 0.7);

    canvas.drawPath(
      Path()
        ..moveTo(top.dx, top.dy)
        ..lineTo(apex.dx, apex.dy)
        ..lineTo(bottom.dx, bottom.dy),
      Paint()
        ..color = color.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  static double lerpDouble(double a, double b, double t) => a + (b - a) * t;

  @override
  bool shouldRepaint(covariant _ArrowWritingPainter old) =>
      old.progress != progress ||
      old.idlePulse != idlePulse ||
      old.line1 != line1 ||
      old.line2 != line2 ||
      old.color != color;
}
