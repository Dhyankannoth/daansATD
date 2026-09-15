import '../dsp/stats.dart' as stats;

class _Point {
  const _Point(this.t, this.value);
  final double t;
  final double value;
}

/// The most recent trusted `(t, value)` recorded for a metric.
class LastTrustedPoint {
  const LastTrustedPoint(this.t, this.value);
  final double t;
  final double value;
}

/// Rolling per-metric history of trusted tick values, used to derive
/// short-term slopes and variability. History persists across finger-loss
/// resets within a scan (only [reset] clears it, for a brand new scan).
class Trends {
  Trends({
    required this.windowS,
    required this.trendMinPoints,
    required this.mlMetricMinPoints,
  });

  final double windowS;
  final int trendMinPoints;
  final int mlMetricMinPoints;

  final Map<String, List<_Point>> _history = {};

  void reset() => _history.clear();

  /// Records a value for [metric] at time [t] (seconds) if [trusted] and
  /// non-null, then prunes anything older than [windowS].
  void record(String metric, double t, double? value, bool trusted) {
    final list = _history.putIfAbsent(metric, () => []);
    if (trusted && value != null) {
      list.add(_Point(t, value));
    }
    list.removeWhere((p) => p.t < t - windowS);
  }

  /// Slope in units-per-minute over the trend window, or null if fewer than
  /// [trendMinPoints] trusted points are available.
  double? slopePerMin(String metric) {
    final pts = _history[metric] ?? const [];
    if (pts.length < trendMinPoints) return null;
    final xsMin = pts.map((p) => p.t / 60).toList();
    final ys = pts.map((p) => p.value).toList();
    return stats.lsqSlope(xsMin, ys);
  }

  /// Standard deviation over the trend window, or null if fewer than
  /// [mlMetricMinPoints] trusted points are available.
  double? std(String metric) {
    final pts = _history[metric] ?? const [];
    if (pts.length < mlMetricMinPoints) return null;
    return stats.std(pts.map((p) => p.value).toList());
  }

  /// The most recently recorded trusted point for [metric], or null if none.
  LastTrustedPoint? lastTrusted(String metric) {
    final pts = _history[metric] ?? const [];
    if (pts.isEmpty) return null;
    final p = pts.last;
    return LastTrustedPoint(p.t, p.value);
  }
}
