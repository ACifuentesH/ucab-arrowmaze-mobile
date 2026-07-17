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
import 'package:arrow_maze/presentation/views/screens/generate_level_screen.dart';
import 'package:arrow_maze/presentation/views/screens/leaderboard_screen.dart';
import 'package:arrow_maze/presentation/views/screens/login_screen.dart';

/// Pantalla de seleccion: la campa?a se dibuja como un sendero progresivo
/// (nodos encadenados que serpentean hacia abajo, estilo lobby de juego de
/// puzzles) + una lista secundaria de niveles generados con IA.
class LevelSelectScreen extends ConsumerStatefulWidget {
  const LevelSelectScreen({super.key});

  /// Key estable del nodo de campa?a n?mero [number] (1-based) para las
  /// pruebas de navegaci?n/interacci?n.
  static Key campaignTileKey(int number) => Key('campaign_tile_$number');

  @override
  ConsumerState<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends ConsumerState<LevelSelectScreen> {
  static const ThemeConfig _t = ThemeConfig.dark;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(levelSelectViewModelProvider.notifier).load(),
    );
  }

  Future<void> _playCampaign(List<LevelSelectEntry> campaign, int index) async {
    // La cola arranca en el nivel tocado; los siguientes se van
    // desbloqueando a medida que se completan.
    final queue = campaign
        .skip(index)
        .map((e) => PlayableLevel.fromPreview(e.preview))
        .toList();
    await ref.read(gameViewModelProvider.notifier).startCampaign(queue);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const GameScreen()),
    );
    if (mounted) ref.read(levelSelectViewModelProvider.notifier).load();
  }

  Future<void> _playGenerated(LevelSelectEntry entry) async {
    await ref.read(gameViewModelProvider.notifier).loadLevel(
          entry.preview.id,
          difficulty: entry.preview.difficulty,
          levelName: entry.preview.name,
        );
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const GameScreen()),
    );
    if (mounted) ref.read(levelSelectViewModelProvider.notifier).load();
  }

  void _openLeaderboard(String levelId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LeaderboardScreen(levelId: levelId),
      ),
    );
  }

  /// El backend exige sesión para `POST /levels/generate` (JWT): si no hay
  /// una activa, se pide login antes de entrar al builder en vez de dejar
  /// que la generación falle con un error técnico.
  Future<void> _goToCreative() async {
    final auth = ref.read(authViewModelProvider);
    if (!auth.isAuthenticated) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      if (!mounted) return;
      if (!ref.read(authViewModelProvider).isAuthenticated) return;
    }
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const GenerateLevelScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final state = ref.watch(levelSelectViewModelProvider);
    final campaign = state.campaign;
    final generated = state.generated;

    return Scaffold(
      backgroundColor: _t.background,
      appBar: AppBar(
        backgroundColor: _t.boardBackground,
        title: Text(l.levelsTitle, style: TextStyle(color: _t.hudText)),
        iconTheme: IconThemeData(color: _t.hudText),
        elevation: 0,
      ),
      body: state.isLoading && state.entries.isEmpty
          ? Center(child: CircularProgressIndicator(color: _t.primary))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                _CreativeButton(
                  theme: _t,
                  label: l.creativeButton,
                  onTap: _goToCreative,
                ),
                const SizedBox(height: 24),
                _SectionTitle(l.campaignSection, theme: _t),
                const SizedBox(height: 8),
                _CampaignProgressBar(campaign: campaign, theme: _t),
                const SizedBox(height: 8),
                _CampaignTrail(
                  campaign: campaign,
                  theme: _t,
                  playLabel: l.playButton,
                  onTapLevel: (i) => _playCampaign(campaign, i),
                  onLeaderboard: (i) =>
                      _openLeaderboard(campaign[i].preview.id),
                ),
                if (generated.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  _SectionTitle(l.aiGeneratedSection, theme: _t),
                  const SizedBox(height: 12),
                  ...generated.map((entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _GeneratedTile(
                          entry: entry,
                          theme: _t,
                          label: l.levelMeta(
                            entry.preview.arrowCount,
                            entry.preview.difficulty.name,
                          ),
                          onTap: () => _playGenerated(entry),
                          onLeaderboard: () =>
                              _openLeaderboard(entry.preview.id),
                        ),
                      )),
                ],
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

class _SectionTitle extends StatelessWidget {
  final String text;
  final ThemeConfig theme;
  const _SectionTitle(this.text, {required this.theme});

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: TextStyle(
          color: theme.hudText.withValues(alpha: 0.7),
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      );
}

/// CTA para abrir el generador de niveles con IA (map builder). Vive junto a
/// la campaña, no en Home: es donde el jugador ya está eligiendo qué jugar.
class _CreativeButton extends StatelessWidget {
  final ThemeConfig theme;
  final String label;
  final VoidCallback onTap;

  const _CreativeButton({
    required this.theme,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: theme.primary.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.primary.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Icon(Icons.auto_awesome, color: theme.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: theme.hudText,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: theme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Barra fina de progreso global de la campa?a (niveles completados / total).
class _CampaignProgressBar extends StatelessWidget {
  final List<LevelSelectEntry> campaign;
  final ThemeConfig theme;
  const _CampaignProgressBar({required this.campaign, required this.theme});

  @override
  Widget build(BuildContext context) {
    final total = campaign.length;
    final done =
        campaign.where((e) => e.status == LevelStatus.completed).length;
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

/// Sendero serpenteante de la campa?a: coloca cada nodo siguiendo una onda
/// senoidal y dibuja el camino que los conecta por detr?s.
class _CampaignTrail extends StatelessWidget {
  final List<LevelSelectEntry> campaign;
  final ThemeConfig theme;
  final String playLabel;
  final void Function(int index) onTapLevel;
  final void Function(int index) onLeaderboard;

  const _CampaignTrail({
    required this.campaign,
    required this.theme,
    required this.playLabel,
    required this.onTapLevel,
    required this.onLeaderboard,
  });

  // Geometr?a del sendero.
  static const double _vSpacing = 118; // separaci?n vertical entre nodos
  static const double _topPad = 44; // hueco para el marcador "est?s aqu?"
  static const double _bottomPad = 20;
  static const double _sizeCurrent = 84;
  static const double _sizeCompleted = 72;
  static const double _sizeLocked = 58;

  double _nodeSize(LevelStatus status, bool isCurrent) {
    if (isCurrent) return _sizeCurrent;
    if (status == LevelStatus.locked) return _sizeLocked;
    return _sizeCompleted;
  }

  @override
  Widget build(BuildContext context) {
    if (campaign.isEmpty) return const SizedBox.shrink();

    // El "nodo actual" es el primer nivel jugable a?n sin completar: ah? va el
    // marcador de "est?s aqu?".
    final currentIndex =
        campaign.indexWhere((e) => e.status == LevelStatus.unlocked);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final midX = width / 2;
        final amplitude = math.min(width * 0.30, 120.0);

        // Centro de cada nodo (onda senoidal ? serpenteo suave).
        final centers = <Offset>[
          for (var i = 0; i < campaign.length; i++)
            Offset(
              midX + amplitude * math.sin(i * math.pi / 2),
              _topPad + i * _vSpacing,
            ),
        ];

        final height =
            _topPad + (campaign.length - 1) * _vSpacing + _bottomPad + 40;

        return SizedBox(
          width: width,
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Camino que conecta los nodos (capa de fondo).
              Positioned.fill(
                child: CustomPaint(
                  painter: _TrailPainter(
                    centers: centers,
                    statuses: [for (final e in campaign) e.status],
                    theme: theme,
                  ),
                ),
              ),
              // Marcador "est?s aqu?" sobre el nodo actual.
              if (currentIndex >= 0)
                Positioned(
                  left: centers[currentIndex].dx - 70,
                  top: centers[currentIndex].dy -
                      _sizeCurrent / 2 -
                      34,
                  child: SizedBox(
                    width: 140,
                    child: Center(
                      child: _CurrentMarker(theme: theme, label: playLabel),
                    ),
                  ),
                ),
              // Nodos.
              for (var i = 0; i < campaign.length; i++)
                _positionedNode(i, centers[i], currentIndex == i),
            ],
          ),
        );
      },
    );
  }

  Widget _positionedNode(int i, Offset center, bool isCurrent) {
    final entry = campaign[i];
    final size = _nodeSize(entry.status, isCurrent);
    return Positioned(
      left: center.dx - size / 2,
      top: center.dy - size / 2,
      child: _CampaignNode(
        key: LevelSelectScreen.campaignTileKey(i + 1),
        entry: entry,
        number: i + 1,
        size: size,
        isCurrent: isCurrent,
        theme: theme,
        onTap: entry.isPlayable ? () => onTapLevel(i) : null,
        onLeaderboard: () => onLeaderboard(i),
      ),
    );
  }
}

/// Chip "est?s aqu?" que apunta al siguiente nivel jugable.
class _CurrentMarker extends StatelessWidget {
  final ThemeConfig theme;
  final String label;
  const _CurrentMarker({required this.theme, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: theme.primary,
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
        Icon(Icons.arrow_drop_down_rounded, size: 20, color: theme.primary),
      ],
    );
  }
}

/// Un nodo del sendero. C?rculo con n?mero/candado, borde seg?n estado y una
/// fila de estrellas colgando debajo. Mantiene `Icons.lock_rounded` para
/// bloqueados y `Icons.star_rounded` para estrellas ganadas (contrato de test).
class _CampaignNode extends StatelessWidget {
  final LevelSelectEntry entry;
  final int number;
  final double size;
  final bool isCurrent;
  final ThemeConfig theme;
  final VoidCallback? onTap;
  final VoidCallback onLeaderboard;

  const _CampaignNode({
    super.key,
    required this.entry,
    required this.number,
    required this.size,
    required this.isCurrent,
    required this.theme,
    required this.onTap,
    required this.onLeaderboard,
  });

  @override
  Widget build(BuildContext context) {
    final locked = entry.status == LevelStatus.locked;
    final completed = entry.status == LevelStatus.completed;

    final Color fill = locked
        ? theme.emptyCell.withValues(alpha: 0.5)
        : completed
            ? theme.exitCell
            : theme.primary;
    final Color border = locked
        ? theme.wallCell
        : completed
            ? theme.exitCell
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
                      color: theme.primary.withValues(alpha: 0.55),
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
        _StarsRow(stars: entry.stars, dimmed: locked, theme: theme),
        IconButton(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          tooltip: 'Clasificacion',
          icon: Icon(
            Icons.emoji_events,
            size: 18,
            color: locked
                ? theme.hudText.withValues(alpha: 0.25)
                : theme.exitCell,
          ),
          onPressed: onLeaderboard,
        ),
      ],
    );
  }
}

