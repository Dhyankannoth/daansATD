/// One camera-frame observation: ROI-averaged colour plus validity flags.
/// Shared between acquisition (which produces these) and the vitals engine
/// (which consumes them). Plain data — no Flutter dependency.
class FrameSample {
  const FrameSample({
    required this.t,
    required this.r,
    required this.g,
    required this.b,
    required this.valid,
    required this.fingerPresent,
  });

  /// Seconds, monotonic within a scan.
  final double t;
  final double r;
  final double g;
  final double b;

  /// True when this frame passed all placement checks (finger, light,
  /// clipping, jump, motion).
  final bool valid;

  /// True when a finger was detected, even if other checks failed.
  final bool fingerPresent;
}
