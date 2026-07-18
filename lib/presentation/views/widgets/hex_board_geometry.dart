import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:arrow_maze/domain/services/hex_grid_topology.dart';
import 'package:arrow_maze/presentation/views/widgets/board_geometry.dart';

/// Geometría hexagonal POINTY-TOP con coordenadas offset **odd-r** (las filas
/// impares se desplazan media celda a la derecha), coherente con
/// [HexGridTopology]. `cell` es el circumradio `s` del hexágono (centro→vértice).
///
/// Fórmulas (x derecha, y ABAJO; `√3` = raíz de 3):
///   - centro: x = √3·s·(c + 0.5·(r%2)) + (√3/2)·s ;  y = 1.5·s·r + s
///   - ancho tablero  = √3·s·cols + (rows>1 ? (√3/2)·s : 0)
///   - alto tablero    = 1.5·s·(rows−1) + 2·s
///   - paso entre vecinas = √3·s (uniforme para las 6 direcciones)
///
/// Índices de dirección = los de [HexGridTopology]: 0=NE,1=E,2=SE,3=SW,4=W,5=NW.
class HexBoardGeometry implements IBoardGeometry {
  const HexBoardGeometry();

  static final double _sqrt3 = math.sqrt(3);

  /// Vectores unitarios de las 6 direcciones hex (y hacia abajo → NE tiene y<0).
  /// El desplazamiento odd-r ya está absorbido en el centro, así que estos
  /// vectores NO dependen de la paridad de la fila.
  static final List<Offset> _dir = [
    Offset(0.5, -_sqrt3 / 2), // NE
    const Offset(1, 0), //        E
    Offset(0.5, _sqrt3 / 2), //   SE
    Offset(-0.5, _sqrt3 / 2), //  SW
    const Offset(-1, 0), //       W
    Offset(-0.5, -_sqrt3 / 2), // NW
  ];

  @override
  double cellScaleFor(double maxWidth, double maxHeight, int rows, int cols) {
    // Despeja s de las dos fórmulas del tamaño del tablero y toma el mínimo,
    // para que el tablero quepa en ambos ejes sin deformarse.
    final widthDivisor = _sqrt3 * cols + (rows > 1 ? _sqrt3 / 2 : 0);
    final heightDivisor = 1.5 * (rows - 1) + 2;
    final sByWidth = maxWidth / widthDivisor;
    final sByHeight = maxHeight / heightDivisor;
    return math.min(sByWidth, sByHeight);
  }

  @override
  Size boardSize(int rows, int cols, double cell) {
    final width = _sqrt3 * cell * cols + (rows > 1 ? _sqrt3 / 2 * cell : 0);
    final height = 1.5 * cell * (rows - 1) + 2 * cell;
    return Size(width, height);
  }

  @override
  Offset cellCenter(int r, int c, double cell) {
    final x = _sqrt3 * cell * (c + 0.5 * (r % 2)) + _sqrt3 / 2 * cell;
    final y = 1.5 * cell * r + cell;
    return Offset(x, y);
  }

  @override
  Path cellOutline(int r, int c, double cell) {
    final center = cellCenter(r, c, cell);
    final path = Path();
    for (int i = 0; i < 6; i++) {
      // Vértices a 60°·i − 30°: para pointy-top el vértice superior queda
      // recto hacia arriba (i=5 → 270° → (0,−s)).
      final angle = (60 * i - 30) * math.pi / 180;
      final v = center + Offset(cell * math.cos(angle), cell * math.sin(angle));
      if (i == 0) {
        path.moveTo(v.dx, v.dy);
      } else {
        path.lineTo(v.dx, v.dy);
      }
    }
    path.close();
    return path;
  }

  @override
  Offset directionVector(int dirIndex) => _dir[dirIndex];

  @override
  double stepDistance(double cell) => _sqrt3 * cell;

  @override
  (int, int)? hitTest(Offset local, double cell, int rows, int cols) {
    // 1) Estima la fila por la coordenada vertical (filas equiespaciadas 1.5·s).
    final estR = ((local.dy - cell) / (1.5 * cell)).round();
    // 2) Estima la columna despejando x según la paridad de la fila estimada.
    final estC = ((local.dx - _sqrt3 / 2 * cell) / (_sqrt3 * cell) -
            0.5 * (estR % 2))
        .round();

    // 3) Los centros hex forman un diagrama de Voronoi hexagonal: la celda
    //    correcta es la de centro más cercano. Se comprueba la candidata y sus
    //    6 vecinas (misma tabla odd-r de la topología, sin duplicarla).
    (int, int)? best;
    double bestDist = double.infinity;

    void consider(int r, int c) {
      if (r < 0 || r >= rows || c < 0 || c >= cols) return;
      final d = (local - cellCenter(r, c, cell)).distance;
      if (d < bestDist) {
        bestDist = d;
        best = (r, c);
      }
    }

    consider(estR, estC);
    for (int i = 0; i < 6; i++) {
      final (nr, nc) = HexGridTopology.neighborOffset(i, estR, estC);
      consider(nr, nc);
    }

    // Fuera de cualquier hexágono: el centro más cercano queda a más de un
    // circumradio (s) → el tap no cae en ninguna celda.
    if (best == null || bestDist > cell) return null;
    return best;
  }

  @override
  bool operator ==(Object other) => other is HexBoardGeometry;

  @override
  int get hashCode => (HexBoardGeometry).hashCode;
}
