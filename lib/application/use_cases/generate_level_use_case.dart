import 'package:arrow_maze/application/builders/level_builder.dart';
import 'package:arrow_maze/application/builders/level_definition.dart';
import 'package:arrow_maze/application/dtos/level_preview.dart';
import 'package:arrow_maze/application/dtos/level_spec.dart';
import 'package:arrow_maze/application/enums/level_source.dart';
import 'package:arrow_maze/application/ports/i_generated_level_repository.dart';
import 'package:arrow_maze/application/ports/i_level_generator_service.dart';
import 'package:arrow_maze/domain/ports/i_arrow_placer.dart';

/// Orquesta la generación de un nivel con IA, su validación y su persistencia.
///
/// La IA solo aporta la silueta (`cells`); las flechas las coloca
/// [IArrowPlacer], un algoritmo determinista del dominio — así se garantiza
/// que el tablero final sea siempre resoluble y sin flechas solapadas, sin
/// depender de qué tan bien el modelo respete esas reglas.
class GenerateLevelUseCase {
  final ILevelGeneratorService _generator;
  final IGeneratedLevelRepository _repository;
  final LevelBuilder _builder;
  final IArrowPlacer _arrowPlacer;

  const GenerateLevelUseCase({
    required ILevelGeneratorService generator,
    required IGeneratedLevelRepository repository,
    required LevelBuilder builder,
    required IArrowPlacer arrowPlacer,
  })  : _generator = generator,
        _repository = repository,
        _builder = builder,
        _arrowPlacer = arrowPlacer;

  /// Devuelve un [LevelPreview] listo para mostrar en el catálogo.
  /// Reintenta una vez automáticamente si la silueta generada no admite
  /// suficientes flechas o el nivel resultante es inválido.
  /// Lanza [LevelGenerationException] si ambos intentos fallan.
  Future<LevelPreview> execute(LevelSpec spec) async {
    LevelGenerationException? lastError;

    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final aiDefinition = await _generator.generate(spec);
        final arrows = _arrowPlacer.place(aiDefinition.cells);
        if (arrows.isEmpty) {
          throw LevelGenerationException(
            'La forma generada no tiene espacio para ninguna flecha. '
            'Intento ${attempt + 1}/2.',
          );
        }

        final definition = LevelDefinition(
          id: aiDefinition.id,
          name: aiDefinition.name,
          lives: aiDefinition.lives,
          parMoves: aiDefinition.parMoves,
          timeLimitSeconds: aiDefinition.timeLimitSeconds,
          difficulty: aiDefinition.difficulty,
          cells: aiDefinition.cells,
          arrows: arrows,
        );

        try {
          _builder.build(definition);
        } on ArgumentError catch (e) {
          throw LevelGenerationException(
            'El nivel generado no pasó la validación: ${e.message}. '
            'Intento ${attempt + 1}/2.',
          );
        }
        await _repository.save(definition);
        return LevelPreview.fromDefinition(definition, source: LevelSource.generated);
      } on LevelGenerationException catch (e) {
        lastError = e;
        // Loop continues to next attempt
      }
    }

    throw lastError ??
        const LevelGenerationException(
          'Error desconocido al generar el nivel.',
        );
  }
}
