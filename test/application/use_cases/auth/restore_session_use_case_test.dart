import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:arrow_maze/application/ports/i_auth_repository.dart';
import 'package:arrow_maze/application/use_cases/auth/restore_session_use_case.dart';
import 'package:arrow_maze/domain/entities/user.dart';

import '../../../_support/mothers/user_mother.dart';

class MockAuthRepository extends Mock implements IAuthRepository {}

void main() {
  group('RestoreSessionUseCase', () {
    late MockAuthRepository auth;
    late RestoreSessionUseCase useCase;

    setUp(() {
      auth = MockAuthRepository();
      useCase = RestoreSessionUseCase(auth: auth);
    });

    test('should_return_user_when_repository_has_stored_session', () async {
      when(() => auth.restoreSession()).thenAnswer((_) async => UserMother.alice());

      final user = await useCase.execute();

      expect(user, UserMother.alice());
    });

    test('should_return_null_when_repository_has_no_stored_session', () async {
      when(() => auth.restoreSession()).thenAnswer((_) async => null);

      final user = await useCase.execute();

      expect(user, isNull);
    });
  });
}
