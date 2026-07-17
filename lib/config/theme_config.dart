import 'package:flutter/material.dart';

/// Paleta de colores centralizada para Arrow Maze.
/// Toda la UI lee sus colores desde aquí; cambiar el tema es cambiar esta clase.
@immutable
class ThemeConfig {
  final Color background;
  final Color boardBackground;
  final Color emptyCell;
  final Color wallCell;
  final Color exitCell;
  final Color arrowCell;
  final Color arrowIcon;
  final Color hudText;
  final Color lifeActive;
  final Color lifeEmpty;
  final Color primary;
  final Color onPrimary;
  final Color victoryOverlay;
  final Color defeatOverlay;

  const ThemeConfig({
    required this.background,
    required this.boardBackground,
    required this.emptyCell,
    required this.wallCell,
    required this.exitCell,
    required this.arrowCell,
    required this.arrowIcon,
    required this.hudText,
    required this.lifeActive,
    required this.lifeEmpty,
    required this.primary,
    required this.onPrimary,
    required this.victoryOverlay,
    required this.defeatOverlay,
  });

  /// "Sunset Cálido": grises carbón cálidos + coral, mostaza y rosa fuerte.
  static const ThemeConfig dark = ThemeConfig(
    background: Color(0xFF1B1B1F),
    boardBackground: Color(0xFF232328),
    emptyCell: Color(0xFF2E2E36),
    wallCell: Color(0xFF3D3D46),
    exitCell: Color(0xFFFFB238),
    arrowCell: Color(0xFFFF6B4A),
    arrowIcon: Color(0xFFF3EFE9),
    hudText: Color(0xFFF3EFE9),
    lifeActive: Color(0xFFFF3D68),
    lifeEmpty: Color(0xFF3D3D46),
    primary: Color(0xFFFF6B4A),
    onPrimary: Color(0xFF1B1B1F),
    victoryOverlay: Color(0xFFFFB238),
    defeatOverlay: Color(0xFF7A2E3A),
  );
}
