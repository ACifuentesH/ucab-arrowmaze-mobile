import 'dart:math' show min;

import 'package:flutter/material.dart';

/// Abstracción de la geometría de píxeles de un tablero: convierte coordenadas
/// lógicas `(fila, columna)` en posiciones/formas en el canvas y viceversa.
///
/// Aísla TODA la matemática de layout del [BoardPainter] y del [BoardView] para
/// que el mismo pintor sirva tanto a tableros cuadrados como hexagonales: solo
/// cambia la implementación de geometría inyectada.
///
/// Convención de ejes: `x` crece hacia la derecha, `y` hacia ABAJO (como en el
/// canvas de Flutter). `cell` es la unidad de escala de cada celda — su
/// significado exacto depende de la topología (lado del cuadrado en
/// [SquareBoardGeometry]; circumradio del hexágono en `HexBoardGeometry`).
abstract interface class IBoardGeometry {
  /// Escala de celda que hace caber un tablero de [rows]×[cols] dentro de un
  /// rectángulo [maxWidth]×[maxHeight] sin deformar la forma.
  double cellScaleFor(double maxWidth, double maxHeight, int rows, int cols);

  /// Tamaño en píxeles del tablero completo para una escala [cell] dada.
  Size boardSize(int rows, int cols, double cell);

  /// Centro en píxeles de la celda `(r, c)`.
  Offset cellCenter(int r, int c, double cell);

  /// Contorno de la celda `(r, c)`: rectángulo en cuadrado, hexágono en hex.
  /// Lo usa el pintor para el fondo y como base de los puntos.
  Path cellOutline(int r, int c, double cell);

  /// Vector UNITARIO de la dirección [dirIndex] (índices propios de la
  /// topología). `y` apunta hacia abajo en pantalla.
  Offset directionVector(int dirIndex);

  /// Distancia centro-a-centro entre celdas vecinas (uniforme). La usa la
  /// animación de escape para prolongar el camino fuera del tablero.
  double stepDistance(double cell);

  /// Celda `(fila, columna)` bajo el punto [local] (relativo al tablero), o
  /// null si el punto cae fuera de toda celda existente / del rango
  /// `[0, rows) × [0, cols)`.
  (int, int)? hitTest(Offset local, double cell, int rows, int cols);
}

/// Geometría ortogonal clásica: celdas cuadradas de lado `cell`, alineadas a
/// una cuadrícula. Reproduce 1:1 la matemática que el pintor/vista tenían
/// hardcodeada (centros, outline, hit-test) — el render cuadrado no cambia ni
/// un píxel.
class SquareBoardGeometry implements IBoardGeometry {
  const SquareBoardGeometry();

  /// N=0, E=1, S=2, O=3 (vectores unitarios; y hacia abajo).
  static const List<Offset> _dir = [
    Offset(0, -1),
    Offset(1, 0),
    Offset(0, 1),
    Offset(-1, 0),
  ];

  @override
  double cellScaleFor(double maxWidth, double maxHeight, int rows, int cols) =>
      min(maxWidth / cols, maxHeight / rows);

  @override
  Size boardSize(int rows, int cols, double cell) =>
      Size(cols * cell, rows * cell);

  @override
  Offset cellCenter(int r, int c, double cell) =>
      Offset((c + 0.5) * cell, (r + 0.5) * cell);

  @override
  Path cellOutline(int r, int c, double cell) =>
      Path()..addRect(Rect.fromLTWH(c * cell, r * cell, cell, cell));

  @override
  Offset directionVector(int dirIndex) => _dir[dirIndex];

  @override
  double stepDistance(double cell) => cell;

  @override
  (int, int)? hitTest(Offset local, double cell, int rows, int cols) {
    final c = (local.dx / cell).floor();
    final r = (local.dy / cell).floor();
    if (r < 0 || r >= rows || c < 0 || c >= cols) return null;
    return (r, c);
  }

  // Todas las instancias son intercambiables (sin estado): igualdad por tipo
  // para que `shouldRepaint` no dispare repintados espurios al recrear el
  // pintor en cada frame de animación.
  @override
  bool operator ==(Object other) => other is SquareBoardGeometry;

  @override
  int get hashCode => (SquareBoardGeometry).hashCode;
}
