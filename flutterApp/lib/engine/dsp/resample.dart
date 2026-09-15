// Resampling and binning of irregular/uniform time series. Pure Dart.

/// Linearly interpolates the (times, values) samples onto a uniform grid
/// at `fs` Hz spanning `[tStart, tEnd]`. `times` must be non-decreasing.
/// Grid points before the first sample or after the last sample hold the
/// first/last value (flat extrapolation).
List<double> resampleLinear(
  List<double> times,
  List<double> values,
  double fs,
  double tStart,
  double tEnd,
) {
  if (times.isEmpty) return [];
  final n = ((tEnd - tStart) * fs).round() + 1;
  final out = List<double>.filled(n < 0 ? 0 : n, 0);
  var srcIdx = 0;
  for (var i = 0; i < out.length; i++) {
    final t = tStart + i / fs;
    if (t <= times.first) {
      out[i] = values.first;
      continue;
    }
    if (t >= times.last) {
      out[i] = values.last;
      continue;
    }
    while (srcIdx < times.length - 2 && times[srcIdx + 1] < t) {
      srcIdx++;
    }
    final t0 = times[srcIdx];
    final t1 = times[srcIdx + 1];
    final v0 = values[srcIdx];
    final v1 = values[srcIdx + 1];
    if (t1 == t0) {
      out[i] = v0;
    } else {
      final frac = (t - t0) / (t1 - t0);
      out[i] = v0 + frac * (v1 - v0);
    }
  }
  return out;
}

/// Averages a uniformly-sampled series (sample rate `fsIn`) into consecutive
/// bins of `binSeconds` seconds.
List<double> binAverage(List<double> values, double fsIn, double binSeconds) {
  final samplesPerBin = (binSeconds * fsIn).round();
  if (samplesPerBin <= 0 || values.isEmpty) return [];
  final out = <double>[];
  for (var start = 0; start < values.length; start += samplesPerBin) {
    final end = (start + samplesPerBin).clamp(0, values.length);
    if (end <= start) break;
    var sum = 0.0;
    for (var i = start; i < end; i++) {
      sum += values[i];
    }
    out.add(sum / (end - start));
  }
  return out;
}
