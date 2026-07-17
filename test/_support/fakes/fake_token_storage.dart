import 'package:arrow_maze/application/ports/i_token_storage.dart';

/// Fake in-memory de ITokenStorage.
class FakeTokenStorage implements ITokenStorage {
  String? stored;

  @override
  Future<String?> read() async => stored;

  @override
  Future<void> save(String token) async => stored = token;

  @override
  Future<void> clear() async => stored = null;
}
