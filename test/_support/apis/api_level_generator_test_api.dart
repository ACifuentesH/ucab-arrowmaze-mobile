import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:arrow_maze/application/builders/level_definition.dart';
import 'package:arrow_maze/application/dtos/level_spec.dart';
import 'package:arrow_maze/application/enums/difficulty.dart';
import 'package:arrow_maze/application/ports/i_api_client.dart';
import 'package:arrow_maze/application/ports/i_level_generator_service.dart';
import 'package:arrow_maze/infrastructure/services/api_level_generator_service.dart';

class _MockApiClient extends Mock implements IApiClient {}

class _FakeLevelSpec extends Fake implements LevelSpec {}

/// Testing API: ApiLevelGeneratorService contra un IApiClient mockeado — no
/// hay red real ni backend involucrado.
class ApiLevelGeneratorTestApi {
  final _MockApiClient _apiClient = _MockApiClient();
  late final ILevelGeneratorService _service =
      ApiLevelGeneratorService(apiClient: _apiClient);

  final LevelSpec _spec = const LevelSpec(
    shapeName: 'a heart',
    difficulty: Difficulty.medium,
  );

  LevelDefinition? _result;
  Object? _error;

  static void registerFallbacks() {
    registerFallbackValue(_FakeLevelSpec());
  }

  // ── Given ──────────────────────────────────────────────────────────────────

  ApiLevelGeneratorTestApi givenTheBackendReturns(LevelDefinition level) {
    when(() => _apiClient.generateLevel(any())).thenAnswer((_) async => level);
    return this;
  }

  ApiLevelGeneratorTestApi givenTheBackendFailsWith(Object error) {
    when(() => _apiClient.generateLevel(any())).thenThrow(error);
    return this;
  }

  // ── When ───────────────────────────────────────────────────────────────────

  Future<ApiLevelGeneratorTestApi> whenGenerating() async {
    try {
      _result = await _service.generate(_spec);
    } catch (e) {
      _error = e;
    }
    return this;
  }

  // ── Then ───────────────────────────────────────────────────────────────────

  void thenTheApiClientShouldHaveBeenCalledWithTheSpec() =>
      verify(() => _apiClient.generateLevel(_spec)).called(1);

  void thenTheResultShouldBe(LevelDefinition level) =>
      expect(_result, same(level));

  void thenItShouldFailWith<T>() => expect(_error, isA<T>());

  void thenTheErrorMessageShouldBe(String message) {
    expect(_error, isA<LevelGenerationException>());
    expect((_error! as LevelGenerationException).message, equals(message));
  }
}
