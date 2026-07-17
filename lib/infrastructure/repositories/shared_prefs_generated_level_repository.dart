import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:arrow_maze/application/builders/level_definition.dart';
import 'package:arrow_maze/application/ports/i_generated_level_repository.dart';

class SharedPrefsGeneratedLevelRepository implements IGeneratedLevelRepository {
  static const String _idsKey = 'generated_level_ids';
  static const String _prefix = 'generated_level_';

  final SharedPreferences _prefs;

  const SharedPrefsGeneratedLevelRepository(this._prefs);

  @override
  Future<void> save(LevelDefinition definition) async {
    await _prefs.setString(
      '$_prefix${definition.id}',
      jsonEncode(definition.toJson()),
    );
    final ids = _ids()..add(definition.id);
    await _prefs.setStringList(_idsKey, ids.toSet().toList());
  }

  @override
  Future<List<LevelDefinition>> findAll() async =>
      _ids().map(_load).whereType<LevelDefinition>().toList();

  @override
  Future<LevelDefinition?> findById(String id) async => _load(id);

  @override
  Future<void> delete(String id) async {
    await _prefs.remove('$_prefix$id');
    final ids = _ids()..remove(id);
    await _prefs.setStringList(_idsKey, ids);
  }

  List<String> _ids() => List<String>.from(
        _prefs.getStringList(_idsKey) ?? [],
      );

  LevelDefinition? _load(String id) {
    final raw = _prefs.getString('$_prefix$id');
    if (raw == null) return null;
    return LevelDefinition.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}
