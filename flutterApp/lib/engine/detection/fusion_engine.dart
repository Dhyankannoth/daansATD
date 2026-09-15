import '../core/config/thresholds.dart';
import '../core/models/deviation_flag.dart';

class FusionResult {
  const FusionResult({
    required this.persistentSystems,
    required this.currentlyDeviating,
    required this.ruleAlert,
    required this.watchdogAlert,
    required this.lastDeviationAtMs,
  });

  final List<BodySystem> persistentSystems;
  final List<BodySystem> currentlyDeviating;
  final bool ruleAlert;
  final bool watchdogAlert;
  final int? lastDeviationAtMs;
}

/// Tracks per-system deviation persistence and combines it into the rule
/// alert (respiratory + at least one of cardiovascular/autonomic, all
/// persistent) and the signal-loss watchdog.
class FusionEngine {
  FusionEngine({required this.thresholds});

  final Thresholds thresholds;

  final Map<BodySystem, List<bool>> _history = {
    for (final s in BodySystem.values) s: <bool>[],
  };

  int? _lastDeviationAtMs;
  double? _fingerLostSinceS;

  void reset() {
    for (final s in BodySystem.values) {
      _history[s] = [];
    }
    _lastDeviationAtMs = null;
    _fingerLostSinceS = null;
  }

  FusionResult evaluate({
    required List<DeviationFlag> flags,
    required bool fingerPresent,
    required bool scanEndedByUser,
    required bool inCooldown,
    required double nowS,
    required int nowMs,
  }) {
    final window = thresholds.fusion.persistenceWindow;
    final minCount = thresholds.fusion.persistenceMin;

    for (final flag in flags) {
      final list = _history[flag.system]!;
      list.add(flag.trusted && flag.deviating);
      if (list.length > window) {
        list.removeAt(0);
      }
    }

    final persistent = <BodySystem>[];
    for (final s in BodySystem.values) {
      final list = _history[s]!;
      if (list.length == window && list.where((v) => v).length >= minCount) {
        persistent.add(s);
      }
    }

    final currentlyDeviating = flags
        .where((f) => f.trusted && f.deviating)
        .map((f) => f.system)
        .toList();

    final ruleAlert = persistent.contains(BodySystem.respiratory) &&
        (persistent.contains(BodySystem.cardiovascular) ||
            persistent.contains(BodySystem.autonomic));

    if (currentlyDeviating.isNotEmpty) {
      _lastDeviationAtMs = nowMs;
    }

    if (!fingerPresent) {
      _fingerLostSinceS ??= nowS;
    } else {
      _fingerLostSinceS = null;
    }

    final fingerLostDuration =
        _fingerLostSinceS == null ? 0.0 : nowS - _fingerLostSinceS!;
    final recentDeviation = _lastDeviationAtMs != null &&
        (nowMs - _lastDeviationAtMs!) <= thresholds.fusion.watchdogRecentS * 1000;
    final watchdogAlert = fingerLostDuration > thresholds.fusion.watchdogFingerLostS &&
        recentDeviation &&
        !scanEndedByUser &&
        !inCooldown;

    return FusionResult(
      persistentSystems: persistent,
      currentlyDeviating: currentlyDeviating,
      ruleAlert: ruleAlert,
      watchdogAlert: watchdogAlert,
      lastDeviationAtMs: _lastDeviationAtMs,
    );
  }
}
