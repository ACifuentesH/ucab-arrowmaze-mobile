/// Cliente HTTP genérico hacia ucab-arrowmaze-api (DIP).
///
/// Contratos:
///  - Envelope `{ success, data, message }` resuelto por la implementación.
///  - Los métodos devuelven el contenido de `data` tipado como [dynamic].
///  - Errores HTTP → subclases de [ApiError] (ver `application/errors`).
abstract interface class IApiClient {
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  });

  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
  });

  Future<dynamic> put(
    String path, {
    Map<String, dynamic>? body,
  });

  Future<dynamic> delete(String path);
}
