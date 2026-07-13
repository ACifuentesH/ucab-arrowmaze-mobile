import 'package:arrow_maze/domain/entities/user.dart';

class UserMother {
  static User alice({String id = 'u-1'}) => User(
        id: id,
        username: 'alice',
        email: 'alice@example.com',
      );
}
