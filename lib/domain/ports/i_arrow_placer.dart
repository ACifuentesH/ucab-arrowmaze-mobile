import 'dart:math';

import 'package:arrow_maze/domain/factories/arrow_spec.dart';

/// Patrón Strategy: coloca flechas válidas y siempre-resolubles sobre una
/// forma dada (lista de celdas). Aísla la geometría de colocación de
/// cualquier fuente de la forma (assets, generador de IA, editor manual...).
abstract interface class IArrowPlacer {
  /// Devuelve flechas que cubren la forma [cells] COMPLETA (cada celda
  /// pertenece a alguna flecha, sin solaparse) y siempre resolubles.
  /// Puede dejar alguna celda sin cubrir solo si la geometría lo hace
  /// imposible (p. ej. una celda aislada); devuelve lista vacía si la forma
  /// no admite ninguna flecha (menos de 2 celdas).
  List<ArrowSpec> place(
    List<List<int>> cells, {
    Random? random,
  });
}
