import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pulseguard/engine/core/config/thresholds.dart';
import 'package:pulseguard/engine/core/models/activity_state.dart';
import 'package:pulseguard/engine/core/models/baseline.dart';
import 'package:pulseguard/engine/core/models/vitals_reading.dart';
import 'package:pulseguard/engine/detection/trends.dart';
import 'package:pulseguard/engine/ml/feature_builder.dart';

Thresholds _load() {
  final json = jsonDecode(File('assets/config/thresholds.json').readAsStringSync())
      as Map<String, dynamic>;
  return Thresholds.fromJson(json);
}

void main() {
  test('row gate rejects until enough trusted history accumulates, then '
      'produces exact feature values', () {
    final thresholds = _load();
    const mb72 = MetricBaseline(
        mean: 72, sd: 5, variance: 25, sdFloorApplied: false, sessionCount: 3, updatedAt: 0);
    const mb45 = MetricBaseline(
        mean: 45, sd: 8, variance: 64, sdFloorApplied: false, sessionCount: 3, updatedAt: 0);
    const mb14 = MetricBaseline(
        mean: 14, sd: 2, variance: 4, sdFloorApplied: false, sessionCount: 3, updatedAt: 0);
    const baseline = Baseline(hr: mb72, hrv: mb45, rr: mb14, isDemo: false);

    final trends = Trends(
      windowS: thresholds.windowsS.trend,
      trendMinPoints: thresholds.trend.minPoints,
      mlMetricMinPoints: thresholds.ml.metricMinPoints,
    );
    final builder = FeatureBuilder(thresholds: thresholds);

    VitalsReading reading(int t) => VitalsReading(
          timestamp: t * 1000,
          hr: 80,
          hrv: 45,
          rr: 14,
          spo2: null,
          oxTrend: null,
          quality: 0.9,
          rrQuality: 0.9,
          fingerPresent: true,
          source: VitalsReadingSource.camera,
        );

    var lastRow = builder.build(
      nowS: 0,
      nowMs: 0,
      reading: reading(0),
      baseline: baseline,
      activity: ActivityStateKind.resting,
      trends: trends,
      timeSinceExerciseS: null,
      elapsedScanS: 0,
    );
    // Not enough trend/trust history yet.
    expect(lastRow.valid, isFalse);

    for (var t = 0; t < 60; t++) {
      trends.record('hr', t.toDouble(), 80, true);
      trends.record('hrv', t.toDouble(), 45, true);
      trends.record('rr', t.toDouble(), 14, true);
      lastRow = builder.build(
        nowS: t.toDouble(),
        nowMs: t * 1000,
        reading: reading(t),
        baseline: baseline,
        activity: ActivityStateKind.resting,
        trends: trends,
        timeSinceExerciseS: null,
        elapsedScanS: t.toDouble(),
      );
    }

    expect(lastRow.valid, isTrue);
    expect(lastRow.values.length, 16);
    expect(lastRow.values[0], closeTo(1.6, 1e-9)); // hr_z = (80-72)/5
    expect(lastRow.values[1], closeTo(0.0, 1e-9)); // hrv_z
    expect(lastRow.values[2], closeTo(0.0, 1e-9)); // rr_z
    expect(lastRow.values[3], closeTo(0.0, 1e-9)); // hr_slope_z (constant hr)
    expect(lastRow.values[6], closeTo(0.0, 1e-9)); // hr_var_z (constant hr)
    expect(lastRow.values[9], closeTo(8.0 / 72.0, 1e-9)); // hr_pct
    expect(lastRow.values[12], 1.0); // is_resting
    expect(lastRow.values[13], 0.0); // is_recovering
    expect(lastRow.values[14], 0.0); // is_unknown
    expect(lastRow.values[15], 1.0); // since_exercise (no exercise)
  });

  test('missing baseline always yields an invalid row', () {
    final thresholds = _load();
    final trends = Trends(
      windowS: thresholds.windowsS.trend,
      trendMinPoints: thresholds.trend.minPoints,
      mlMetricMinPoints: thresholds.ml.metricMinPoints,
    );
    final builder = FeatureBuilder(thresholds: thresholds);
    const reading = VitalsReading(
      timestamp: 0,
      hr: 80,
      hrv: 45,
      rr: 14,
      spo2: null,
      oxTrend: null,
      quality: 0.9,
      rrQuality: 0.9,
      fingerPresent: true,
      source: VitalsReadingSource.camera,
    );
    final row = builder.build(
      nowS: 0,
      nowMs: 0,
      reading: reading,
      baseline: null,
      activity: ActivityStateKind.resting,
      trends: trends,
      timeSinceExerciseS: null,
      elapsedScanS: 0,
    );
    expect(row.valid, isFalse);
  });
}
