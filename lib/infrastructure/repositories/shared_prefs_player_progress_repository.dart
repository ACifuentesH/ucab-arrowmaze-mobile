import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:arrow_maze/application/dtos/level_progress.dart';
import 'package:arrow_maze/application/ports/i_player_progress_repository.dart';

class SharedPrefsPlayerProgressRepository implements IPlayerProgressRepository {
  static const String _idsKey = 'progress_level_ids';
  static const String _prefix = 'progress_';

  final SharedPreferences _prefs;

  const SharedPrefsPlayerProgressRepository(this._prefs);

  @override
  Future<void> save(LevelProgress progress) async {
    await _prefs.setString(
      '$_prefix${progress.levelId}',
      jsonEncode(progress.toJson()),
    );
    final ids = _ids()..add(progress.levelId);
    await _prefs.setStringList(_idsKey, ids.toSet().toList());
  }

  @override
  Future<LevelProgress?> find(String levelId) async {
    final raw = _prefs.getString('$_prefix$levelId');
    if (raw == null) return null;
    return LevelProgress.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<List<LevelProgress>> findAll() async =>
      _ids().map((id) {
        final raw = _prefs.getString('$_prefix$id');
        if (raw == null) return null;
        return LevelProgress.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      }).whereType<LevelProgress>().toList();

  List<String> _ids() => List<String>.from(
        _prefs.getStringList(_idsKey) ?? [],
      );
}
