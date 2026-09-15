import '../core/models/deviation_flag.dart';
import '../core/models/escalation_payload.dart';
import 'engine_strings.dart';

/// The five-level risk classification. Never implies a medical diagnosis —
/// UI copy must stick to "risk" / "early warning" / "unusual for you".
enum RiskLevel {
  normal,
  monitoring,
  elevated,
  high,
  critical;

  String toJson() => name;

  static RiskLevel fromJson(String value) =>
      RiskLevel.values.firstWhere((e) => e.name == value);
}

/// One tick's combined rule + ML risk verdict.
class RiskAssessment {
  const RiskAssessment({
    required this.timestamp,
    required this.level,
    required this.statusText,
    required this.flags,
    required this.persistentSystems,
    required this.anomalyScore,
    required this.riskProbability,
    required this.mlActive,
    required this.recoveringSuppressed,
    required this.reasons,
  });

  final int timestamp;
  final RiskLevel level;
  final String statusText;

  /// Always exactly 3: cardiovascular, respiratory, autonomic.
  final List<DeviationFlag> flags;
  final List<BodySystem> persistentSystems;
  final double? anomalyScore;
  final double? riskProbability;
  final bool mlActive;
  final bool recoveringSuppressed;
  final List<String> reasons;
}

/// Kind of [AlertEvent] emitted by the alert controller state machine.
enum AlertEventKind {
  checkInOpened,
  checkInTick,
  resolved,
  escalated,
  cooldownStarted,
  cooldownEnded,
}

/// One state-machine transition (or countdown tick) from the alert
/// controller: check-in opened / tick / resolved / escalated / cooldown.
class AlertEvent {
  const AlertEvent({
    required this.kind,
    required this.timestamp,
    this.remainingSeconds,
    this.payload,
  });

  final AlertEventKind kind;
  final int timestamp;

  /// Seconds remaining in the check-in countdown or cooldown, when relevant.
  final int? remainingSeconds;
  final EscalationPayload? payload;
}

/// Debounced finger-placement feedback derived from the camera frame stream.
enum PlacementHint {
  ok,
  coverLens,
  coverFlash,
  pressLighter,
  keepStill,
  noFinger;

  String get message => switch (this) {
    PlacementHint.ok => EngineStrings.placementOk,
    PlacementHint.coverLens => EngineStrings.placementCoverLens,
    PlacementHint.coverFlash => EngineStrings.placementCoverFlash,
    PlacementHint.pressLighter => EngineStrings.placementPressLighter,
    PlacementHint.keepStill => EngineStrings.placementKeepStill,
    PlacementHint.noFinger => EngineStrings.placementNoFinger,
  };
}

/// One ~30 Hz sample of the live (or simulated) pulse waveform for display.
class WaveformSample {
  const WaveformSample({
    required this.t,
    required this.value,
    required this.simulated,
  });

  /// Seconds since scan start.
  final double t;

  /// Normalized, roughly -1..1, inverted so beats point up.
  final double value;
  final bool simulated;
}

/// File paths written by a finished record-mode session.
class RecordingResult {
  const RecordingResult({
    required this.csvPath,
    this.rawCsvPath,
    required this.metaPath,
  });

  final String csvPath;
  final String? rawCsvPath;
  final String metaPath;
}
