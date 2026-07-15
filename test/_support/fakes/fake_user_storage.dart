import 'package:arrow_maze/application/dtos/auth_user.dart';
import 'package:arrow_maze/application/ports/i_user_storage.dart';

class FakeUserStorage implements IUserStorage {
  AuthUser? _user;

  @override
  Future<void> save(AuthUser user) async {
    _user = user;
  }

  @override
  Future<AuthUser?> read() async => _user;

  @override
  Future<void> clear() async {
    _user = null;
  }
}
