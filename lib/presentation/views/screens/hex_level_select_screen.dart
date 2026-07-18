import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:arrow_maze/application/dtos/level_select_entry.dart';
import 'package:arrow_maze/application/dtos/playable_level.dart';
import 'package:arrow_maze/application/enums/level_status.dart';
import 'package:arrow_maze/config/providers.dart';
import 'package:arrow_maze/config/theme_config.dart';
import 'package:arrow_maze/l10n/app_localizations.dart';
import 'package:arrow_maze/presentation/views/screens/game_screen.dart';

/// Ventana del MODO HEXAGONAL: la campaña hex dibujada como sendero progresivo
/// (nodos circulares encadenados que serpentean hacia abajo), ESPEJO VISUAL del
/// `_CampaignTrail` de la campaña cuadrada, pero con acento ámbar/miel y un
/// nodo final "próximamente" en construcción como teaser de futuros niveles.
///
/// Es un espejo deliberado y no el widget original extraído: el trail cuadrado
/// está acoplado a su pantalla (leaderboard por nodo, `campaignTileKey`) y esa
/// pantalla y sus tests deben permanecer intactos. Patrones compartidos:
/// initState + load, cola de campaña con `PlayableLevel.fromPreview` +
/// `startCampaign`, recarga al volver. Sin login: los niveles hex son locales.
class HexLevelSelectScreen extends ConsumerStatefulWidget {
  const HexLevelSelectScreen({super.key});

  /// Key estable del nodo del nivel hex número [number] (1-based) para las
  /// pruebas de navegación/interacción.
  static Key hexTileKey(int number) => Key('hex_tile_$number');

  /// Key del nodo "próximamente" (en construcción) al final del sendero.
  static const Key comingSoonTileKey = Key('hex_coming_soon_tile');

  @override
  ConsumerState<HexLevelSelectScreen> createState() =>
      _HexLevelSelectScreenState();
}

class _HexLevelSelectScreenState extends ConsumerState<HexLevelSelectScreen> {
  static const ThemeConfig _t = ThemeConfig.dark;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(hexLevelSelectViewModelProvider.notifier).load(),
    );
  }

  /// Igual que `_playCampaign` de la campaña cuadrada: la cola arranca en el
  /// nivel tocado, de modo que completar "Panal" encadena automáticamente con
  /// los siguientes y el progreso desbloquea/persiste con la infraestructura
  /// común.
  Future<void> _playHex(List<LevelSelectEntry> entries, int index) async {
    final queue = entries
        .skip(index)
        .map((e) => PlayableLevel.fromPreview(e.preview))
        .toList();
    await ref.read(gameViewModelProvider.notifier).startCampaign(queue);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const GameScreen()),
    );
    if (mounted) ref.read(hexLevelSelectViewModelProvider.notifier).load();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final state = ref.watch(hexLevelSelectViewModelProvider);
    final entries = state.entries;

    return Scaffold(
      backgroundColor: _t.background,
      appBar: AppBar(
        backgroundColor: _t.boardBackground,
        title: Text(l.hexModeTitle, style: TextStyle(color: _t.hudText)),
        iconTheme: IconThemeData(color: _t.hudText),
        elevation: 0,
      ),
      body: state.isLoading && entries.isEmpty
          ? Center(child: CircularProgressIndicator(color: _t.exitCell))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                _HexModeHeader(theme: _t, subtitle: l.hexModeSubtitle),
                const SizedBox(height: 16),
                _HexProgressBar(entries: entries, theme: _t),
                const SizedBox(height: 8),
                _HexTrail(
                  entries: entries,
                  theme: _t,
                  playLabel: l.playButton,
                  comingSoonLabel: l.hexComingSoon,
                  onTapLevel: (i) => _playHex(entries, i),
                ),
                if (state.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(state.errorMessage!,
                        style: TextStyle(color: _t.primary)),
                  ),
              ],
            ),
    );
  }
}

