import '../dsp/spectrum.dart' show DominantRateResult;

class RrResult {
  const RrResult({required this.rr, required this.rrQuality});
  final double? rr;
  final double rrQuality;
}

/// Combines the intensity-modulation and interval-modulation respiratory
/// rate estimates into one reading, per the agreement rule in §7.3.7.
RrResult computeRr({
  required DominantRateResult? intensityResult,
  required DominantRateResult? intervalResult,
  required double minProminence,
  required double agreeBpm,
  required double agreeQuality,
  required double singleQuality,
}) {
  final intensityOk =
      intensityResult != null && intensityResult.prominence >= minProminence;
  final intervalOk =
      intervalResult != null && intervalResult.prominence >= minProminence;

  if (intensityOk && intervalOk) {
    final diff = (intensityResult.bpm - intervalResult.bpm).abs();
    if (diff <= agreeBpm) {
      final rr = (intensityResult.bpm + intervalResult.bpm) / 2;
      return RrResult(rr: rr, rrQuality: agreeQuality);
    }
    final winner = intensityResult.prominence >= intervalResult.prominence
        ? intensityResult
        : intervalResult;
    return RrResult(rr: winner.bpm, rrQuality: singleQuality);
  }

  if (intensityOk)
    return RrResult(rr: intensityResult.bpm, rrQuality: singleQuality);
  if (intervalOk)
    return RrResult(rr: intervalResult.bpm, rrQuality: singleQuality);

  return const RrResult(rr: null, rrQuality: 0);
}
