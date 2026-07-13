import 'package:flutter_test/flutter_test.dart';

import 'package:arrow_maze/domain/entities/user.dart';

void main() {
  group('User', () {
    test('should_normalize_id_from_register_payload', () {
      final user = User.fromJson({
        'id': 'u-1',
        'username': 'alice',
        'email': 'alice@example.com',
      });

      expect(user.id, 'u-1');
      expect(user.username, 'alice');
      expect(user.email, 'alice@example.com');
    });

    test('should_normalize_id_from_login_payload', () {
      final user = User.fromJson({
        'userId': 'u-1',
        'username': 'alice',
        'email': 'alice@example.com',
      });

      expect(user.id, 'u-1');
    });

    test('should_expose_only_public_fields_in_toJson', () {
      final json = UserMotherLike().toJson();

      expect(json.keys, containsAll(['id', 'username', 'email']));
      expect(json.keys, hasLength(3));
    });
  });
}

class UserMotherLike {
  Map<String, dynamic> toJson() => const User(
        id: 'u-1',
        username: 'alice',
        email: 'alice@example.com',
      ).toJson();
}
