import 'package:arrow_maze/domain/entities/arrow.dart';
import 'package:arrow_maze/domain/factories/arrow_factory.dart';
import 'package:arrow_maze/domain/factories/arrow_spec.dart';

/// Object Mother: specs y entidades Arrow válidas y consistentes.
/// Centraliza toda construcción de Arrow/ArrowSpec usada en tests.
class ArrowMother {
  static final ArrowFactory _factory = ArrowFactory();

  /// Flecha de 2 casillas (1,0)→(1,1) apuntando al Este.
  static ArrowSpec eastwardSpec({String id = 'a1', String color = '#EF476F'}) =>
      ArrowSpec(id: id, path: const [
        [1, 0],
        [1, 1],
      ], color: color);

  /// Flecha de 2 casillas (0,2)→(1,2) apuntando al Sur.
  static ArrowSpec southwardSpec({String id = 'a2', String color = '#06D6A0'}) =>
      ArrowSpec(id: id, path: const [
        [0, 2],
        [1, 2],
      ], color: color);

  /// Flecha en L (0,0)→(1,0)→(1,1): dobla y termina apuntando al Este.
  static ArrowSpec lShapedSpec({String id = 'curved', String color = '#FFD166'}) =>
      ArrowSpec(id: id, path: const [
        [0, 0],
        [1, 0],
        [1, 1],
      ], color: color);

  /// Spec inválida: una sola casilla (viola la invariante path >= 2).
  static ArrowSpec singleCellSpec({String id = 'bad'}) =>
      ArrowSpec(id: id, path: const [
        [0, 0],
      ], color: '#000000');

  /// Spec inválida: casillas no adyacentes ortogonalmente.
  static ArrowSpec nonAdjacentSpec({String id = 'gap'}) =>
      ArrowSpec(id: id, path: const [
        [0, 0],
        [0, 2],
      ], color: '#000000');

  static Arrow eastward({String id = 'a1'}) =>
      _factory.create(eastwardSpec(id: id));

  static Arrow southward({String id = 'a2'}) =>
      _factory.create(southwardSpec(id: id));

  static Arrow lShaped({String id = 'curved'}) =>
      _factory.create(lShapedSpec(id: id));
}
