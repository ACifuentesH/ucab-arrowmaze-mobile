import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:arrow_maze/application/proxies/use_case_logger_proxy.dart';
import 'package:arrow_maze/application/use_cases/i_remove_arrow_use_case.dart';
import 'package:arrow_maze/domain/aggregates/board.dart';

import '../mothers/board_mother.dart';

class _MockRemoveArrowUseCase extends Mock implements IRemoveArrowUseCase {}

/// Testing API: proxy de logging (decorator). Aquí el mock es legítimo:
/// la interacción con el delegado ES el comportamiento observable.
class LoggerProxyTestApi {
  LoggerProxyTestApi() {
    registerFallbackValue(BoardMother.withEscapableArrow());
  }

  final _MockRemoveArrowUseCase _delegate = _MockRemoveArrowUseCase();
  late final UseCaseLoggerProxy _proxy =
      UseCaseLoggerProxy(delegate: _delegate);
  final Board _board = BoardMother.withEscapableArrow();
  bool? _result;

  LoggerProxyTestApi givenDelegateWillReport(bool outcome) {
    when(() => _delegate.execute(any(), any())).thenReturn(outcome);
    return this;
  }

  LoggerProxyTestApi whenArrowIsTapped(String arrowId) {
    _result = _proxy.execute(_board, arrowId);
    return this;
  }

  void thenDelegateShouldHandleTheTap(String arrowId) =>
      verify(() => _delegate.execute(_board, arrowId)).called(1);

  void thenResultShouldBe(bool expected) =>
      expect(_result, equals(expected));
}
