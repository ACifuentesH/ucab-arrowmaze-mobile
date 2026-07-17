import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:arrow_maze/application/dtos/auth_user.dart';
import 'package:arrow_maze/application/ports/i_user_storage.dart';

class SharedPrefsUserStorage implements IUserStorage {
  static const String _key = 'auth_user';

  final SharedPreferences _prefs;

  const SharedPrefsUserStorage(this._prefs);

  @override
  Future<void> save(AuthUser user) =>
      _prefs.setString(_key, jsonEncode(user.toJson()));

  @override
  Future<AuthUser?> read() async {
    final raw = _prefs.getString(_key);
    if (raw == null) return null;
    return AuthUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> clear() => _prefs.remove(_key);
}
