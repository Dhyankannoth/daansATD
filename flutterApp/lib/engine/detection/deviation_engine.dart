import '../api/engine_strings.dart';
import '../core/config/thresholds.dart';
import '../core/models/activity_state.dart';
import '../core/models/baseline.dart';
import '../core/models/deviation_flag.dart';
import '../core/models/vitals_reading.dart';
import 'trends.dart';

/// Compares each tick's trusted vitals against the user's resting baseline
/// and emits exactly three [DeviationFlag]s (cardiovascular, respiratory,
/// autonomic), suppressing exercise-recovery false positives.
class DeviationEngine {
  DeviationEngine({required this.thresholds});

  final Thresholds thresholds;

  List<DeviationFlag> evaluate({
    required VitalsReading reading,
    required Baseline? baseline,
    required ActivityStateKind activity,
    required Trends trends,
    required int nowMs,
  }) {
    final hrTrusted = reading.quality >= thresholds.quality.trusted;
    final rrTrusted =
        _min(reading.quality, reading.rrQuality) >= thresholds.quality.trusted;
    final hrvTrusted = hrTrusted; // RMSSD shares the HR-window quality gate.

    final cardio = _evaluateMetric(
      system: BodySystem.cardiovascular,
      metric: 'hr',
      value: reading.hr,
      trusted: hrTrusted,
      metricBaseline: baseline?.hr,
      z: baseline == null || reading.hr == null
          ? null
          : (reading.hr! - baseline.hr.mean) / baseline.hr.sd,
      deviatingTest: (z) => z >= thresholds.deviation.hrZ,
      recoveringOk: (slope) => slope > thresholds.deviation.recoveringHrSlope,
      activity: activity,
      trends: trends,
      aboveBaseline: true,
      humanName: 'HR',
      nowMs: nowMs,
    );

    final resp = _evaluateMetric(
      system: BodySystem.respiratory,
      metric: 'rr',
      value: reading.rr,
      trusted: rrTrusted,
      metricBaseline: baseline?.rr,
      z: baseline == null || reading.rr == null
          ? null
          : (reading.rr! - baseline.rr.mean) / baseline.rr.sd,
      deviatingTest: (z) => z >= thresholds.deviation.rrZ,
      recoveringOk: (slope) => slope > thresholds.deviation.recoveringRrSlope,
      activity: activity,
      trends: trends,
      aboveBaseline: true,
      humanName: 'Breathing rate',
      nowMs: nowMs,
    );

    final auto = _evaluateMetric(
      system: BodySystem.autonomic,
      metric: 'hrv',
      value: reading.hrv,
      trusted: hrvTrusted,
      metricBaseline: baseline?.hrv,
      z: baseline == null || reading.hrv == null
          ? null
          : (reading.hrv! - baseline.hrv.mean) / baseline.hrv.sd,
      deviatingTest: (z) => z <= thresholds.deviation.hrvZ,
      recoveringOk: (slope) => slope <= thresholds.deviation.recoveringHrvSlope,
      activity: activity,
      trends: trends,
      aboveBaseline: false,
      humanName: 'HRV',
      nowMs: nowMs,
    );

    return [cardio, resp, auto];
  }

  double _min(double a, double b) => a < b ? a : b;

  DeviationFlag _evaluateMetric({
    required BodySystem system,
    required String metric,
    required double? value,
    required bool trusted,
    required MetricBaseline? metricBaseline,
    required double? z,
    required bool Function(double z) deviatingTest,
    required bool Function(double slope) recoveringOk,
    required ActivityStateKind activity,
    required Trends trends,
    required bool aboveBaseline,
    required String humanName,
    required int nowMs,
  }) {
    if (metricBaseline == null) {
      return DeviationFlag(
        timestamp: nowMs,
        system: system,
        deviating: false,
        severity: 0,
        metric: metric,
        value: value,
        baseline: 0,
        z: null,
        trusted: false,
        reason: EngineStrings.noBaselineYet,
      );
    }

    if (!trusted || value == null || z == null) {
      return DeviationFlag(
        timestamp: nowMs,
        system: system,
        deviating: false,
        severity: 0,
        metric: metric,
        value: value,
        baseline: metricBaseline.mean,
        z: null,
        trusted: false,
        reason: EngineStrings.noTrustedTick(humanName),
      );
    }

    final severity = (z.abs() / thresholds.deviation.severityScale).clamp(0.0, 1.0);
    final deviatingRaw = deviatingTest(z);

    var deviating = deviatingRaw;
    var recoveringSuppressed = false;
    if (deviatingRaw && activity == ActivityStateKind.recovering) {
      final slope = trends.slopePerMin(metric);
      final stillDeviating = slope != null && recoveringOk(slope);
      if (!stillDeviating) {
        deviating = false;
        recoveringSuppressed = true;
      }
    }

    final pct = ((value - metricBaseline.mean).abs() / metricBaseline.mean * 100).round();
    final direction = aboveBaseline ? 'above' : 'below';
    final String reason;
    if (recoveringSuppressed) {
      reason = EngineStrings.recoverySuppressed(humanName);
    } else if (deviating) {
      reason = '$humanName $pct% $direction your resting baseline';
    } else {
      reason = '';
    }

    return DeviationFlag(
      timestamp: nowMs,
      system: system,
      deviating: deviating,
      severity: severity,
      metric: metric,
      value: value,
      baseline: metricBaseline.mean,
      z: z,
      trusted: true,
      reason: reason,
      recoveringSuppressed: recoveringSuppressed,
    );
  }
}
