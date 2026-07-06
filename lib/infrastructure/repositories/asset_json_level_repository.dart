import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:arrow_maze/domain/aggregates/board.dart';
import 'package:arrow_maze/domain/ports/i_level_repository.dart';
import 'package:arrow_maze/domain/value_objects/level_id.dart';
import 'package:arrow_maze/application/builders/level_builder.dart';
import 'package:arrow_maze/application/builders/level_definition.dart';

/// Implementa ILevelRepository leyendo niveles desde assets/levels/*.json.
/// Sin red ni base de datos: depende únicamente del sistema de archivos del bundle.
/// saveProgress es no-op en esta primera versión (persistencia vendrá después).
class AssetJsonLevelRepository implements ILevelRepository {
  final LevelBuilder _builder;

  AssetJsonLevelRepository({required LevelBuilder builder})
      : _builder = builder;

  @override
  Future<Board> loadLevel(LevelId id) async {
    final raw =
        await rootBundle.loadString('assets/levels/${id.value}.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final definition = LevelDefinition.fromJson(json);
    return _builder.build(definition);
  }

  @override
  Future<void> saveProgress(LevelId id, int score) async {
    // No-op: primera versión en memoria.
    // La persistencia real (SharedPreferences / Supabase) se añade en v2.
  }
}
