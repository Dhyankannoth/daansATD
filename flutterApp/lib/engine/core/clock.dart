/// Injectable source of time, so engine logic is deterministic under test
/// and replay can advance faster than real time.
abstract class Clock {
  /// Current time as epoch milliseconds.
  int nowMs();

  /// Current time in seconds (fractional).
  double nowS() => nowMs() / 1000.0;

  /// Completes after [duration] has elapsed according to this clock.
  Future<void> delay(Duration duration);
}

/// Wall-clock implementation backed by [DateTime] and real [Future.delayed].
class SystemClock extends Clock {
  @override
  int nowMs() => DateTime.now().millisecondsSinceEpoch;

  @override
  Future<void> delay(Duration duration) => Future<void>.delayed(duration);
}

/// Deterministic, manually-advanced clock for tests and sped-up replay.
///
/// [delay] advances the clock's own notion of time immediately and returns
/// a completed future, so callers relying on it (e.g. periodic orchestration
/// loops) proceed without waiting on the real wall clock.
class FakeClock extends Clock {
  FakeClock({int startMs = 0}) : _nowMs = startMs;

  int _nowMs;

  @override
  int nowMs() => _nowMs;

  /// Advances the clock by [duration] without waiting.
  void advance(Duration duration) {
    _nowMs += duration.inMilliseconds;
  }

  @override
  Future<void> delay(Duration duration) async {
    advance(duration);
  }
}
