import 'dart:math' as math;

import '../api/engine_strings.dart';
import '../core/config/thresholds.dart';
import '../core/models/baseline.dart';
import '../dsp/stats.dart' show mean, median, std;

/// Result of aggregating one calibration scan's trusted ticks.
class CalibrationSessionResult {
  const CalibrationSessionResult({
    required this.success,
    this.failureReason,
    this.hrMedian,
    this.hrStd,
    this.hrvMedian,
    this.hrvStd,
    this.rrMedian,
    this.rrStd,
    required this.timestamp,
  });

  final bool success;
  final String? failureReason;
  final double? hrMedian;
  final double? hrStd;
  final double? hrvMedian;
  final double? hrvStd;
  final double? rrMedian;
  final double? rrStd;

  /// Epoch milliseconds.
  final int timestamp;
}

/// Calibration aggregation, baseline floors, and the adaptive-update EMA.
class BaselineService {
  BaselineService({required this.thresholds});

  final Thresholds thresholds;

  /// Aggregates one calibration scan's trusted tick lists into a session
  /// result, or a failure with a user-readable reason.
  CalibrationSessionResult evaluateSession({
    required List<double> hrTicks,
    required List<double> hrvTicks,
    required List<double> rrTicks,
    required int nowMs,
  }) {
    final b = thresholds.baseline;
    if (hrTicks.length < b.minTicksHr) {
      return CalibrationSessionResult(
        success: false,
        failureReason: EngineStrings.calibrationFailHr,
        timestamp: nowMs,
      );
    }
    if (hrvTicks.length < b.minTicksHrv) {
      return CalibrationSessionResult(
        success: false,
        failureReason: EngineStrings.calibrationFailHrv,
        timestamp: nowMs,
      );
    }
    if (rrTicks.length < b.minTicksRr) {
      return CalibrationSessionResult(
        success: false,
        failureReason: EngineStrings.calibrationFailRr,
        timestamp: nowMs,
      );
    }
    return CalibrationSessionResult(
      success: true,
      hrMedian: median(hrTicks),
      hrStd: std(hrTicks),
      hrvMedian: median(hrvTicks),
      hrvStd: std(hrvTicks),
      rrMedian: median(rrTicks),
      rrStd: std(rrTicks),
      timestamp: nowMs,
    );
  }

  /// Builds a [Baseline] from up to the last 10 successful calibration
  /// sessions (oldest first, most recent last).
  Baseline computeBaseline(
    List<CalibrationSessionResult> successfulSessions, {
    required int nowMs,
    bool isDemo = false,
  }) {
    assert(successfulSessions.isNotEmpty);
    assert(successfulSessions.every((s) => s.success));
    final last10 = successfulSessions.length > 10
        ? successfulSessions.sublist(successfulSessions.length - 10)
        : successfulSessions;
    final b = thresholds.baseline;

    MetricBaseline build(
      List<double> medians,
      double latestWithinStd,
      double Function(double mean) floorFor,
    ) {
      final m = mean(medians);
      var sd = last10.length >= b.minSessionsForSessionSd ? std(medians) : latestWithinStd;
      final floor = floorFor(m);
      var floorApplied = false;
      if (sd < floor) {
        sd = floor;
        floorApplied = true;
      }
      return MetricBaseline(
        mean: m,
        sd: sd,
        variance: sd * sd,
        sdFloorApplied: floorApplied,
        sessionCount: last10.length,
        updatedAt: nowMs,
      );
    }

    final hr = build(last10.map((s) => s.hrMedian!).toList(), last10.last.hrStd!,
        (_) => b.sdFloorHr);
    final hrv = build(last10.map((s) => s.hrvMedian!).toList(), last10.last.hrvStd!,
        (m) => math.max(b.sdFloorHrvMs, b.sdFloorHrvFrac * m));
    final rr = build(last10.map((s) => s.rrMedian!).toList(), last10.last.rrStd!,
        (_) => b.sdFloorRr);

    return Baseline(hr: hr, hrv: hrv, rr: rr, isDemo: isDemo);
  }

  /// Applies the adaptive EMA update after a qualifying scan. Returns null
  /// (no update) if any gating condition fails.
  Baseline? adaptiveUpdate({
    required Baseline current,
    required double hrMedian,
    required double hrvMedian,
    required double rrMedian,
    required String endReason, // 'user' | 'timeout' (only these qualify)
    required double restingFraction,
    required int maxLevelRank, // 0=normal .. 4=critical; must be <= 1 (monitoring)
    required String alertOutcome, // 'none' | 'userOk' | 'escalated' | 'cancelled'
    required int trustedTicksHr,
    required int trustedTicksHrv,
    required int trustedTicksRr,
    required bool isReplay,
    required int nowMs,
  }) {
    if (current.isDemo || isReplay) return null;
    if (endReason != 'user' && endReason != 'timeout') return null;
    if (restingFraction < 0.8) return null;
    if (maxLevelRank > 1) return null;
    if (alertOutcome != 'none' && alertOutcome != 'userOk') return null;
    if (trustedTicksHr < 30 || trustedTicksHrv < 30 || trustedTicksRr < 30) return null;

    final b = thresholds.baseline;
    final hr = _ema(current.hr, hrMedian, b.updateAlpha, floor: b.sdFloorHr, nowMs: nowMs);
    final hrv = _ema(current.hrv, hrvMedian, b.updateAlpha,
        floor: math.max(b.sdFloorHrvMs, b.sdFloorHrvFrac * current.hrv.mean), nowMs: nowMs);
    final rr = _ema(current.rr, rrMedian, b.updateAlpha, floor: b.sdFloorRr, nowMs: nowMs);

    return current.copyWith(hr: hr, hrv: hrv, rr: rr);
  }

  MetricBaseline _ema(
    MetricBaseline old,
    double newMedian,
    double alpha, {
    required double floor,
    required int nowMs,
  }) {
    final newMean = (1 - alpha) * old.mean + alpha * newMedian;
    final delta = newMedian - old.mean;
    final newVariance = (1 - alpha) * old.variance + alpha * delta * delta;
    var sd = math.sqrt(newVariance);
    var floorApplied = false;
    if (sd < floor) {
      sd = floor;
      floorApplied = true;
    }
    return MetricBaseline(
      mean: newMean,
      sd: sd,
      variance: newVariance,
      sdFloorApplied: floorApplied,
      sessionCount: old.sessionCount,
      updatedAt: nowMs,
    );
  }
}
