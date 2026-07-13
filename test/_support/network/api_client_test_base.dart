/// Base y reglas para pruebas de la capa de red.
///
/// **Regla estricta (State over Interaction):**
/// - Los tests del cliente API evalúan **entradas y salidas de [IApiClient]**.
/// - Se simulan respuestas JSON del backend (envelope `{ success, data, message }`).
/// - **Prohibido** verificar detalles de implementación interna (interceptores,
///   orden de llamadas privadas, estructura del adaptador Dio, etc.).
/// - Usar Given/When/Then vía Testing APIs en `test/_support/apis/`.
library;

/// Clave de documentación — los tests concretos viven en
/// `test/infrastructure/api/api_client_test.dart`,
/// `test/infrastructure/repositories/auth_repository_test.dart` y
/// `test/presentation/view_models/auth/auth_view_model_test.dart`.
const networkTestBaseVersion = 1;
