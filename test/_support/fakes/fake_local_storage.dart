import 'package:arrow_maze/domain/interfaces/i_local_storage.dart';

/// Fake in-memory de [ILocalStorage] para pruebas.
class FakeLocalStorage implements ILocalStorage {
  String? token;

  @override
  Future<void> deleteToken() async => token = null;

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> saveToken(String value) async => token = value;
}
