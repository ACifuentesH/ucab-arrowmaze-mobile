import 'package:arrow_maze/application/dtos/level_preview.dart';
import 'package:arrow_maze/application/ports/i_level_catalog_service.dart';

/// Decorador "contenido remoto, orden local" sobre dos catálogos de campaña.
///
/// El backend es la fuente de verdad del CONTENIDO de los niveles, pero no de
/// la SECUENCIA de la campaña: GET /levels devuelve orden lexicográfico
/// (level_1, level_10, level_11…, level_2…), y la regla de desbloqueo de
/// GetLevelSelectionUseCase encadena niveles en el orden del catálogo — usarlo
/// crudo desbloquearía la campaña en el orden equivocado. El catálogo [local]
/// (assets/levels/manifest.json) sigue siendo la autoridad del orden.
///
/// Reglas de fusión:
///  - id presente en ambos → gana la versión remota (contenido actualizable
///    desde el backend sin republicar la app), en la posición local.
///  - id solo local (backend incompleto/sin seed) → se sirve el bundleado.
///  - id solo remoto (nivel nuevo publicado en el backend) → se anexa al
///    final de la campaña.
///  - backend inaccesible o vacío → campaña bundleada tal cual (offline-first:
///    el juego nunca depende de la red para funcionar).
class RemoteFirstLevelCatalogService implements ILevelCatalogService {
  final ILevelCatalogService _remote;
  final ILevelCatalogService _local;

  const RemoteFirstLevelCatalogService({
    required ILevelCatalogService remote,
    required ILevelCatalogService local,
  })  : _remote = remote,
        _local = local;

  @override
  Future<List<LevelPreview>> getLevels() async {
    final local = await _local.getLevels();

    List<LevelPreview> remote;
    try {
      remote = await _remote.getLevels();
    } catch (_) {
      return local;
    }
    if (remote.isEmpty) return local;

    final remoteById = {for (final p in remote) p.id: p};
    return [
      for (final p in local) remoteById.remove(p.id) ?? p,
      ...remoteById.values,
    ];
  }
}
