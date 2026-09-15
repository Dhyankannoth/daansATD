import 'dart:math' as math;

import '../dsp/stats.dart' show pearson;

/// Signal quality for the HR window: how much of the window was usable,
/// how many intervals survived cleaning, and how well the red and green
/// channels agree (a real pulse modulates both; noise does not).
double computeQuality({
  required bool hrWindowOk,
  required double validFrac,
  required double keptFrac,
  required List<double> filteredRed,
  required List<double> filteredGreen,
}) {
  if (!hrWindowOk) return 0;
  final corr = pearson(filteredRed, filteredGreen);
  return validFrac * keptFrac * math.max(0, corr);
}
