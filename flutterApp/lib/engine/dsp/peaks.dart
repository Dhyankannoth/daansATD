import 'stats.dart' show std;

/// Detects beat (pulse) times in a band-passed PPG signal.
///
/// The signal dips on each beat (absorption increases), so it is inverted
/// before peak-picking. Peaks closer together than `minGapS` are pruned
/// (taller wins); peaks within `edgeIgnoreS` of either end are dropped;
/// surviving peaks are refined to sub-sample precision via parabolic
/// interpolation. Returns beat times in seconds.
List<double> findBeats(
  List<double> filtered,
  double fs, {
  required double minGapS,
  required double minHeightSd,
  required double edgeIgnoreS,
}) {
  final n = filtered.length;
  if (n < 3) return [];

  final inverted = filtered.map((v) => -v).toList();
  final threshold = minHeightSd * std(inverted);

  final candidates = <int>[];
  for (var i = 1; i < n - 1; i++) {
    if (inverted[i] > inverted[i - 1] &&
        inverted[i] > inverted[i + 1] &&
        inverted[i] > threshold) {
      candidates.add(i);
    }
  }

  final minGapSamples = minGapS * fs;
  final byHeightDesc = [...candidates]
    ..sort((a, b) => inverted[b].compareTo(inverted[a]));

  final kept = <int>[];
  for (final idx in byHeightDesc) {
    final tooClose = kept.any((k) => (k - idx).abs() < minGapSamples);
    if (!tooClose) kept.add(idx);
  }
  kept.sort();

  final edgeIgnoreSamples = edgeIgnoreS * fs;
  final trimmed =
      kept.where((i) => i >= edgeIgnoreSamples && i <= (n - 1) - edgeIgnoreSamples);

  final times = <double>[];
  for (final i in trimmed) {
    final refinedIndex =
        i + parabolicPeakOffset(inverted[i - 1], inverted[i], inverted[i + 1]);
    times.add(refinedIndex / fs);
  }
  return times;
}

/// Sub-sample offset (added to the integer peak index `i`) of the true peak
/// of the parabola passing through `(i-1, a)`, `(i, b)`, `(i+1, c)`.
/// Returns 0 if the three points are collinear (degenerate parabola).
double parabolicPeakOffset(double a, double b, double c) {
  final denom = a - 2 * b + c;
  if (denom == 0) return 0;
  return 0.5 * (a - c) / denom;
}
