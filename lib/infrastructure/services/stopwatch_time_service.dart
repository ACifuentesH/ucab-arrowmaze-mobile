import 'dart:async';

import 'package:arrow_maze/domain/ports/i_time_service.dart';

/// Adapter + implementación concreta de ITimeService.
/// Usa Stopwatch (acumulador) + Timer.periodic (tick cada segundo).
/// PROHIBIDO en dominio/aplicación: Timer y Stopwatch son APIs de plataforma.
class StopwatchTimeService implements ITimeService {
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  final StreamController<int> _controller = StreamController<int>.broadcast();

  @override
  Stream<int> get elapsed => _controller.stream;

  @override
  void start() {
    if (_stopwatch.isRunning) return;
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_controller.isClosed) {
        _controller.add(_stopwatch.elapsed.inSeconds);
      }
    });
  }

  @override
  void stop() {
    _stopwatch.stop();
    _timer?.cancel();
    _timer = null;
  }

  @override
  void reset() {
    stop();
    _stopwatch.reset();
  }

  void dispose() {
    reset();
    _controller.close();
  }
}
