import 'package:arrow_maze/domain/aggregates/board.dart';
import 'package:arrow_maze/domain/ports/i_level_repository.dart';
import 'package:arrow_maze/domain/value_objects/level_id.dart';

/// Caso de uso: carga un nivel del repositorio y devuelve un Board listo.
/// Aplica DIP: depende del puerto ILevelRepository, no de la implementación.
class LoadLevelUseCase {
  final ILevelRepository _repository;

  LoadLevelUseCase({required ILevelRepository repository})
      : _repository = repository;

  Future<Board> execute(LevelId levelId) => _repository.loadLevel(levelId);
}
