import 'package:arrow_maze/domain/entities/user.dart';
import 'package:arrow_maze/domain/interfaces/i_local_storage.dart';

/// Fake in-memory de [ILocalStorage] para pruebas.
class FakeLocalStorage implements ILocalStorage {
  String? token;
  User? user;

  @override
  Future<void> deleteToken() async {
    token = null;
    user = null;
  }

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> saveToken(String value) async => token = value;

  @override
  Future<void> saveUser(User value) async => user = value;

  @override
  Future<User?> readUser() async => user;
}
