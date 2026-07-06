import 'package:arrow_maze/application/builders/level_builder.dart';
import 'package:arrow_maze/application/dtos/level_preview.dart';
import 'package:arrow_maze/application/dtos/level_spec.dart';
import 'package:arrow_maze/application/enums/level_source.dart';
import 'package:arrow_maze/application/ports/i_generated_level_repository.dart';
import 'package:arrow_maze/application/ports/i_level_generator_service.dart';

/// Orquesta la generación de un nivel con IA, su validación y su persistencia.
class GenerateLevelUseCase {
  final ILevelGeneratorService _generator;
  final IGeneratedLevelRepository _repository;
  final LevelBuilder _builder;

  const GenerateLevelUseCase({
    required ILevelGeneratorService generator,
    required IGeneratedLevelRepository repository,
    required LevelBuilder builder,
  })  : _generator = generator,
        _repository = repository,
        _builder = builder;

  /// Devuelve un [LevelPreview] listo para mostrar en el catálogo.
  /// Reintenta una vez automáticamente si la IA produce un nivel inválido.
  /// Lanza [LevelGenerationException] si ambos intentos fallan.
  Future<LevelPreview> execute(LevelSpec spec) async {
    LevelGenerationException? lastError;

    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final definition = await _generator.generate(spec);
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
