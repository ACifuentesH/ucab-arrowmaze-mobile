/// Errores de la API normalizados a tipos de aplicación.
/// La capa de infraestructura traduce códigos HTTP a estas clases;
/// las capas superiores nunca ven códigos HTTP crudos.
sealed class ApiError implements Exception {
  final String message;
  const ApiError(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

/// 401 — sesión ausente, inválida o expirada. La UI debe forzar logout.
class UnauthorizedError extends ApiError {
  const UnauthorizedError(super.message);
}

/// 404 — recurso inexistente (ej. usuario nuevo sin progreso guardado).
class NotFoundError extends ApiError {
  const NotFoundError(super.message);
}

/// 409 — conflicto (email o username ya registrados).
class ConflictError extends ApiError {
  const ConflictError(super.message);
}

/// 400/422 — body inválido según validaciones del backend.
///
/// [message] es un código de aplicación estable (ej. `invalid_email`),
/// no el payload crudo del backend.
class ValidationError extends ApiError {
  const ValidationError(super.message);
}

/// 500 u otro fallo no controlado del servidor.
class ServerError extends ApiError {
  const ServerError(super.message);
}

/// Fallo de red/transporte: sin conexión, timeout, DNS.
class NetworkError extends ApiError {
  const NetworkError(super.message);
}
