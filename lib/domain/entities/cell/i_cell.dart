import 'package:arrow_maze/domain/value_objects/cell_id.dart';

/// Interfaz base de toda celda del tablero.
/// Segregada a propósito (ISP): solo lo común a TODAS las celdas.
/// Comportamientos extra (rotar, etc.) viven en interfaces aparte.
abstract interface class ICell {
  CellId get id;

  /// ¿El jugador puede pasar/pararse en esta celda? (LSP: toda ICell responde).
  bool get isWalkable;
}
