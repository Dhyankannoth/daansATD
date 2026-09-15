import 'dart:math' as math;

import '../dsp/stats.dart' show median;

class HrResult {
  const HrResult({required this.hr, required this.keptFrac});
  final double hr;
  final double keptFrac;
}

/// Computes heart rate from beat times (seconds) within the HR window.
/// Cleans inter-beat intervals to `[ibiMinS, ibiMaxS]` and within
/// `hrIbiTolerance` of their median; requires at least `hrMinIntervals` kept.
HrResult? computeHr(
  List<double> beatTimes, {
  required double ibiMinS,
  required double ibiMaxS,
  required double hrIbiTolerance,
  required int hrMinIntervals,
}) {
  final intervals = _diffs(beatTimes);
  if (intervals.isEmpty) return null;

  final ranged = intervals.where((x) => x >= ibiMinS && x <= ibiMaxS).toList();
  if (ranged.isEmpty) return null;
  final med = median(ranged);
  final kept =
      ranged.where((x) => (x - med).abs() <= hrIbiTolerance * med).toList();

  if (kept.length < hrMinIntervals) return null;

  final hr = 60.0 / median(kept);
  final keptFrac = kept.length / intervals.length;
  return HrResult(hr: hr, keptFrac: keptFrac);
}

/// Computes RMSSD (ms) from beat times (seconds) within the HRV window.
/// Requires at least `hrvMinIntervals` total intervals and at least
/// `hrvMinPairs` consecutive clean-interval pairs.
double? computeRmssd(
  List<double> beatTimes, {
  required double hrvIbiTolerance,
  required int hrvMinIntervals,
  required int hrvMinPairs,
}) {
  final intervals = _diffs(beatTimes);
  if (intervals.length < hrvMinIntervals) return null;

  final med = median(intervals);
  final clean = intervals.map((x) => (x - med).abs() <= hrvIbiTolerance * med).toList();

  final squaredDiffsMs = <double>[];
  for (var i = 0; i < intervals.length - 1; i++) {
    if (clean[i] && clean[i + 1]) {
      final diffMs = (intervals[i + 1] - intervals[i]) * 1000;
      squaredDiffsMs.add(diffMs * diffMs);
    }
  }

  if (squaredDiffsMs.length < hrvMinPairs) return null;

  var sum = 0.0;
  for (final v in squaredDiffsMs) {
    sum += v;
  }
  return math.sqrt(sum / squaredDiffsMs.length);
}

List<double> _diffs(List<double> xs) {
  if (xs.length < 2) return [];
  final out = <double>[];
  for (var i = 1; i < xs.length; i++) {
    out.add(xs[i] - xs[i - 1]);
  }
  return out;
}
