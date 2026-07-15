/// Orquesta sincronización bidireccional de progreso con el backend.
///
/// La implementación concreta vive en la capa de configuración (Riverpod)
/// para poder invalidar providers de presentación sin acoplar el ViewModel.
abstract interface class IProgressSyncCoordinator {
  /// GET /progress → hidrata almacenamiento local (404 = vacío silencioso).
  /// Cualquier otro error (red, 401, 500, JSON malformado) también se
  /// absorbe: llamarse justo después de un login/register exitoso nunca
  /// debe convertir esa autenticación válida en un fallo de UI.
  Future<void> pullAndApplyLocal();

  /// PUT /progress tras completar un nivel (incluye last* para leaderboard).
  /// Errores de red/servidor se absorben; no debe tumbar la partida.
  Future<void> pushCompletedLevel({
    required String lastLevelId,
    required int lastScore,
    required int lastMoves,
    required int lastTimeSeconds,
    required String currentLevelId,
  });
}
