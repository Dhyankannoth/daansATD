import '../core/models/activity_state.dart';
import '../core/models/baseline.dart';
import '../core/models/escalation_payload.dart';
import '../core/models/vitals_reading.dart';
import 'events.dart';

enum EnginePhase {
  uninitialized,
  idle,
  preparingCamera,
  settling,
  scanning,
  calibrating,
  replaying,
  finished,
  error,
}

enum AlertSnapshotState { none, checkIn, escalated, cooldown }

/// How a [ScanSummary] concluded.
enum ScanEndReason { user, timeout, noSignal, error, replayFinished }

enum AlertOutcome { none, userOk, escalated, cancelled }

/// Always-current summary the UI polls/observes via
/// `PulseGuardApi.snapshot` — a `ValueListenable<EngineSnapshot>`.
class EngineSnapshot {
  const EngineSnapshot({
    this.phase = EnginePhase.uninitialized,
    this.elapsed = Duration.zero,
    this.remaining,
    this.latestVitals,
    this.activity,
    this.placementHint,
    this.risk,
    this.alertState = AlertSnapshotState.none,
    this.checkInRemaining,
    this.activePayload,
    this.oxTrendPct,
    this.recording = false,
    this.message = '',
    this.error,
    this.hasBaseline = false,
    this.baseline,
  });

  final EnginePhase phase;
  final Duration elapsed;
  final Duration? remaining;
  final VitalsReading? latestVitals;
  final ActivityState? activity;
  final PlacementHint? placementHint;
  final RiskAssessment? risk;
  final AlertSnapshotState alertState;
  final int? checkInRemaining;
  final EscalationPayload? activePayload;
  final double? oxTrendPct;
  final bool recording;
  final String message;
  final String? error;
  final bool hasBaseline;
  final Baseline? baseline;

  EngineSnapshot copyWith({
    EnginePhase? phase,
    Duration? elapsed,
    Duration? remaining,
    bool remainingIsSet = false,
    VitalsReading? latestVitals,
    ActivityState? activity,
    PlacementHint? placementHint,
    RiskAssessment? risk,
    AlertSnapshotState? alertState,
    int? checkInRemaining,
    bool checkInRemainingIsSet = false,
    EscalationPayload? activePayload,
    bool activePayloadIsSet = false,
    double? oxTrendPct,
    bool oxTrendPctIsSet = false,
    bool? recording,
    String? message,
    String? error,
    bool errorIsSet = false,
    bool? hasBaseline,
    Baseline? baseline,
    bool baselineIsSet = false,
  }) {
    return EngineSnapshot(
      phase: phase ?? this.phase,
      elapsed: elapsed ?? this.elapsed,
      remaining: remainingIsSet ? remaining : (remaining ?? this.remaining),
      latestVitals: latestVitals ?? this.latestVitals,
      activity: activity ?? this.activity,
      placementHint: placementHint ?? this.placementHint,
      risk: risk ?? this.risk,
      alertState: alertState ?? this.alertState,
      checkInRemaining: checkInRemainingIsSet
          ? checkInRemaining
          : (checkInRemaining ?? this.checkInRemaining),
      activePayload: activePayloadIsSet
          ? activePayload
          : (activePayload ?? this.activePayload),
      oxTrendPct: oxTrendPctIsSet
          ? oxTrendPct
          : (oxTrendPct ?? this.oxTrendPct),
      recording: recording ?? this.recording,
      message: message ?? this.message,
      error: errorIsSet ? error : (error ?? this.error),
      hasBaseline: hasBaseline ?? this.hasBaseline,
      baseline: baselineIsSet ? baseline : (baseline ?? this.baseline),
    );
  }
}

/// Result of a finished (or aborted) scan.
class ScanSummary {
  const ScanSummary({
    required this.endReason,
    required this.duration,
    this.medianHr,
    this.medianHrv,
    this.medianRr,
    required this.maxLevel,
    required this.alertOutcome,
    required this.trustedFraction,
    this.escalationPayload,
  });

  final ScanEndReason endReason;
  final Duration duration;
  final double? medianHr;
  final double? medianHrv;
  final double? medianRr;
  final RiskLevel maxLevel;
  final AlertOutcome alertOutcome;
  final double trustedFraction;
  final EscalationPayload? escalationPayload;
}

/// Progress of an in-flight calibration scan.
class CalibrationProgress {
  const CalibrationProgress({
    required this.elapsed,
    required this.total,
    required this.trustedTicksHr,
    required this.trustedTicksHrv,
    required this.trustedTicksRr,
    this.done = false,
    this.success,
    this.failureReason,
    this.baseline,
  });

  final Duration elapsed;
  final Duration total;
  final int trustedTicksHr;
  final int trustedTicksHrv;
  final int trustedTicksRr;
  final bool done;
  final bool? success;
  final String? failureReason;
  final Baseline? baseline;

  CalibrationProgress copyWith({
    Duration? elapsed,
    int? trustedTicksHr,
    int? trustedTicksHrv,
    int? trustedTicksRr,
    bool? done,
    bool? success,
    String? failureReason,
    Baseline? baseline,
  }) {
    return CalibrationProgress(
      elapsed: elapsed ?? this.elapsed,
      total: total,
      trustedTicksHr: trustedTicksHr ?? this.trustedTicksHr,
      trustedTicksHrv: trustedTicksHrv ?? this.trustedTicksHrv,
      trustedTicksRr: trustedTicksRr ?? this.trustedTicksRr,
      done: done ?? this.done,
      success: success ?? this.success,
      failureReason: failureReason ?? this.failureReason,
      baseline: baseline ?? this.baseline,
    );
  }
}
