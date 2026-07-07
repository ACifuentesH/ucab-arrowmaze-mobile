import 'package:flutter_test/flutter_test.dart';

import 'package:arrow_maze/application/builders/level_builder.dart';
import 'package:arrow_maze/application/dtos/level_preview.dart';
import 'package:arrow_maze/application/dtos/level_spec.dart';
import 'package:arrow_maze/application/enums/difficulty.dart';
import 'package:arrow_maze/application/ports/i_level_generator_service.dart';
import 'package:arrow_maze/application/use_cases/generate_level_use_case.dart';

import '../fakes/fake_generated_level_repository.dart';
import '../fakes/fake_level_generator_service.dart';
import '../mothers/level_definition_mother.dart';

/// Testing API: generación de niveles con IA (reintento + persistencia).
class GenerateLevelTestApi {
  final FakeLevelGeneratorService _generator = FakeLevelGeneratorService();
  final FakeGeneratedLevelRepository _repository =
      FakeGeneratedLevelRepository();
  LevelPreview? _preview;
  Object? _error;

  GenerateLevelTestApi givenAGeneratorThatReturnsAValidLevel() {
    _generator.enqueueLevel(LevelDefinitionMother.withEscapableArrow(
      id: 'generated_1',
    ));
    return this;
  }

  GenerateLevelTestApi givenAGeneratorThatFailsOnceThenSucceeds() {
    _generator.enqueueFailure();
    _generator.enqueueLevel(LevelDefinitionMother.withEscapableArrow(
      id: 'generated_retry',
    ));
    return this;
  }

  GenerateLevelTestApi givenAGeneratorThatReturnsAnUnplayableLevelTwice() {
    _generator.enqueueLevel(LevelDefinitionMother.withArrowOutsideBoard());
    _generator.enqueueLevel(LevelDefinitionMother.withArrowOutsideBoard());
    return this;
  }

  Future<GenerateLevelTestApi> whenLevelIsGenerated() async {
    final useCase = GenerateLevelUseCase(
      generator: _generator,
      repository: _repository,
      builder: LevelBuilder(),
    );
    try {
      _preview = await useCase.execute(const LevelSpec(
        shapeName: 'corazón',
        arrowCount: 1,
        difficulty: Difficulty.easy,
      ));
    } catch (e) {
      _error = e;
    }
    return this;
  }

  void thenAPreviewShouldBeReturned() {
    expect(_error, isNull);
    expect(_preview, isNotNull);
  }

  Future<void> thenLevelShouldBePersisted(String id) async =>
      expect(await _repository.findById(id), isNotNull);

  Future<void> thenNothingShouldBePersisted() async =>
      expect(await _repository.findAll(), isEmpty);

  void thenGenerationShouldFail() =>
      expect(_error, isA<LevelGenerationException>());

  void thenGeneratorShouldHaveBeenAskedTimes(int times) =>
      expect(_generator.callCount, equals(times));
}
