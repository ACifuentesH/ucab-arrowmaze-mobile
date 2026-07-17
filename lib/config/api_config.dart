/// Configuración del backend. La URL se inyecta en build/run:
///   flutter run --dart-define=API_BASE_URL=https://balanced-hope-production-96ef.up.railway.app
/// Default: backend desplegado en Railway.
abstract final class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://balanced-hope-production-96ef.up.railway.app',
  );
}
