import '../core/config/thresholds.dart';
import '../core/models/activity_state.dart';
import '../core/models/baseline.dart';
import '../core/models/feature_row.dart';
import '../core/models/vitals_reading.dart';
import '../detection/trends.dart';

class _QualityTick {
  const _QualityTick(this.t, this.trusted);
  final double t;
  final bool trusted;
}

/// Builds one [FeatureRow] per tick in the exact `feature_spec.json` order.
/// Stateful only in its rolling window of per-tick trust, used for the row
/// gate; the per-metric trusted-or-carried-forward values come from
/// [Trends], which the caller must have already updated this tick.
class FeatureBuilder {
  FeatureBuilder({required this.thresholds});

  final Thresholds thresholds;

  final List<_QualityTick> _qualityHistory = [];

  void reset() => _qualityHistory.clear();

  FeatureRow build({
    required double nowS,
    required int nowMs,
    required VitalsReading reading,
    required Baseline? baseline,
    required ActivityStateKind activity,
    required Trends trends,
    required double? timeSinceExerciseS,
    required double elapsedScanS,
  }) {
    final q = thresholds.quality;
    final overallTrusted = reading.quality >= q.trusted;
    _qualityHistory.add(_QualityTick(nowS, overallTrusted));
    _qualityHistory.removeWhere((t) => t.t < nowS - thresholds.ml.rowWindowS);

    FeatureRow invalid() =>
        FeatureRow(timestamp: nowMs, values: const [], valid: false);

    if (baseline == null) return invalid();

    final trustedCount = _qualityHistory.where((t) => t.trusted).length;
    final required = thresholds.ml.rowWindowS * thresholds.ml.rowMinTrustedFrac;
    if (trustedCount < required) return invalid();

    final hr = _carriedValue(trends, 'hr', nowS);
    final hrv = _carriedValue(trends, 'hrv', nowS);
    final rr = _carriedValue(trends, 'rr', nowS);
    if (hr == null || hrv == null || rr == null) return invalid();

    final hrSlope = trends.slopePerMin('hr');
    final hrvSlope = trends.slopePerMin('hrv');
    final rrSlope = trends.slopePerMin('rr');
    if (hrSlope == null || hrvSlope == null || rrSlope == null)
      return invalid();

    final hrStd = trends.std('hr');
    final hrvStd = trends.std('hrv');
    final rrStd = trends.std('rr');
    if (hrStd == null || hrvStd == null || rrStd == null) return invalid();

    final muHr = baseline.hr.mean, sdHr = baseline.hr.sd;
    final muHrv = baseline.hrv.mean, sdHrv = baseline.hrv.sd;
    final muRr = baseline.rr.mean, sdRr = baseline.rr.sd;

    final sinceExercise = timeSinceExerciseS == null
        ? 1.0
        : ((timeSinceExerciseS + elapsedScanS).clamp(0, 600)) / 600;

    final values = <double>[
      (hr - muHr) / sdHr, // 0 hr_z
      (hrv - muHrv) / sdHrv, // 1 hrv_z
      (rr - muRr) / sdRr, // 2 rr_z
      hrSlope / sdHr, // 3 hr_slope_z
      hrvSlope / sdHrv, // 4 hrv_slope_z
      rrSlope / sdRr, // 5 rr_slope_z
      hrStd / sdHr, // 6 hr_var_z
      hrvStd / sdHrv, // 7 hrv_var_z
      rrStd / sdRr, // 8 rr_var_z
      (hr - muHr) / muHr, // 9 hr_pct
      (hrv - muHrv) / muHrv, // 10 hrv_pct
      (rr - muRr) / muRr, // 11 rr_pct
      activity == ActivityStateKind.resting ? 1.0 : 0.0, // 12 is_resting
      activity == ActivityStateKind.recovering ? 1.0 : 0.0, // 13 is_recovering
      (activity == ActivityStateKind.unknown ||
              activity == ActivityStateKind.exercising)
          ? 1.0
          : 0.0, // 14 is_unknown
      sinceExercise.toDouble(), // 15 since_exercise
    ];

    return FeatureRow(timestamp: nowMs, values: values, valid: true);
  }

  double? _carriedValue(Trends trends, String metric, double nowS) {
    final last = trends.lastTrusted(metric);
    if (last == null) return null;
    if (nowS - last.t > thresholds.ml.carryForwardS) return null;
    return last.value;
  }
}
