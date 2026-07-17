import 'package:arrow_maze/domain/value_objects/level_id.dart';

/// Base de los Eventos de Dominio (patrón Domain Events, DDD).
///
/// Es un mecanismo *pull*: el Board acumula eventos y el consumidor los
/// recupera con `Board.pullEvents()`. NO es el Observer clásico de GoF
/// (no hay `subject.attach(observer)` ni `notify()` empujando eventos).
/// El Observer real del proyecto vive en los StateNotifier de Riverpod.
abstract class DomainEvent {
  final DateTime occurredOn;
  DomainEvent() : occurredOn = DateTime.now();
}

/// La flecha [arrowId] salió del tablero.
class ArrowEscaped extends DomainEvent {
  final String arrowId;
  ArrowEscaped({required this.arrowId});
}

/// Intento inválido: el camino de [arrowId] estaba bloqueado. Cuesta una vida.
class MoveBlocked extends DomainEvent {
  final String arrowId;
  MoveBlocked({required this.arrowId});
}

/// Todas las flechas salieron: nivel completado.
class LevelCleared extends DomainEvent {
  final LevelId levelId;
  LevelCleared({required this.levelId});
}

/// Las vidas llegaron a 0: fin del juego.
class GameOver extends DomainEvent {
  final LevelId levelId;
  GameOver({required this.levelId});
}
