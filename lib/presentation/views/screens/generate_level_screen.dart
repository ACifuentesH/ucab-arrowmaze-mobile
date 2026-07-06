import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:arrow_maze/application/dtos/level_preview.dart';
import 'package:arrow_maze/application/enums/difficulty.dart';
import 'package:arrow_maze/application/enums/shape_name.dart';
import 'package:arrow_maze/presentation/view_models/generate_level_state.dart';
import 'package:arrow_maze/config/providers.dart';
import 'package:arrow_maze/presentation/views/screens/game_screen.dart';

class GenerateLevelScreen extends ConsumerStatefulWidget {
  const GenerateLevelScreen({super.key});

  @override
  ConsumerState<GenerateLevelScreen> createState() =>
      _GenerateLevelScreenState();
}

class _GenerateLevelScreenState extends ConsumerState<GenerateLevelScreen> {
  final _shapeController = TextEditingController();

  @override
  void dispose() {
    _shapeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gs = ref.watch(generateLevelViewModelProvider);
    final notifier = ref.read(generateLevelViewModelProvider.notifier);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Level Builder'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Shape name ──────────────────────────────────────────────────
            const _SectionLabel('Forma del tablero'),
            const SizedBox(height: 8),
            TextField(
              controller: _shapeController,
              decoration: InputDecoration(
                hintText: 'Escribe cualquier forma (gato, nave espacial…)',
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.edit_outlined),
              ),
              onChanged: notifier.setShapeName,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: ShapeSuggestions.all
                  .map(
                    (s) => ActionChip(
                      label: Text(s),
                      onPressed: () {
                        _shapeController.text = s;
                        notifier.setShapeName(s);
                      },
                    ),
                  )
                  .toList(),
            ),

            const SizedBox(height: 24),

            // ── Difficulty ──────────────────────────────────────────────────
            const _SectionLabel('Dificultad'),
            const SizedBox(height: 10),
            SegmentedButton<Difficulty>(
              segments: const [
                ButtonSegment(value: Difficulty.easy, label: Text('Fácil')),
                ButtonSegment(value: Difficulty.medium, label: Text('Media')),
                ButtonSegment(value: Difficulty.hard, label: Text('Difícil')),
              ],
              selected: {gs.difficulty},
              onSelectionChanged: (s) => notifier.setDifficulty(s.first),
              style: ButtonStyle(
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),
            Text(
              _difficultyDesc(gs.difficulty),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: colors.onSurface.withValues(alpha: 0.6)),
            ),

            const SizedBox(height: 24),

            // ── Time limit ──────────────────────────────────────────────────
            Row(
              children: [
                const _SectionLabel('Límite de tiempo'),
                const Spacer(),
                Switch(
                  value: gs.hasTimeLimit,
                  onChanged: notifier.setHasTimeLimit,
                ),
              ],
            ),
            if (gs.hasTimeLimit) ...[
              Slider(
                value: gs.timeLimitSeconds.toDouble(),
                min: 30,
                max: 300,
                divisions: 27,
                label: '${gs.timeLimitSeconds}s',
                onChanged: (v) => notifier.setTimeLimitSeconds(v.round()),
              ),
              Text(
                '${gs.timeLimitSeconds} segundos para completar el nivel',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurface.withValues(alpha: 0.6),
                    ),
              ),
            ],

            const SizedBox(height: 32),

            // ── Generate button ─────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: gs.canGenerate ? notifier.generate : null,
                icon: gs.status == GenerateStatus.loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(
                  gs.status == GenerateStatus.loading
                      ? 'Generando…'
                      : 'Generar nivel',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),

            // ── Status feedback ─────────────────────────────────────────────
            if (gs.status == GenerateStatus.error) ...[
              const SizedBox(height: 20),
              _ErrorCard(gs.errorMessage ?? 'Error desconocido'),
            ],

            if (gs.status == GenerateStatus.success && gs.result != null) ...[
              const SizedBox(height: 24),
              _SuccessCard(
                preview: gs.result!,
                onPlay: () => _navigateToPlay(context, ref, gs.result!.id),
                onGenerateAnother: notifier.reset,
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToPlay(
      BuildContext context, WidgetRef ref, String levelId) async {
    await ref.read(gameViewModelProvider.notifier).loadLevel(levelId);
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const GameScreen()),
    );
  }

  String _difficultyDesc(Difficulty d) => switch (d) {
        Difficulty.easy => '5 vidas • Sin penalización de tiempo en puntaje',
        Difficulty.medium => '3 vidas • Multiplicador ×1.5 en puntaje',
        Difficulty.hard => '1 vida • Multiplicador ×2.0 en puntaje',
      };
}

// ── Helpers ─────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard(this.message);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessCard extends StatelessWidget {
  final LevelPreview preview;
  final VoidCallback onPlay;
  final VoidCallback onGenerateAnother;

  const _SuccessCard({
    required this.preview,
    required this.onPlay,
    required this.onGenerateAnother,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: colors.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '¡Nivel generado y guardado!',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${preview.name} • ${preview.arrowCount} flechas • '
            '${preview.cells.length} celdas',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.7),
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onGenerateAnother,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Generar otro'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onPlay,
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('Jugar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

