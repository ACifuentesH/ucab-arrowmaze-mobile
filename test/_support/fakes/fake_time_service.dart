import 'dart:async';

import 'package:arrow_maze/domain/ports/i_time_service.dart';

/// Fake de ITimeService: el test controla el reloj con [tick].
class FakeTimeService implements ITimeService {
  final StreamController<int> _controller = StreamController<int>.broadcast();

  @override
  Stream<int> get elapsed => _controller.stream;

  @override
  void start() {}

  @override
  void stop() {}

  @override
  void reset() {}

  void tick(int seconds) => _controller.add(seconds);

  void dispose() => _controller.close();
}
