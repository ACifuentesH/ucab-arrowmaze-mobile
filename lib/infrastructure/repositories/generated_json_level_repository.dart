import 'package:arrow_maze/application/builders/level_builder.dart';
import 'package:arrow_maze/application/ports/i_generated_level_repository.dart';
import 'package:arrow_maze/domain/aggregates/board.dart';
import 'package:arrow_maze/domain/ports/i_level_repository.dart';
import 'package:arrow_maze/domain/value_objects/level_id.dart';

/// Adapta [IGeneratedLevelRepository] (application port) al puerto de dominio
/// [ILevelRepository], permitiendo que el GameViewModel cargue niveles
/// generados por IA exactamente igual que los niveles bundleados.
///
/// Patrón Adapter: convierte la interfaz de persistencia de definiciones
/// en la interfaz de carga de Boards que espera el dominio.
class GeneratedJsonLevelRepository implements ILevelRepository {
  final IGeneratedLevelRepository _source;
  final LevelBuilder _builder;

  const GeneratedJsonLevelRepository({
    required IGeneratedLevelRepository source,
    required LevelBuilder builder,
  })  : _source = source,
        _builder = builder;

  @override
  Future<Board> loadLevel(LevelId id) async {
    final def = await _source.findById(id.value);
    if (def == null) throw Exception('Generated level not found: ${id.value}');
    return _builder.build(def);
  }

  @override
  Future<void> saveProgress(LevelId id, int score) async {}
}
