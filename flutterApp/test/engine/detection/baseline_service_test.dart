import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pulseguard/engine/core/config/thresholds.dart';
import 'package:pulseguard/engine/core/models/baseline.dart';
import 'package:pulseguard/engine/detection/baseline_service.dart';

Thresholds _load() {
  final json = jsonDecode(File('assets/config/thresholds.json').readAsStringSync())
      as Map<String, dynamic>;
  return Thresholds.fromJson(json);
}

void main() {
  test('calibration fails with too few HR ticks', () {
    final service = BaselineService(thresholds: _load());
    final result = service.evaluateSession(
      hrTicks: List.filled(10, 72.0), // below min_ticks_hr (60)
      hrvTicks: List.filled(50, 45.0),
      rrTicks: List.filled(50, 14.0),
      nowMs: 0,
    );
    expect(result.success, isFalse);
    expect(result.failureReason, isNotNull);
  });

  test('successful calibration session aggregates median and std', () {
    final service = BaselineService(thresholds: _load());
    final result = service.evaluateSession(
      hrTicks: List.filled(60, 72.0),
      hrvTicks: List.filled(40, 45.0),
      rrTicks: List.filled(40, 14.0),
      nowMs: 0,
    );
    expect(result.success, isTrue);
    expect(result.hrMedian, 72.0);
    expect(result.hrStd, 0.0);
  });

  test('SD floor is applied when session variability is very low', () {
    final service = BaselineService(thresholds: _load());
    // Constant vitals across the single session -> std = 0, well below floors.
    final session = service.evaluateSession(
      hrTicks: List.filled(60, 72.0),
      hrvTicks: List.filled(40, 45.0),
      rrTicks: List.filled(40, 14.0),
      nowMs: 0,
    );
    final baseline = service.computeBaseline([session], nowMs: 0);
    expect(baseline.hr.sdFloorApplied, isTrue);
    expect(baseline.hr.sd, 5.0); // sd_floor_hr
    expect(baseline.hrv.sdFloorApplied, isTrue);
    expect(baseline.hrv.sd, closeTo(11.25, 1e-9)); // max(8.0, 0.25*45)
    expect(baseline.rr.sdFloorApplied, isTrue);
    expect(baseline.rr.sd, 2.0); // sd_floor_rr
  });

  test('adaptive update applies EMA when all gates pass', () {
    final thresholds = _load();
    final service = BaselineService(thresholds: thresholds);
    const mb = MetricBaseline(
        mean: 72, sd: 5, variance: 25, sdFloorApplied: true, sessionCount: 1, updatedAt: 0);
    const current = Baseline(hr: mb, hrv: mb, rr: mb, isDemo: false);

    final updated = service.adaptiveUpdate(
      current: current,
      hrMedian: 74,
      hrvMedian: 45,
      rrMedian: 14,
      endReason: 'user',
      restingFraction: 0.9,
      maxLevelRank: 1,
      alertOutcome: 'none',
      trustedTicksHr: 40,
      trustedTicksHrv: 40,
      trustedTicksRr: 40,
      isReplay: false,
      nowMs: 1000,
    );

    expect(updated, isNotNull);
    // mean moves 20% of the way from 72 toward 74.
    expect(updated!.hr.mean, closeTo(72.4, 1e-9));
  });

  test('adaptive update is skipped after an escalation (alertOutcome escalated)', () {
    final thresholds = _load();
    final service = BaselineService(thresholds: thresholds);
    const mb = MetricBaseline(
        mean: 72, sd: 5, variance: 25, sdFloorApplied: true, sessionCount: 1, updatedAt: 0);
    const current = Baseline(hr: mb, hrv: mb, rr: mb, isDemo: false);

    final updated = service.adaptiveUpdate(
      current: current,
      hrMedian: 90,
      hrvMedian: 20,
      rrMedian: 25,
      endReason: 'user',
      restingFraction: 0.9,
      maxLevelRank: 4,
      alertOutcome: 'escalated',
      trustedTicksHr: 40,
      trustedTicksHrv: 40,
      trustedTicksRr: 40,
      isReplay: false,
      nowMs: 1000,
    );

    expect(updated, isNull);
  });

  test('adaptive update is skipped for a demo baseline', () {
    final thresholds = _load();
    final service = BaselineService(thresholds: thresholds);
    const mb = MetricBaseline(
        mean: 72, sd: 5, variance: 25, sdFloorApplied: true, sessionCount: 1, updatedAt: 0);
    const current = Baseline(hr: mb, hrv: mb, rr: mb, isDemo: true);

    final updated = service.adaptiveUpdate(
      current: current,
      hrMedian: 74,
      hrvMedian: 45,
      rrMedian: 14,
      endReason: 'user',
      restingFraction: 0.9,
      maxLevelRank: 1,
      alertOutcome: 'none',
      trustedTicksHr: 40,
      trustedTicksHrv: 40,
      trustedTicksRr: 40,
      isReplay: false,
      nowMs: 1000,
    );

    expect(updated, isNull);
  });
}
