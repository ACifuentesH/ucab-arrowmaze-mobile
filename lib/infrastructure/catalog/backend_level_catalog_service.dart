import 'package:arrow_maze/application/dtos/level_preview.dart';
import 'package:arrow_maze/application/enums/level_source.dart';
import 'package:arrow_maze/application/ports/i_api_client.dart';
import 'package:arrow_maze/application/ports/i_level_catalog_service.dart';

/// Catálogo de niveles servido por el backend (GET /levels).
///
/// Los niveles del backend son la campaña oficial (misma identidad que los
/// bundleados en assets), por eso salen con [LevelSource.asset]: la UI y la
/// regla de progresión los tratan exactamente igual. No captura errores — el
/// decorador [RemoteFirstLevelCatalogService] decide qué hacer si la red falla.
class BackendLevelCatalogService implements ILevelCatalogService {
  final IApiClient _api;

  const BackendLevelCatalogService(this._api);

  @override
  Future<List<LevelPreview>> getLevels() async {
    final defs = await _api.getLevels();
    return defs
        .map((d) => LevelPreview.fromDefinition(d, source: LevelSource.asset))
        .toList();
  }
}
