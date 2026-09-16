import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pulseguard/engine/api/events.dart' show RiskLevel;
import 'package:pulseguard/engine/core/config/thresholds.dart';
import 'package:pulseguard/engine/core/models/deviation_flag.dart';
import 'package:pulseguard/engine/detection/fusion_engine.dart'
    show FusionResult;
import 'package:pulseguard/engine/ml/risk_engine.dart';

Thresholds _load() {
  final json =
      jsonDecode(File('assets/config/thresholds.json').readAsStringSync())
          as Map<String, dynamic>;
  return Thresholds.fromJson(json);
}

DeviationFlag _flag(
  BodySystem s, {
  bool deviating = false,
  bool trusted = true,
  String reason = '',
}) {
  return DeviationFlag(
    timestamp: 0,
    system: s,
    deviating: deviating,
    severity: deviating ? 0.5 : 0,
    metric: s.name,
    value: null,
    baseline: 0,
    z: null,
    trusted: trusted,
    reason: reason,
  );
}

List<DeviationFlag> _noFlags() => [
  _flag(BodySystem.cardiovascular),
  _flag(BodySystem.respiratory),
  _flag(BodySystem.autonomic),
];

const _emptyFusion = FusionResult(
  persistentSystems: [],
  currentlyDeviating: [],
  ruleAlert: false,
  watchdogAlert: false,
  lastDeviationAtMs: null,
);

void main() {
  test('no deviation and no ML activity -> normal', () {
    final engine = RiskEngine(thresholds: _load());
    final r = engine.evaluate(
      nowS: 0,
      nowMs: 0,
      flags: _noFlags(),
      fusion: _emptyFusion,
      anomalyScoreRaw: null,
      riskProbabilityRaw: null,
      alertEscalated: false,
    );
    expect(r.level, RiskLevel.normal);
  });

  test('a currently-deviating flag (not yet persistent) -> monitoring', () {
    final engine = RiskEngine(thresholds: _load());
    final flags = [
      _flag(
        BodySystem.cardiovascular,
        deviating: true,
        reason: 'HR 20% above baseline',
      ),
      _flag(BodySystem.respiratory),
      _flag(BodySystem.autonomic),
    ];
    final r = engine.evaluate(
      nowS: 0,
      nowMs: 0,
      flags: flags,
      fusion: _emptyFusion,
      anomalyScoreRaw: null,
      riskProbabilityRaw: null,
      alertEscalated: false,
    );
    expect(r.level, RiskLevel.monitoring);
    expect(r.reasons, contains('HR 20% above baseline'));
  });

  test('a persistent system (rule not yet satisfied) -> elevated', () {
    final engine = RiskEngine(thresholds: _load());
    const fusion = FusionResult(
      persistentSystems: [BodySystem.cardiovascular],
      currentlyDeviating: [BodySystem.cardiovascular],
      ruleAlert: false,
      watchdogAlert: false,
      lastDeviationAtMs: 0,
    );
    final r = engine.evaluate(
      nowS: 0,
      nowMs: 0,
      flags: _noFlags(),
      fusion: fusion,
      anomalyScoreRaw: null,
      riskProbabilityRaw: null,
      alertEscalated: false,
    );
    expect(r.level, RiskLevel.elevated);
  });

  test('rule alert -> high', () {
    final engine = RiskEngine(thresholds: _load());
    const fusion = FusionResult(
      persistentSystems: [BodySystem.respiratory, BodySystem.cardiovascular],
      currentlyDeviating: [],
      ruleAlert: true,
      watchdogAlert: false,
      lastDeviationAtMs: 0,
    );
    final r = engine.evaluate(
      nowS: 0,
      nowMs: 0,
      flags: _noFlags(),
      fusion: fusion,
      anomalyScoreRaw: null,
      riskProbabilityRaw: null,
      alertEscalated: false,
    );
    expect(r.level, RiskLevel.high);
  });

  test('watchdog alert -> high', () {
    final engine = RiskEngine(thresholds: _load());
    const fusion = FusionResult(
      persistentSystems: [],
      currentlyDeviating: [],
      ruleAlert: false,
      watchdogAlert: true,
      lastDeviationAtMs: 0,
    );
    final r = engine.evaluate(
      nowS: 0,
      nowMs: 0,
      flags: _noFlags(),
      fusion: fusion,
      anomalyScoreRaw: null,
      riskProbabilityRaw: null,
      alertEscalated: false,
    );
    expect(r.level, RiskLevel.high);
  });

  test('alertEscalated always yields critical', () {
    final engine = RiskEngine(thresholds: _load());
    final r = engine.evaluate(
      nowS: 0,
      nowMs: 0,
      flags: _noFlags(),
      fusion: _emptyFusion,
      anomalyScoreRaw: null,
      riskProbabilityRaw: null,
      alertEscalated: true,
    );
    expect(r.level, RiskLevel.critical);
  });

  test(
    'ML alone can reach elevated (sustained anomaly) but never high, even with '
    'a sustained high risk probability and no persistent system',
    () {
      final engine = RiskEngine(thresholds: _load());
      late final r = () {
        var last = engine.evaluate(
          nowS: 0,
          nowMs: 0,
          flags: _noFlags(),
          fusion: _emptyFusion,
          anomalyScoreRaw: 0.9,
          riskProbabilityRaw: 0.95,
          alertEscalated: false,
        );
        for (var t = 1; t <= 16; t++) {
          last = engine.evaluate(
            nowS: t.toDouble(),
            nowMs: t * 1000,
            flags: _noFlags(),
            fusion: _emptyFusion, // no persistent systems, ever
            anomalyScoreRaw: 0.9,
            riskProbabilityRaw: 0.95,
            alertEscalated: false,
          );
        }
        return last;
      }();

      expect(r.mlActive, isTrue);
      expect(r.level, RiskLevel.elevated);
      expect(r.level, isNot(RiskLevel.high));
    },
  );
}