class _StarsRow extends StatelessWidget {
  final int stars;
  final bool dimmed;
  final ThemeConfig theme;
  const _StarsRow({
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

/// Pinta el camino serpenteante que une los centros de los nodos. Los tramos
/// que llegan a un nodo desbloqueado/completado se dibujan s?lidos y en color
/// de acento; los que llegan a un nodo bloqueado, punteados y apagados.
class _TrailPainter extends CustomPainter {
  final List<Offset> centers;
  final List<LevelStatus> statuses;
  final ThemeConfig theme;

  _TrailPainter({
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
      // Curva suave: control en el punto medio con un peque?o desv?o.
      final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(mid.dx, a.dy + (b.dy - a.dy) * 0.35, b.dx, b.dy);

      // El tramo est? "recorrido" si el nodo destino ya es jugable.
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
  bool shouldRepaint(_TrailPainter old) =>
      old.centers != centers || old.statuses != statuses;
}

class _GeneratedTile extends StatelessWidget {
  final LevelSelectEntry entry;
  final ThemeConfig theme;
  final String label;
  final VoidCallback onTap;
  final VoidCallback onLeaderboard;

  const _GeneratedTile({
    required this.entry,
    required this.theme,
    required this.label,
    required this.onTap,
    required this.onLeaderboard,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: theme.emptyCell,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.auto_awesome, color: theme.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.preview.name,
                        style: TextStyle(
                            color: theme.hudText,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: TextStyle(
                          color: theme.hudText.withValues(alpha: 0.6),
                          fontSize: 12),
                    ),
                  ],
                ),
              ),
              _StarsRow(stars: entry.stars, theme: theme),
              IconButton(
                tooltip: 'Clasificaci?n',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                icon: Icon(Icons.emoji_events, color: theme.exitCell, size: 22),
                onPressed: onLeaderboard,
              ),
              Icon(Icons.chevron_right, color: theme.primary),
            ],
          ),
        ),
      ),
    );
  }
}
