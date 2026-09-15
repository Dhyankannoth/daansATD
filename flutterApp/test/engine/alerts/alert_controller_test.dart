import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pulseguard/engine/alerts/alert_controller.dart';
import 'package:pulseguard/engine/alerts/alert_effects.dart';
import 'package:pulseguard/engine/api/events.dart' show AlertEventKind, RiskLevel;
import 'package:pulseguard/engine/core/config/thresholds.dart';
import 'package:pulseguard/engine/core/models/emergency_contact.dart';
import 'package:pulseguard/engine/core/models/escalation_payload.dart';
import 'package:pulseguard/engine/core/models/vitals_reading.dart';

Thresholds _load() {
  final json = jsonDecode(File('assets/config/thresholds.json').readAsStringSync())
      as Map<String, dynamic>;
  return Thresholds.fromJson(json);
}

class _FakeEffects implements AlertEffects {
  int checkInOpenedCount = 0;
  int escalatedCount = 0;
  bool wakelockOn = false;

  @override
  void onCheckInOpened() => checkInOpenedCount++;
  @override
  void onCheckInTick(int remainingSeconds) {}
  @override
  void onEscalated() => escalatedCount++;
  @override
  Future<void> enableWakelock() async => wakelockOn = true;
  @override
  Future<void> disableWakelock() async => wakelockOn = false;
}

const _vitals = VitalsReading(
  timestamp: 0,
  hr: 120,
  hrv: 18,
  rr: 26,
  spo2: null,
  oxTrend: null,
  quality: 0.9,
  rrQuality: 0.9,
  fingerPresent: true,
  source: VitalsReadingSource.camera,
);

EscalationPayload _payload() => const EscalationPayload(
      triggeredAt: 0,
      triggerType: EscalationTriggerType.multiSystem,
      systems: [],
      reasons: [],
      vitalsSnapshot: _vitals,
      contact: EmergencyContact(name: 'Alex', phone: '555-0100'),
      status: EscalationStatus.pending,
    );

void main() {
  test('high risk opens a check-in, timeout escalates, then cooldown', () {
    final thresholds = _load();
    final effects = _FakeEffects();
    final controller = AlertController(thresholds: thresholds, effects: effects);
    final events = <AlertEventKind>[];
    controller.events.listen((e) => events.add(e.kind));

    controller.tick(level: RiskLevel.high, nowMs: 0, buildPayload: _payload);
    expect(controller.state, AlertControllerState.checkIn);
    expect(effects.checkInOpenedCount, 1);
    expect(effects.wakelockOn, isTrue);

    // Advance through the timeout without a response.
    final timeoutMs = (thresholds.alerts.checkinTimeoutS * 1000).round();
    controller.tick(level: RiskLevel.high, nowMs: timeoutMs + 1, buildPayload: _payload);

    expect(controller.state, AlertControllerState.escalated);
    expect(effects.escalatedCount, 1);
    expect(controller.activePayload!.status, EscalationStatus.escalated);

    // A subsequent tick doesn't auto-advance out of escalated; the user (or
    // orchestrator) must cancel it.
    controller.cancelEscalation(timeoutMs + 2);
    expect(controller.state, AlertControllerState.cooldown);

    expect(events, containsAllInOrder([
      AlertEventKind.checkInOpened,
      AlertEventKind.escalated,
      AlertEventKind.resolved,
      AlertEventKind.cooldownStarted,
    ]));
  });

  test('respondCheckIn(ok: true) resolves and starts cooldown, suppressing a new high', () {
    final thresholds = _load();
    final controller = AlertController(thresholds: thresholds, effects: _FakeEffects());

    controller.tick(level: RiskLevel.high, nowMs: 0, buildPayload: _payload);
    controller.respondCheckIn(ok: true, nowMs: 1000);
    expect(controller.state, AlertControllerState.cooldown);
    expect(controller.activePayload!.status, EscalationStatus.userOk);

    // A new `high` tick during cooldown does not reopen a check-in.
    controller.tick(level: RiskLevel.high, nowMs: 2000, buildPayload: _payload);
    expect(controller.state, AlertControllerState.cooldown);
  });

  test('respondCheckIn(ok: false) escalates immediately', () {
    final thresholds = _load();
    final effects = _FakeEffects();
    final controller = AlertController(thresholds: thresholds, effects: effects);

    controller.tick(level: RiskLevel.high, nowMs: 0, buildPayload: _payload);
    controller.respondCheckIn(ok: false, nowMs: 1000);
    expect(controller.state, AlertControllerState.escalated);
    expect(effects.escalatedCount, 1);
  });

  test('cooldown expires back to none after cooldown_s', () {
    final thresholds = _load();
    final controller = AlertController(thresholds: thresholds, effects: _FakeEffects());

    controller.tick(level: RiskLevel.high, nowMs: 0, buildPayload: _payload);
    controller.respondCheckIn(ok: true, nowMs: 1000);
    expect(controller.state, AlertControllerState.cooldown);

    final cooldownEndMs = 1000 + (thresholds.alerts.cooldownS * 1000).round();
    controller.tick(level: RiskLevel.normal, nowMs: cooldownEndMs + 1, buildPayload: _payload);
    expect(controller.state, AlertControllerState.none);
  });

  test('resetForNewScan preserves an active cooldown', () {
    final thresholds = _load();
    final controller = AlertController(thresholds: thresholds, effects: _FakeEffects());
    controller.tick(level: RiskLevel.high, nowMs: 0, buildPayload: _payload);
    controller.respondCheckIn(ok: true, nowMs: 1000);
    expect(controller.state, AlertControllerState.cooldown);

    controller.resetForNewScan();
    expect(controller.state, AlertControllerState.cooldown);
  });
}
