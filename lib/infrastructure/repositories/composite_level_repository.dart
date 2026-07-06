import 'package:arrow_maze/domain/aggregates/board.dart';
import 'package:arrow_maze/domain/ports/i_level_repository.dart';
import 'package:arrow_maze/domain/value_objects/level_id.dart';

/// Patrón Chain of Responsibility: intenta cargar el nivel de cada repositorio
/// en orden hasta que uno tenga éxito. Si ninguno lo encuentra, relanza la
/// última excepción.
///
/// Orden por defecto: AssetJsonLevelRepository → GeneratedJsonLevelRepository.
/// Agregar fuentes remotas en el futuro solo requiere añadir un elemento a la
/// lista en el provider — el resto del código no cambia.
class CompositeLevelRepository implements ILevelRepository {
  final List<ILevelRepository> _repos;

  const CompositeLevelRepository(this._repos);

  @override
  Future<Board> loadLevel(LevelId id) async {
    Object? last;
    for (final repo in _repos) {
      try {
        return await repo.loadLevel(id);
      } catch (e) {
        // FlutterError (asset not found) extends Error, not Exception —
        // catch everything and try the next repo.
        last = e;
      }
    }
    throw last ?? Exception('Level ${id.value} not found');
  }

  @override
  Future<void> saveProgress(LevelId id, int score) async {
    // Delegates to all repos; each decides whether it owns the level.
    for (final repo in _repos) {
      await repo.saveProgress(id, score);
    }
  }
}
