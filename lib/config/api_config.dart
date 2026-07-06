/// Configuración del backend. La URL se inyecta en build/run:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
/// Default: backend local (docs/backend-context.md §7).
abstract final class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );
}
