import '../api/engine_strings.dart';
import '../api/events.dart' show RiskAssessment, RiskLevel;
import '../core/config/thresholds.dart';
import '../core/models/deviation_flag.dart';
import '../detection/fusion_engine.dart' show FusionResult;

class _TimedValue {
  const _TimedValue(this.t, this.value);
  final double t;
  final double value;
}

class _RollingAverage {
  _RollingAverage(this.windowS);
  final double windowS;
  final List<_TimedValue> _pts = [];

  void reset() => _pts.clear();

  double? add(double t, double? value) {
    if (value != null) _pts.add(_TimedValue(t, value));
    _pts.removeWhere((p) => p.t < t - windowS);
    if (_pts.isEmpty) return null;
    var sum = 0.0;
    for (final p in _pts) {
      sum += p.value;
    }
    return sum / _pts.length;
  }
}

String _systemLabel(BodySystem s) => switch (s) {
  BodySystem.cardiovascular => 'heart rate',
  BodySystem.respiratory => 'breathing',
  BodySystem.autonomic => 'HRV',
};

String _joinLabels(List<String> labels) {
  if (labels.isEmpty) return '';
  if (labels.length == 1) return labels.first;
  if (labels.length == 2) return '${labels[0]} and ${labels[1]}';
  return '${labels.sublist(0, labels.length - 1).join(', ')} and ${labels.last}';
}

/// Combines rule-based fusion output with (optional) ML anomaly/risk
/// scores into a 5-level [RiskAssessment]. ML alone can never reach `high`.
class RiskEngine {
  RiskEngine({required this.thresholds});

  final Thresholds thresholds;

  late final _RollingAverage _anomalySmoothed = _RollingAverage(
    thresholds.ml.smoothingS,
  );
  late final _RollingAverage _riskSmoothed = _RollingAverage(
    thresholds.ml.smoothingS,
  );

  double? _anomalyAboveSinceS;
  double? _riskAboveSinceS;

  void reset() {
    _anomalySmoothed.reset();
    _riskSmoothed.reset();
    _anomalyAboveSinceS = null;
    _riskAboveSinceS = null;
  }

  RiskAssessment evaluate({
    required double nowS,
    required int nowMs,
    required List<DeviationFlag> flags,
    required FusionResult fusion,
    required double? anomalyScoreRaw,
    required double? riskProbabilityRaw,
    required bool alertEscalated,
    double? anomalyThreshold,
  }) {
    final threshold =
        anomalyThreshold ?? thresholds.ml.fallbackAnomalyThreshold;
    final mlActive = anomalyScoreRaw != null || riskProbabilityRaw != null;

    final anomalySmooth = _anomalySmoothed.add(nowS, anomalyScoreRaw);
    final riskSmooth = _riskSmoothed.add(nowS, riskProbabilityRaw);

    final anomalyAbove = anomalySmooth != null && anomalySmooth > threshold;
    if (anomalyAbove) {
      _anomalyAboveSinceS ??= nowS;
    } else {
      _anomalyAboveSinceS = null;
    }
    final anomalySustained =
        _anomalyAboveSinceS != null &&
        (nowS - _anomalyAboveSinceS!) >= thresholds.ml.sustainS;

    final riskAbove =
        riskSmooth != null && riskSmooth >= thresholds.ml.riskHigh;
    if (riskAbove) {
      _riskAboveSinceS ??= nowS;
    } else {
      _riskAboveSinceS = null;
    }
    final riskSustained =
        _riskAboveSinceS != null &&
        (nowS - _riskAboveSinceS!) >= thresholds.ml.sustainS;

    final anyDeviatingNow = flags.any((f) => f.trusted && f.deviating);
    final recoveringSuppressed = flags.any((f) => f.recoveringSuppressed);
    final hasPersistentSystem = fusion.persistentSystems.isNotEmpty;

    RiskLevel level;
    if (alertEscalated) {
      level = RiskLevel.critical;
    } else if (fusion.ruleAlert ||
        fusion.watchdogAlert ||
        (riskSustained && hasPersistentSystem)) {
      level = RiskLevel.high;
    } else if (hasPersistentSystem || anomalySustained) {
      level = RiskLevel.elevated;
    } else if (anyDeviatingNow || anomalyAbove) {
      level = RiskLevel.monitoring;
    } else {
      level = RiskLevel.normal;
    }

    final reasons = <String>[
      for (final f in flags)
        if (f.trusted && f.deviating && f.reason.isNotEmpty) f.reason,
    ];
    final mlContributed =
        anomalySustained || (level != RiskLevel.normal && anomalyAbove);
    if (mlContributed) {
      reasons.add(
        anyDeviatingNow
            ? EngineStrings.reasonMlAgrees
            : EngineStrings.reasonMlFlagged,
      );
    }
    if (fusion.watchdogAlert) {
      reasons.add(EngineStrings.reasonSignalLost);
    }

    final statusText = _statusText(
      level: level,
      recoveringSuppressed: recoveringSuppressed,
      deviatingSystems: flags
          .where((f) => f.trusted && f.deviating)
          .map((f) => f.system)
          .toList(),
      mlOnly: anyDeviatingNow == false && anomalyAbove,
    );

    return RiskAssessment(
      timestamp: nowMs,
      level: level,
      statusText: statusText,
      flags: flags,
      persistentSystems: fusion.persistentSystems,
      anomalyScore: anomalySmooth,
      riskProbability: riskSmooth,
      mlActive: mlActive,
      recoveringSuppressed: recoveringSuppressed,
      reasons: reasons,
    );
  }

  String _statusText({
    required RiskLevel level,
    required bool recoveringSuppressed,
    required List<BodySystem> deviatingSystems,
    required bool mlOnly,
  }) {
    switch (level) {
      case RiskLevel.normal:
        return recoveringSuppressed
            ? EngineStrings.statusRecovering
            : EngineStrings.statusNormal;
      case RiskLevel.monitoring:
        if (deviatingSystems.isEmpty) {
          return mlOnly ? EngineStrings.statusMonitoringUnusual : 'Monitoring';
        }
        final labels = deviatingSystems.map(_systemLabel).toSet().toList();
        return 'Monitoring — ${_joinLabels(labels)} deviating';
      case RiskLevel.elevated:
        return EngineStrings.statusElevated;
      case RiskLevel.high:
        return EngineStrings.statusHigh;
      case RiskLevel.critical:
        return EngineStrings.statusCritical;
    }
  }
}
