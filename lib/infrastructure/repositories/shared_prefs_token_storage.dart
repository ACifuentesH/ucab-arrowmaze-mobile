import 'package:shared_preferences/shared_preferences.dart';

import 'package:arrow_maze/application/ports/i_token_storage.dart';

/// Adapter: guarda el JWT en SharedPreferences.
class SharedPrefsTokenStorage implements ITokenStorage {
  static const String _key = 'auth_token';

  final SharedPreferences _prefs;

  const SharedPrefsTokenStorage(this._prefs);

  @override
  Future<String?> read() async => _prefs.getString(_key);

  @override
  Future<void> save(String token) => _prefs.setString(_key, token);

  @override
  Future<void> clear() async {
    await _prefs.remove(_key);
  }
}
