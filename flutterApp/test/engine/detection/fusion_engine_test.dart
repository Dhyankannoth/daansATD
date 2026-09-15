import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pulseguard/engine/core/config/thresholds.dart';
import 'package:pulseguard/engine/core/models/deviation_flag.dart';
import 'package:pulseguard/engine/detection/fusion_engine.dart';

Thresholds _load() {
  final json = jsonDecode(File('assets/config/thresholds.json').readAsStringSync())
      as Map<String, dynamic>;
  return Thresholds.fromJson(json);
}

DeviationFlag _flag(BodySystem s, bool deviating, {bool trusted = true}) {
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
    reason: '',
  );
}

void main() {
  test('persistence requires >= persistence_min of persistence_window (15 of 20)', () {
    final fusion = FusionEngine(thresholds: _load());
    // 14 deviating out of 20 ticks: not persistent.
    for (var i = 0; i < 14; i++) {
      fusion.evaluate(
        flags: [_flag(BodySystem.respiratory, true)],
        fingerPresent: true,
        scanEndedByUser: false,
        inCooldown: false,
        nowS: i.toDouble(),
        nowMs: i * 1000,
      );
    }
    late FusionResult result;
    for (var i = 14; i < 20; i++) {
      result = fusion.evaluate(
        flags: [_flag(BodySystem.respiratory, false)],
        fingerPresent: true,
        scanEndedByUser: false,
        inCooldown: false,
        nowS: i.toDouble(),
        nowMs: i * 1000,
      );
    }
    expect(result.persistentSystems.contains(BodySystem.respiratory), isFalse);
  });

  test('15 of 20 deviating ticks reaches persistence', () {
    final fusion = FusionEngine(thresholds: _load());
    for (var i = 0; i < 15; i++) {
      fusion.evaluate(
        flags: [_flag(BodySystem.respiratory, true)],
        fingerPresent: true,
        scanEndedByUser: false,
        inCooldown: false,
        nowS: i.toDouble(),
        nowMs: i * 1000,
      );
    }
    late FusionResult result;
    for (var i = 15; i < 20; i++) {
      result = fusion.evaluate(
        flags: [_flag(BodySystem.respiratory, false)],
        fingerPresent: true,
        scanEndedByUser: false,
        inCooldown: false,
        nowS: i.toDouble(),
        nowMs: i * 1000,
      );
    }
    expect(result.persistentSystems.contains(BodySystem.respiratory), isTrue);
  });

  test('rule alert requires respiratory plus one of cardiovascular/autonomic', () {
    final fusion = FusionEngine(thresholds: _load());
    late FusionResult result;
    for (var i = 0; i < 20; i++) {
      result = fusion.evaluate(
        flags: [
          _flag(BodySystem.respiratory, true),
          _flag(BodySystem.cardiovascular, true),
          _flag(BodySystem.autonomic, false),
        ],
        fingerPresent: true,
        scanEndedByUser: false,
        inCooldown: false,
        nowS: i.toDouble(),
        nowMs: i * 1000,
      );
    }
    expect(result.ruleAlert, isTrue);
  });

  test('respiratory alone (no cardio/autonomic) does not trigger the rule alert', () {
    final fusion = FusionEngine(thresholds: _load());
    late FusionResult result;
    for (var i = 0; i < 20; i++) {
      result = fusion.evaluate(
        flags: [
          _flag(BodySystem.respiratory, true),
          _flag(BodySystem.cardiovascular, false),
          _flag(BodySystem.autonomic, false),
        ],
        fingerPresent: true,
        scanEndedByUser: false,
        inCooldown: false,
        nowS: i.toDouble(),
        nowMs: i * 1000,
      );
    }
    expect(result.ruleAlert, isFalse);
  });

  test('watchdog fires after finger loss persists for > watchdog_finger_lost_s '
      'following a recent deviation', () {
    final fusion = FusionEngine(thresholds: _load());
    fusion.evaluate(
      flags: [_flag(BodySystem.cardiovascular, true)],
      fingerPresent: true,
      scanEndedByUser: false,
      inCooldown: false,
      nowS: 0,
      nowMs: 0,
    );
    // Finger goes missing at t=1 and stays missing through t=7 (> 5s lost).
    late FusionResult result;
    for (var t = 1; t <= 7; t++) {
      result = fusion.evaluate(
        flags: [_flag(BodySystem.cardiovascular, false, trusted: false)],
        fingerPresent: false,
        scanEndedByUser: false,
        inCooldown: false,
        nowS: t.toDouble(),
        nowMs: t * 1000,
      );
    }
    expect(result.watchdogAlert, isTrue);
  });

  test('watchdog does not fire when the scan was ended by the user', () {
    final fusion = FusionEngine(thresholds: _load());
    fusion.evaluate(
      flags: [_flag(BodySystem.cardiovascular, true)],
      fingerPresent: true,
      scanEndedByUser: false,
      inCooldown: false,
      nowS: 0,
      nowMs: 0,
    );
    late FusionResult result;
    for (var t = 1; t <= 7; t++) {
      result = fusion.evaluate(
        flags: [_flag(BodySystem.cardiovascular, false, trusted: false)],
        fingerPresent: false,
        scanEndedByUser: true,
        inCooldown: false,
        nowS: t.toDouble(),
        nowMs: t * 1000,
      );
    }
    expect(result.watchdogAlert, isFalse);
  });

  test('watchdog does not fire during cooldown', () {
    final fusion = FusionEngine(thresholds: _load());
    fusion.evaluate(
      flags: [_flag(BodySystem.cardiovascular, true)],
      fingerPresent: true,
      scanEndedByUser: false,
      inCooldown: false,
      nowS: 0,
      nowMs: 0,
    );
    late FusionResult result;
    for (var t = 1; t <= 7; t++) {
      result = fusion.evaluate(
        flags: [_flag(BodySystem.cardiovascular, false, trusted: false)],
        fingerPresent: false,
        scanEndedByUser: false,
        inCooldown: true,
        nowS: t.toDouble(),
        nowMs: t * 1000,
      );
    }
    expect(result.watchdogAlert, isFalse);
  });
}