/// Cabecera con el icono de panal y la nota que explica la mecánica de las 6
/// direcciones.
class _HexModeHeader extends StatelessWidget {
  final ThemeConfig theme;
  final String subtitle;
  const _HexModeHeader({required this.theme, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.hexagon, color: theme.exitCell, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            subtitle,
            style: TextStyle(
              color: theme.hudText.withValues(alpha: 0.7),
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

/// Barra fina de progreso de la campaña hex (espejo de la cuadrada).
class _HexProgressBar extends StatelessWidget {
  final List<LevelSelectEntry> entries;
  final ThemeConfig theme;
  const _HexProgressBar({required this.entries, required this.theme});

  @override
  Widget build(BuildContext context) {
    final total = entries.length;
    final done =
        entries.where((e) => e.status == LevelStatus.completed).length;
    final ratio = total == 0 ? 0.0 : done / total;

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: theme.emptyCell,
              valueColor: AlwaysStoppedAnimation<Color>(theme.exitCell),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$done/$total',
          style: TextStyle(
            color: theme.hudText.withValues(alpha: 0.7),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// Sendero serpenteante hex: espejo del `_CampaignTrail` cuadrado (misma onda
/// senoidal y camino pintado por detrás) con dos diferencias: sin botón de
/// leaderboard por nodo, y un nodo EXTRA "próximamente" al final del camino
/// (siempre discontinuo, no tappeable) como teaser de futuros niveles.
class _HexTrail extends StatelessWidget {
  final List<LevelSelectEntry> entries;
  final ThemeConfig theme;
  final String playLabel;
  final String comingSoonLabel;
  final void Function(int index) onTapLevel;

  const _HexTrail({
    required this.entries,
    required this.theme,
    required this.playLabel,
    required this.comingSoonLabel,
    required this.onTapLevel,
  });

  // Geometría del sendero (idéntica a la campaña cuadrada salvo _topPad: aquí
  // es mayor para que el marcador "JUGAR" del primer nivel — que se dibuja
  // por encima de su nodo — no invada la barra de progreso de arriba).
  static const double _vSpacing = 118;
  static const double _topPad = 100;
  static const double _bottomPad = 20;
  static const double _sizeCurrent = 84;
  static const double _sizeCompleted = 72;
  static const double _sizeLocked = 58;

  /// Corrimiento adicional a la izquierda del nodo "próximamente" para que la
  /// línea punteada que lo atraviesa quede mejor centrada en el círculo.
  static const double _comingSoonShiftLeft = 24;

  double _nodeSize(LevelStatus status, bool isCurrent) {
    if (isCurrent) return _sizeCurrent;
    if (status == LevelStatus.locked) return _sizeLocked;
    return _sizeCompleted;
  }

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

    // Nodos del sendero: los niveles + el teaser "próximamente" al final.
    final totalNodes = entries.length + 1;
    final currentIndex =
        entries.indexWhere((e) => e.status == LevelStatus.unlocked);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final midX = width / 2;
        final amplitude = math.min(width * 0.30, 120.0);

        final centers = <Offset>[
          for (var i = 0; i < totalNodes; i++)
            Offset(
              midX + amplitude * math.sin(i * math.pi / 2),
              _topPad + i * _vSpacing,
            ),
        ];
        // El nodo "próximamente" se corre un poco más a la izquierda; el
        // painter dibuja la línea hasta este mismo punto ajustado, así que
        // sigue terminando exactamente en el centro del círculo.
        centers[centers.length - 1] = Offset(
          centers.last.dx - _comingSoonShiftLeft,
          centers.last.dy,
        );

        final height =
            _topPad + (totalNodes - 1) * _vSpacing + _bottomPad + 40;

        // El tramo hacia el nodo "próximamente" se pinta discontinuo: para el
        // painter se comporta como un nodo bloqueado más.
        final statuses = [
          for (final e in entries) e.status,
          LevelStatus.locked,
        ];

        return SizedBox(
          width: width,
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _HexTrailPainter(
                    centers: centers,
                    statuses: statuses,
                    theme: theme,
                  ),
                ),
              ),
              if (currentIndex >= 0)
                Positioned(
                  left: centers[currentIndex].dx - 70,
                  top: centers[currentIndex].dy - _sizeCurrent / 2 - 34,
                  child: SizedBox(
                    width: 140,
                    child: Center(
                      child: _HexCurrentMarker(
                        theme: theme,
                        label: playLabel,
                      ),
                    ),
                  ),
                ),
              for (var i = 0; i < entries.length; i++)
                _positionedNode(i, centers[i], currentIndex == i),
              _positionedComingSoon(centers[totalNodes - 1]),
            ],
          ),
        );
      },
    );
  }

  Widget _positionedNode(int i, Offset center, bool isCurrent) {
    final entry = entries[i];
    final size = _nodeSize(entry.status, isCurrent);
    return Positioned(
      left: center.dx - size / 2,
      top: center.dy - size / 2,
      child: _HexTrailNode(
        key: HexLevelSelectScreen.hexTileKey(i + 1),
        entry: entry,
        number: i + 1,
        size: size,
        isCurrent: isCurrent,
        theme: theme,
        onTap: entry.isPlayable ? () => onTapLevel(i) : null,
      ),
    );
  }

  Widget _positionedComingSoon(Offset center) {
    const size = _sizeLocked;
    return Positioned(
      left: center.dx - size / 2,
      top: center.dy - size / 2,
      child: _ComingSoonNode(
        key: HexLevelSelectScreen.comingSoonTileKey,
        size: size,
        label: comingSoonLabel,
        theme: theme,
      ),
    );
  }
}

/// Chip "estás aquí" que apunta al siguiente nivel hex jugable.
class _HexCurrentMarker extends StatelessWidget {
  final ThemeConfig theme;
  final String label;
  const _HexCurrentMarker({required this.theme, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: theme.exitCell,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.play_arrow_rounded, size: 15, color: theme.onPrimary),
              const SizedBox(width: 3),
              Text(
                label,
                style: TextStyle(
                  color: theme.onPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        Icon(Icons.arrow_drop_down_rounded, size: 20, color: theme.exitCell),
      ],
    );
  }
}

