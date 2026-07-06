import 'package:arrow_maze/application/builders/level_definition.dart';
import 'package:arrow_maze/application/dtos/level_spec.dart';

/// Puerto de generación de niveles con IA.
/// La implementación concreta (Groq, OpenAI, local…) vive en infraestructura.
abstract interface class ILevelGeneratorService {
  /// Genera un [LevelDefinition] válido a partir de los parámetros dados.
  /// Lanza [LevelGenerationException] si la IA devuelve un JSON no parseable.
  Future<LevelDefinition> generate(LevelSpec spec);
}

class LevelGenerationException implements Exception {
  final String message;
  const LevelGenerationException(this.message);

  @override
  String toString() => 'LevelGenerationException: $message';
}
