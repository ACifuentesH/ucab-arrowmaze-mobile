import 'package:arrow_maze/application/builders/level_definition.dart';
import 'package:arrow_maze/domain/factories/arrow_spec.dart';
import 'package:arrow_maze/domain/value_objects/topology_kind.dart';

import 'arrow_mother.dart';

/// Object Mother: LevelDefinition válidos (y deliberadamente inválidos)
/// sobre un tablero canónico 3×3 completo.
///
/// Geometría canónica:
///   - 'a1' (Este) ocupa (1,0)-(1,1); su carril de salida es (1,2).
///   - 'a2' (Sur)  ocupa (0,2)-(1,2); su carril de salida es (2,2).
///   - a2 pisa (1,2), así que BLOQUEA la salida de a1 mientras esté en juego.
class LevelDefinitionMother {
  static const List<List<int>> _threeByThree = [
    [0, 0], [0, 1], [0, 2],
    [1, 0], [1, 1], [1, 2],
    [2, 0], [2, 1], [2, 2],
  ];

  /// Solo 'a1' con el carril despejado: escapable, y al salir limpia el nivel.
  static LevelDefinition withEscapableArrow({
    String id = 'level_test',
    String name = 'Test Level',
    int lives = 3,
    int? timeLimitSeconds,
  }) =>
      LevelDefinition(
        id: id,
        name: name,
        lives: lives,
        cells: _threeByThree,
        arrows: [ArrowMother.eastwardSpec()],
        timeLimitSeconds: timeLimitSeconds,
      );

  /// 'a1' bloqueada por 'a2' (que pisa su carril de salida).
  /// 'a2' sí puede salir; después de eso 'a1' queda libre.
  static LevelDefinition withBlockedArrow({
    String id = 'level_blocked',
    int lives = 3,
  }) =>
      LevelDefinition(
        id: id,
        name: 'Blocked Level',
        lives: lives,
        cells: _threeByThree,
        arrows: [ArrowMother.eastwardSpec(), ArrowMother.southwardSpec()],
      );

  /// Tablero sin flechas (borde: nivel vacío).
  static LevelDefinition withoutArrows({String id = 'level_empty'}) =>
      LevelDefinition(
        id: id,
        name: 'Empty Level',
        lives: 3,
        cells: _threeByThree,
        arrows: const [],
      );

  /// Silueta de una sola celda: sin espacio para que ProceduralArrowPlacer
  /// coloque ninguna flecha (no hay corredor de escape posible).
  static LevelDefinition tooSmallForArrows({String id = 'level_too_small'}) =>
      LevelDefinition(
        id: id,
        name: 'Too Small',
        lives: 3,
        cells: const [
          [0, 0],
        ],
        arrows: const [],
      );

  /// Inválido: la flecha pisa una celda que no pertenece al tablero.
  static LevelDefinition withArrowOutsideBoard() => LevelDefinition(
        id: 'level_invalid_outside',
        name: 'Invalid',
        lives: 3,
        cells: const [
          [0, 0],
          [0, 1],
        ],
        arrows: [ArrowMother.eastwardSpec()], // usa la fila 1: no existe
      );

  /// Inválido: dos flechas comparten una casilla.
  static LevelDefinition withOverlappingArrows() => LevelDefinition(
        id: 'level_invalid_overlap',
        name: 'Invalid',
        lives: 3,
        cells: _threeByThree,
        arrows: [
          ArrowMother.eastwardSpec(),
          // Pisa (1,1), ya ocupada por a1.
          ArrowMother.lShapedSpec(id: 'a3'),
        ],
      );

  // ── Hexagonal (pointy-top, odd-r) ─────────────────────────────────────────

  /// Nivel hex válido sobre el 3×3:
  ///   - 'h1' (1,0)→(1,1): apunta E (index 1 de 6).
  ///   - 'h2' (0,2)→(1,2): desde fila PAR, (r+1,c) es SE (index 2 de 6).
  static LevelDefinition hexLevel({
    String id = 'level_hex',
    int lives = 3,
  }) =>
      LevelDefinition(
        id: id,
        name: 'Hex Level',
        lives: lives,
        topology: TopologyKind.hex,
        cells: _threeByThree,
        arrows: const [
          ArrowSpec(id: 'h1', path: [
            [1, 0],
            [1, 1],
          ], color: '#EF476F'),
          ArrowSpec(id: 'h2', path: [
            [0, 2],
            [1, 2],
          ], color: '#06D6A0'),
        ],
      );

  /// Inválido en hex: el par intermedio (0,0)→(1,1) NO es hex-adyacente desde
  /// fila PAR (sus vecinos abajo son (1,0) SE y (1,-1) SW). El último segmento
  /// (1,1)→(1,2) sí es E, así que la fábrica no lo detecta: lo detecta la
  /// validación por grafo del builder.
  static LevelDefinition hexWithNonAdjacentArrow() => LevelDefinition(
        id: 'level_hex_invalid',
        name: 'Invalid Hex',
        lives: 3,
        topology: TopologyKind.hex,
        cells: _threeByThree,
        arrows: const [
          ArrowSpec(id: 'gap', path: [
            [0, 0],
            [1, 1],
            [1, 2],
          ], color: '#000000'),
        ],
      );

  // ── JSON crudo (contrato) ──────────────────────────────────────────────────

  /// Formato plano de assets/levels/*.json.
  static Map<String, dynamic> flatJson({String id = 'level_flat'}) => {
        'id': id,
        'name': 'Flat Level',
        'lives': 5,
        'timeLimitSeconds': 60,
        'difficulty': 'medium',
        'cells': [
          [0, 0],
          [0, 1],
          [0, 2],
        ],
        'arrows': [
          {
            'id': 'a1',
            'path': [
              [0, 0],
              [0, 1],
            ],
            'color': '#118AB2',
          },
        ],
      };

  /// LevelDto del backend: el contrato viaja envuelto en `data`.
  static Map<String, dynamic> backendDtoJson({String id = 'level_1'}) => {
        'id': id,
        'name': 'Tutorial',
        'difficulty': 'easy',
        'parMoves': 10,
        'data': {
          'cells': [
            [0, 0],
            [0, 1],
            [0, 2],
          ],
          'arrows': [
            {
              'id': 'a1',
              'path': [
                [0, 0],
                [0, 1],
              ],
              'color': 'red',
            },
          ],
          'lives': 3,
        },
      };
}
