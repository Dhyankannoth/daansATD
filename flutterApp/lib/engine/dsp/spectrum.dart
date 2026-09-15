import 'dart:math' as math;

import 'stats.dart' show mean;

class DominantRateResult {
  const DominantRateResult({required this.freqHz, required this.bpm, required this.prominence});
  final double freqHz;
  final double bpm;
  final double prominence;
}

List<double> _linearDetrend(List<double> x) {
  final n = x.length;
  if (n < 2) return List<double>.from(x);
  final xs = List<double>.generate(n, (i) => i.toDouble());
  final mx = mean(xs);
  final my = mean(x);
  var num = 0.0;
  var den = 0.0;
  for (var i = 0; i < n; i++) {
    final dx = xs[i] - mx;
    num += dx * (x[i] - my);
    den += dx * dx;
  }
  final slope = den == 0 ? 0.0 : num / den;
  final intercept = my - slope * mx;
  return List<double>.generate(n, (i) => x[i] - (intercept + slope * i));
}

List<double> _hann(int n) {
  if (n == 1) return [1.0];
  return List<double>.generate(
      n, (i) => 0.5 - 0.5 * math.cos(2 * math.pi * i / (n - 1)));
}

/// Scans `band` (Hz, `[low, high]`) in steps of `step` Hz for the frequency
/// with maximum windowed-DFT power. Returns null if `x.length < minSamples`.
DominantRateResult? dominantRate(
  List<double> x,
  double fs,
  List<double> band,
  double step, {
  int minSamples = 0,
}) {
  if (x.length < minSamples || x.length < 2) return null;

  final detrended = _linearDetrend(x);
  final window = _hann(detrended.length);
  final windowed = List<double>.generate(
      detrended.length, (i) => detrended[i] * window[i]);

  final freqs = <double>[];
  for (var f = band[0]; f <= band[1] + 1e-9; f += step) {
    freqs.add(f);
  }
  if (freqs.isEmpty) return null;

  final powers = List<double>.filled(freqs.length, 0);
  final n = windowed.length;
  for (var fi = 0; fi < freqs.length; fi++) {
    final f = freqs[fi];
    var re = 0.0;
    var im = 0.0;
    for (var s = 0; s < n; s++) {
      final theta = -2 * math.pi * f * s / fs;
      re += windowed[s] * math.cos(theta);
      im += windowed[s] * math.sin(theta);
    }
    powers[fi] = re * re + im * im;
  }

  var bestIdx = 0;
  for (var i = 1; i < powers.length; i++) {
    if (powers[i] > powers[bestIdx]) bestIdx = i;
  }
  final meanPower = mean(powers);
  final prominence = meanPower == 0 ? 0.0 : powers[bestIdx] / meanPower;
  final fStar = freqs[bestIdx];
  return DominantRateResult(freqHz: fStar, bpm: 60 * fStar, prominence: prominence);
}
