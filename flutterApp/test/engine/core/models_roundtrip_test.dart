import 'package:flutter_test/flutter_test.dart';
import 'package:pulseguard/engine/core/models/activity_state.dart';
import 'package:pulseguard/engine/core/models/baseline.dart';
import 'package:pulseguard/engine/core/models/deviation_flag.dart';
import 'package:pulseguard/engine/core/models/emergency_contact.dart';
import 'package:pulseguard/engine/core/models/escalation_payload.dart';
import 'package:pulseguard/engine/core/models/feature_row.dart';
import 'package:pulseguard/engine/core/models/vitals_reading.dart';

void main() {
  test('VitalsReading round-trips', () {
    const r = VitalsReading(
      timestamp: 123456,
      hr: 72.5,
      hrv: 45.1,
      rr: 14.2,
      spo2: null,
      oxTrend: 1.5,
      quality: 0.9,
      rrQuality: 1.0,
      fingerPresent: true,
      source: VitalsReadingSource.camera,
    );
    final back = VitalsReading.fromJson(r.toJson());
    expect(back.timestamp, r.timestamp);
    expect(back.hr, r.hr);
    expect(back.hrv, r.hrv);
    expect(back.rr, r.rr);
    expect(back.spo2, r.spo2);
    expect(back.oxTrend, r.oxTrend);
    expect(back.quality, r.quality);
    expect(back.rrQuality, r.rrQuality);
    expect(back.fingerPresent, r.fingerPresent);
    expect(back.source, r.source);
  });

  test('VitalsReading round-trips with all-null optional fields', () {
    const r = VitalsReading(
      timestamp: 1,
      hr: null,
      hrv: null,
      rr: null,
      spo2: null,
      oxTrend: null,
      quality: 0,
      rrQuality: 0,
      fingerPresent: false,
      source: VitalsReadingSource.replay,
    );
    final back = VitalsReading.fromJson(r.toJson());
    expect(back.hr, isNull);
    expect(back.source, VitalsReadingSource.replay);
  });

  test('ActivityState round-trips', () {
    const a = ActivityState(
      timestamp: 10,
      state: ActivityStateKind.recovering,
      confidence: 0.8,
      basis: ActivityBasis.accelerometer,
    );
    final back = ActivityState.fromJson(a.toJson());
    expect(back.state, a.state);
    expect(back.basis, a.basis);
    expect(back.confidence, a.confidence);
  });

  test('Baseline round-trips', () {
    const mb = MetricBaseline(
      mean: 72,
      sd: 5,
      variance: 25,
      sdFloorApplied: true,
      sessionCount: 3,
      updatedAt: 1000,
    );
    const b = Baseline(hr: mb, hrv: mb, rr: mb, isDemo: false);
    final back = Baseline.fromJson(b.toJson());
    expect(back.hr.mean, 72);
    expect(back.activityState, ActivityStateKind.resting);
    expect(back.isDemo, false);
  });

  test('DeviationFlag round-trips', () {
    const d = DeviationFlag(
      timestamp: 5,
      system: BodySystem.respiratory,
      deviating: true,
      severity: 0.4,
      metric: 'rr',
      value: 20,
      baseline: 14,
      z: 3.0,
      trusted: true,
      reason: 'Breathing rate 43% above your resting baseline',
      recoveringSuppressed: true,
    );
    final back = DeviationFlag.fromJson(d.toJson());
    expect(back.system, d.system);
    expect(back.deviating, d.deviating);
    expect(back.value, d.value);
    expect(back.recoveringSuppressed, true);
  });

  test('EmergencyContact round-trips', () {
    const c = EmergencyContact(name: 'Alex', phone: '555-0100');
    final back = EmergencyContact.fromJson(c.toJson());
    expect(back.name, 'Alex');
    expect(back.method, 'simulated');
  });

  test('EscalationPayload round-trips', () {
    const vitals = VitalsReading(
      timestamp: 1,
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
    const contact = EmergencyContact(name: 'Alex', phone: '555-0100');
    const payload = EscalationPayload(
      triggeredAt: 100,
      triggerType: EscalationTriggerType.multiSystem,
      systems: [BodySystem.cardiovascular, BodySystem.respiratory],
      reasons: ['HR elevated', 'RR elevated'],
      vitalsSnapshot: vitals,
      contact: contact,
      status: EscalationStatus.pending,
    );
    final back = EscalationPayload.fromJson(payload.toJson());
    expect(back.triggerType, EscalationTriggerType.multiSystem);
    expect(back.systems, payload.systems);
    expect(back.status, EscalationStatus.pending);
    expect(back.vitalsSnapshot.hr, 120);
  });

  test('FeatureRow round-trips', () {
    final row = FeatureRow(
      timestamp: 3,
      values: List.filled(16, 0.5),
      valid: true,
    );
    final back = FeatureRow.fromJson(row.toJson());
    expect(back.values.length, 16);
    expect(back.valid, true);
  });
}
