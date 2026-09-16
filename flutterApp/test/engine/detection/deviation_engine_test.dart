import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pulseguard/engine/core/config/thresholds.dart';
import 'package:pulseguard/engine/core/models/activity_state.dart';
import 'package:pulseguard/engine/core/models/baseline.dart';
import 'package:pulseguard/engine/core/models/deviation_flag.dart';
import 'package:pulseguard/engine/core/models/vitals_reading.dart';
import 'package:pulseguard/engine/detection/deviation_engine.dart';
import 'package:pulseguard/engine/detection/trends.dart';

Thresholds _load() {
  final json =
      jsonDecode(File('assets/config/thresholds.json').readAsStringSync())
          as Map<String, dynamic>;
  return Thresholds.fromJson(json);
}

const _mb72 = MetricBaseline(
  mean: 72,
  sd: 5,
  variance: 25,
  sdFloorApplied: true,
  sessionCount: 3,
  updatedAt: 0,
);
const _mb45 = MetricBaseline(
  mean: 45,
  sd: 8,
  variance: 64,
  sdFloorApplied: true,
  sessionCount: 3,
  updatedAt: 0,
);
const _mb14 = MetricBaseline(
  mean: 14,
  sd: 2,
  variance: 4,
  sdFloorApplied: true,
  sessionCount: 3,
  updatedAt: 0,
);
const _baseline = Baseline(hr: _mb72, hrv: _mb45, rr: _mb14, isDemo: false);

VitalsReading _reading({
  double? hr,
  double? hrv,
  double? rr,
  double quality = 0.9,
}) {
  return VitalsReading(
    timestamp: 0,
    hr: hr,
    hrv: hrv,
    rr: rr,
    spo2: null,
    oxTrend: null,
    quality: quality,
    rrQuality: quality,
    fingerPresent: true,
    source: VitalsReadingSource.camera,
  );
}

void main() {
  test('HR beyond hr_z SDs above baseline is flagged deviating at rest', () {
    final engine = DeviationEngine(thresholds: _load());
    final trends = Trends(
      windowS: 60,
      trendMinPoints: 30,
      mlMetricMinPoints: 20,
    );
    // z = (85-72)/5 = 2.6 >= hr_z (2.5)
    final flags = engine.evaluate(
      reading: _reading(hr: 85, hrv: 45, rr: 14),
      baseline: _baseline,
      activity: ActivityStateKind.resting,
      trends: trends,
      nowMs: 0,
    );
    final cardio = flags.firstWhere(
      (f) => f.system == BodySystem.cardiovascular,
    );
    expect(cardio.deviating, isTrue);
    expect(cardio.trusted, isTrue);
    expect(cardio.reason, contains('HR'));
  });

  test('untrusted (low quality) tick never deviates', () {
    final engine = DeviationEngine(thresholds: _load());
    final trends = Trends(
      windowS: 60,
      trendMinPoints: 30,
      mlMetricMinPoints: 20,
    );
    final flags = engine.evaluate(
      reading: _reading(hr: 130, hrv: 10, rr: 30, quality: 0.1),
      baseline: _baseline,
      activity: ActivityStateKind.resting,
      trends: trends,
      nowMs: 0,
    );
    for (final f in flags) {
      expect(f.deviating, isFalse);
      expect(f.trusted, isFalse);
    }
  });

  test('recovering activity suppresses HR deviation when HR is falling', () {
    final engine = DeviationEngine(thresholds: _load());
    final trends = Trends(
      windowS: 60,
      trendMinPoints: 2,
      mlMetricMinPoints: 20,
    );
    // Falling HR trend: slope well below recovering_hr_slope (-1.0 bpm/min).
    trends.record('hr', 0, 100, true);
    trends.record('hr', 30, 85, true); // -30 bpm over 30s = -60 bpm/min

    final flags = engine.evaluate(
      reading: _reading(hr: 85, hrv: 45, rr: 14),
      baseline: _baseline,
      activity: ActivityStateKind.recovering,
      trends: trends,
      nowMs: 60000,
    );
    final cardio = flags.firstWhere(
      (f) => f.system == BodySystem.cardiovascular,
    );
    expect(cardio.deviating, isFalse);
    expect(cardio.recoveringSuppressed, isTrue);
    expect(cardio.reason, contains('recovery'));
  });

  test('recovering activity keeps HR deviating when HR is not falling', () {
    final engine = DeviationEngine(thresholds: _load());
    final trends = Trends(
      windowS: 60,
      trendMinPoints: 2,
      mlMetricMinPoints: 20,
    );
    // Flat/rising HR trend: slope above recovering_hr_slope (-1.0).
    trends.record('hr', 0, 85, true);
    trends.record('hr', 30, 85, true);

    final flags = engine.evaluate(
      reading: _reading(hr: 85, hrv: 45, rr: 14),
      baseline: _baseline,
      activity: ActivityStateKind.recovering,
      trends: trends,
      nowMs: 60000,
    );
    final cardio = flags.firstWhere(
      (f) => f.system == BodySystem.cardiovascular,
    );
    expect(cardio.deviating, isTrue);
    expect(cardio.recoveringSuppressed, isFalse);
  });

  test('no baseline means every flag is untrusted with "No baseline yet"', () {
    final engine = DeviationEngine(thresholds: _load());
    final trends = Trends(
      windowS: 60,
      trendMinPoints: 30,
      mlMetricMinPoints: 20,
    );
    final flags = engine.evaluate(
      reading: _reading(hr: 85, hrv: 20, rr: 30),
      baseline: null,
      activity: ActivityStateKind.resting,
      trends: trends,
      nowMs: 0,
    );
    for (final f in flags) {
      expect(f.trusted, isFalse);
      expect(f.reason, 'No baseline yet');
    }
  });

  test('low HRV below hrv_z SDs is flagged deviating (autonomic)', () {
    final engine = DeviationEngine(thresholds: _load());
    final trends = Trends(
      windowS: 60,
      trendMinPoints: 30,
      mlMetricMinPoints: 20,
    );
    // z = (29-45)/8 = -2.0 <= hrv_z (-2.0)
    final flags = engine.evaluate(
      reading: _reading(hr: 72, hrv: 29, rr: 14),
      baseline: _baseline,
      activity: ActivityStateKind.resting,
      trends: trends,
      nowMs: 0,
    );
    final auto = flags.firstWhere((f) => f.system == BodySystem.autonomic);
    expect(auto.deviating, isTrue);
  });
}
