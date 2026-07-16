import 'package:arrow_maze/application/builders/level_definition.dart';
import 'package:arrow_maze/application/dtos/level_spec.dart';
import 'package:arrow_maze/application/errors/api_error.dart';
import 'package:arrow_maze/application/ports/i_api_client.dart';
import 'package:arrow_maze/application/ports/i_level_generator_service.dart';

/// Adaptador de infraestructura que genera niveles con IA delegando en el
/// backend (`POST /levels/generate`), que a su vez llama al LLM.
///
/// El frontend nunca ve el proveedor de IA ni ninguna API key: sólo conoce
/// [IApiClient] (puerto de aplicación). Reemplaza al antiguo
/// `GroqLevelGeneratorService`, que llamaba a Groq directamente desde el
/// cliente — una violación de capas (infraestructura de IA no debe vivir en
/// el frontend) que quedó cerrada al implementarse el mismo caso de uso en
/// el backend (Clean Architecture + DDD, puerto `ILevelGenerator`).
class ApiLevelGeneratorService implements ILevelGeneratorService {
  final IApiClient _apiClient;

  ApiLevelGeneratorService({required IApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<LevelDefinition> generate(LevelSpec spec) async {
    try {
      return await _apiClient.generateLevel(spec);
    } on UnauthorizedError {
      throw const LevelGenerationException(
        'Inicia sesión para generar niveles con IA.',
      );
    } on ApiError catch (e) {
      throw LevelGenerationException(e.message);
    }
  }
}
