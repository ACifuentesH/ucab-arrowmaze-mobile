import 'package:arrow_maze/application/builders/level_definition.dart';
import 'package:arrow_maze/application/dtos/level_spec.dart';
import 'package:arrow_maze/application/ports/i_level_generator_service.dart';

/// Fake de ILevelGeneratorService: devuelve resultados encolados en orden,
/// permitiendo simular reintentos (inválido → válido) sin red ni IA real.
class FakeLevelGeneratorService implements ILevelGeneratorService {
  final List<Object> _queue = [];
  int callCount = 0;

  /// Encola un resultado exitoso.
  void enqueueLevel(LevelDefinition definition) => _queue.add(definition);

  /// Encola un fallo de generación.
  void enqueueFailure([String message = 'AI produced invalid JSON']) =>
      _queue.add(LevelGenerationException(message));

  @override
  Future<LevelDefinition> generate(LevelSpec spec) async {
    callCount++;
    if (_queue.isEmpty) {
      throw const LevelGenerationException('FakeLevelGenerator queue empty');
    }
    final next = _queue.removeAt(0);
    if (next is LevelGenerationException) throw next;
    return next as LevelDefinition;
  }
}
