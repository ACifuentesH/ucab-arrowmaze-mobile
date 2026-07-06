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

  static const ThemeConfig dark = ThemeConfig(
    background: Color(0xFF1A1A2E),
    boardBackground: Color(0xFF16213E),
    emptyCell: Color(0xFF0F3460),
    wallCell: Color(0xFF3A3A5C),
    exitCell: Color(0xFF00B4D8),
    arrowCell: Color(0xFFE94560),
    arrowIcon: Color(0xFFFFFFFF),
    hudText: Color(0xFFE0E0E0),
    lifeActive: Color(0xFFE94560),
    lifeEmpty: Color(0xFF3A3A5C),
    primary: Color(0xFFE94560),
    onPrimary: Color(0xFFFFFFFF),
    victoryOverlay: Color(0xFF00B4D8),
    defeatOverlay: Color(0xFF7B1E3A),
  );
}