/// Nodo del sendero hex: círculo con número/candado/check y estrellas debajo.
/// Mantiene `Icons.lock_rounded` (bloqueado), `Icons.check_rounded`
/// (completado) y `Icons.star_rounded` (estrellas) como contrato de test,
/// igual que la campaña cuadrada. Sin botón de leaderboard: niveles locales.
class _HexTrailNode extends StatelessWidget {
  final LevelSelectEntry entry;
  final int number;
  final double size;
  final bool isCurrent;
  final ThemeConfig theme;
  final VoidCallback? onTap;

  const _HexTrailNode({
    super.key,
    required this.entry,
    required this.number,
    required this.size,
    required this.isCurrent,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final locked = entry.status == LevelStatus.locked;
    final completed = entry.status == LevelStatus.completed;
    final accent = theme.exitCell;

    final Color fill = locked
        ? theme.emptyCell.withValues(alpha: 0.5)
        : completed
            ? accent
            : accent.withValues(alpha: 0.85);
    final Color border = locked
        ? theme.wallCell
        : completed
            ? accent
            : theme.onPrimary.withValues(alpha: 0.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: fill,
                border: Border.all(color: border, width: 3),
                boxShadow: [
                  if (isCurrent)
                    BoxShadow(
                      color: accent.withValues(alpha: 0.55),
                      blurRadius: 18,
                      spreadRadius: 2,
                    )
                  else if (!locked)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                ],
              ),
              alignment: Alignment.center,
              child: locked
                  ? Icon(
                      Icons.lock_rounded,
                      size: size * 0.42,
                      color: theme.hudText.withValues(alpha: 0.4),
                    )
                  : completed
                      ? Icon(
                          Icons.check_rounded,
                          size: size * 0.5,
                          color: theme.onPrimary,
                        )
                      : Text(
                          '$number',
                          style: TextStyle(
                            color: theme.onPrimary,
                            fontSize: size * 0.36,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        _HexStarsRow(stars: entry.stars, dimmed: locked, theme: theme),
      ],
    );
  }
}

/// Nodo teaser "en construcción" al final del sendero: círculo apagado con
/// borde discontinuo, icono de obras y la etiqueta "próximamente". NO es
/// tappeable: solo anuncia que vendrán más niveles.
class _ComingSoonNode extends StatelessWidget {
  final double size;
  final String label;
  final ThemeConfig theme;

  const _ComingSoonNode({
    super.key,
    required this.size,
    required this.label,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          painter: _DashedCirclePainter(
            color: theme.hudText.withValues(alpha: 0.35),
          ),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.emptyCell.withValues(alpha: 0.35),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.construction,
              size: size * 0.42,
              color: theme.hudText.withValues(alpha: 0.4),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: theme.hudText.withValues(alpha: 0.45),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

/// Borde circular discontinuo del nodo "próximamente".
class _DashedCirclePainter extends CustomPainter {
  final Color color;
  _DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const dashCount = 14;
    const sweep = math.pi * 2 / dashCount;
    for (var i = 0; i < dashCount; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * sweep,
        sweep * 0.55,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter old) => old.color != color;
}

/// Pinta el camino que une los nodos del sendero hex: sólido/acento hacia
/// nodos ya alcanzados, punteado/apagado hacia bloqueados y hacia el nodo
/// "próximamente" (espejo del painter de la campaña cuadrada con el acento
/// ámbar del modo hex).
class _HexTrailPainter extends CustomPainter {
  final List<Offset> centers;
  final List<LevelStatus> statuses;
  final ThemeConfig theme;

  _HexTrailPainter({
    required this.centers,
    required this.statuses,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (centers.length < 2) return;

    final active = Paint()
      ..color = theme.exitCell.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    final inactive = Paint()
      ..color = theme.wallCell.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    for (var i = 1; i < centers.length; i++) {
      final a = centers[i - 1];
      final b = centers[i];
      final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(mid.dx, a.dy + (b.dy - a.dy) * 0.35, b.dx, b.dy);

      final reached = statuses[i] != LevelStatus.locked;
      if (reached) {
        canvas.drawPath(path, active);
      } else {
        _drawDashed(canvas, path, inactive);
      }
    }
  }

  void _drawDashed(Canvas canvas, Path path, Paint paint) {
    const dash = 9.0;
    const gap = 7.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = math.min(distance + dash, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_HexTrailPainter old) =>
      old.centers != centers || old.statuses != statuses;
}

class _HexStarsRow extends StatelessWidget {
  final int stars;
  final bool dimmed;
  final ThemeConfig theme;
  const _HexStarsRow({
    required this.stars,
    required this.theme,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final earned = i < stars;
        return Icon(
          earned ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 15,
          color: earned
              ? theme.exitCell
              : theme.hudText.withValues(alpha: dimmed ? 0.1 : 0.25),
        );
      }),
    );
  }
}
