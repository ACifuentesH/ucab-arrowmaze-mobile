// Los campos son privados y los parámetros van con nombre (convención del repo,
// igual que UseCaseLoggerProxy); Dart prohíbe parámetros con nombre privados,
// así que `prefer_initializing_formals` no aplica aquí.
// ignore_for_file: prefer_initializing_formals
import 'package:arrow_maze/application/dtos/leaderboard_entry_dto.dart';
import 'package:arrow_maze/application/use_cases/leaderboard/get_leaderboard_use_case.dart';

/// AOP – Proxy de caché con TTL para [GetLeaderboardUseCase].
///
/// Aspecto transversal: memoiza el resultado del leaderboard por
/// `(levelId, limit)` durante una ventana de tiempo ([ttl]). Mientras la
/// entrada esté vigente, las llamadas repetidas se sirven desde memoria y el
/// caso de uso envuelto NO se invoca (evita golpear la red en cada refresco de
/// la pantalla). Al expirar el TTL, la siguiente llamada vuelve a delegar y
/// refresca la caché.
///
/// Substitución transparente (patrón Proxy): implementa [GetLeaderboardUseCase]
/// (Dart permite usar una clase concreta como interfaz), por lo que reemplaza al
/// caso de uso real en `getLeaderboardUseCaseProvider` sin cambiar su tipo.
///
/// El reloj se inyecta ([clock]) para poder probar la expiración del TTL de
/// forma determinista, sin esperas reales.
class CachingUseCaseProxy implements GetLeaderboardUseCase {
  final GetLeaderboardUseCase _delegate;
  final Duration _ttl;
  final DateTime Function() _clock;
  final Map<String, _CacheEntry> _cache = {};

  CachingUseCaseProxy({
    required GetLeaderboardUseCase delegate,
    Duration ttl = const Duration(seconds: 30),
    DateTime Function() clock = DateTime.now,
  })  : _delegate = delegate,
        _ttl = ttl,
        _clock = clock;

  @override
  Future<List<LeaderboardEntryDto>> execute(
    String levelId, {
    int limit = 10,
  }) async {
    final key = '$levelId::$limit';
    final now = _clock();

    final cached = _cache[key];
    if (cached != null && now.difference(cached.storedAt) < _ttl) {
      return cached.value;
    }

    final fresh = await _delegate.execute(levelId, limit: limit);
    _cache[key] = _CacheEntry(value: fresh, storedAt: now);
    return fresh;
  }
}

class _CacheEntry {
  final List<LeaderboardEntryDto> value;
  final DateTime storedAt;

  const _CacheEntry({required this.value, required this.storedAt});
}
