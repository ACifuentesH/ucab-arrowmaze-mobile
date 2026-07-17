import 'package:arrow_maze/application/builders/level_builder.dart';
import 'package:arrow_maze/domain/aggregates/board.dart';

import 'level_definition_mother.dart';

/// Object Mother: agregados Board válidos y consistentes.
/// Todo Board de test nace aquí — nunca `Board(...)` dentro de un test.
class BoardMother {
  static final LevelBuilder _builder = LevelBuilder();

  /// Tablero 3×3 con una sola flecha 'a1' con su carril despejado.
  /// Al sacarla, el tablero queda vacío (levelCleared).
  static Board withEscapableArrow({int lives = 3}) =>
      _builder.build(LevelDefinitionMother.withEscapableArrow(lives: lives));

  /// Tablero 3×3 donde 'a1' está bloqueada por 'a2'; 'a2' sí puede salir.
  static Board withBlockedArrow({int lives = 3}) =>
      _builder.build(LevelDefinitionMother.withBlockedArrow(lives: lives));

  /// Solo queda una flecha; al salir vacía el tablero.
  static Board almostCleared() => withEscapableArrow();

  /// Tablero con límite de tiempo (regla de dominio applyTimeTick).
  static Board withTimeLimit({required int seconds}) => _builder.build(
        LevelDefinitionMother.withEscapableArrow(timeLimitSeconds: seconds),
      );

  /// Tablero sin límite de tiempo.
  static Board withoutTimeLimit() => withEscapableArrow();
}
