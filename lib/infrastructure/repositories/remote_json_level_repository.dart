import 'package:arrow_maze/application/builders/level_builder.dart';
import 'package:arrow_maze/application/ports/i_api_client.dart';
import 'package:arrow_maze/domain/aggregates/board.dart';
import 'package:arrow_maze/domain/ports/i_level_repository.dart';
import 'package:arrow_maze/domain/value_objects/level_id.dart';

/// Adapter del puerto de dominio [ILevelRepository] sobre GET /levels/:id.
///
/// Primer eslabón de la cadena de repositorios: si el backend tiene el nivel,
/// esa versión gana (fuente de verdad del contenido). Cualquier fallo — 404
/// para ids que solo existen localmente (generados), red caída, 5xx — se
/// propaga para que ChainedLevelRepository continúe con la siguiente fuente.
class RemoteJsonLevelRepository implements ILevelRepository {
  final IApiClient _api;
  final LevelBuilder _builder;

  const RemoteJsonLevelRepository({
    required IApiClient api,
    required LevelBuilder builder,
  })  : _api = api,
        _builder = builder;

  @override
  Future<Board> loadLevel(LevelId id) async {
    final definition = await _api.getLevelById(id.value);
    return _builder.build(definition);
  }

  @override
  Future<void> saveProgress(LevelId id, int score) async {
    // El progreso viaja por PUT /progress (ProgressSyncCoordinator), no por
    // este repositorio.
  }
}
