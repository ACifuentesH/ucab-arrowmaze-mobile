import 'package:arrow_maze/domain/aggregates/board.dart';
import 'package:arrow_maze/domain/ports/i_level_repository.dart';
import 'package:arrow_maze/domain/value_objects/level_id.dart';
import 'package:arrow_maze/application/commands/command_invoker.dart';

/// Caso de uso: reinicia el nivel actual limpiando el historial de Undo.
class RestartLevelUseCase {
  final ILevelRepository _repository;
  final CommandInvoker _invoker;

  RestartLevelUseCase({
    required ILevelRepository repository,
    required CommandInvoker invoker,
  })  : _repository = repository,
        _invoker = invoker;

  Future<Board> execute(LevelId levelId) async {
    _invoker.clear();
    return _repository.loadLevel(levelId);
  }
}
