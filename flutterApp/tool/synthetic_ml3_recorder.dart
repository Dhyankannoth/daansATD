// Stage 2 of the ML-3 synthetic data pipeline. Reads the intermediate
// per-session physiology JSON written by
// training/ml3/synthetic/generate_physiology.py and replays each session
// tick-by-tick through the REAL production classes — Trends, FeatureBuilder,
// DeviationEngine, FusionEngine, RiskEngine, BaselineService,
// RecordModeWriter — so feature/deviation/risk values are never
// reimplemented here. This is exactly what the app itself computes, just
// fed synthetic input instead of a camera or a replayed trace.
//
// This file is a library, not a `dart run` script — plain `dart run` can't
// resolve `dart:ui` (pulled in transitively via thresholds.dart's use of
// `package:flutter/services.dart` for asset loading), the same constraint
// the app's own engine tests hit. Like them, this runs under `flutter test`
// instead, which does provide `dart:ui`. See
// test/tool/synthetic_ml3_recorder_run_test.dart for the actual entry point:
//
//   SYNTHETIC_OUTPUT_DIR=<output-dir> flutter test test/tool/synthetic_ml3_recorder_run_test.dart
//
// (output-dir must match generate_physiology.py's --output-dir; reads
// <output-dir>/_intermediate/*.json, writes CSVs into <output-dir>/ directly)

import 'dart:convert';
import 'dart:io';

import 'package:pulseguard/engine/core/config/feature_spec.dart';
import 'package:pulseguard/engine/core/config/thresholds.dart';
import 'package:pulseguard/engine/core/models/activity_state.dart';
import 'package:pulseguard/engine/core/models/baseline.dart';
import 'package:pulseguard/engine/core/models/vitals_reading.dart';
import 'package:pulseguard/engine/detection/baseline_service.dart';
import 'package:pulseguard/engine/detection/deviation_engine.dart';
import 'package:pulseguard/engine/detection/fusion_engine.dart';
import 'package:pulseguard/engine/detection/trends.dart';
import 'package:pulseguard/engine/ml/feature_builder.dart';
import 'package:pulseguard/engine/ml/risk_engine.dart';
import 'package:pulseguard/engine/record/record_mode_writer.dart';

/// Reads assets directly off disk instead of through a live Flutter binding
/// — this script runs via plain `dart run`, no Flutter engine attached.
class _FileAssetBundle implements AssetBundleLike {
  @override
  Future<String> loadString(String key) => File(key).readAsString();
}

class _SessionFile {
  _SessionFile(this.personId, this.label, this.startedAtMs, this.ticks, this.meta);

  final String personId;
  final String label;
  final int startedAtMs;
  final List<Map<String, dynamic>> ticks;
  final Map<String, dynamic> meta;

  static _SessionFile fromJson(Map<String, dynamic> j) => _SessionFile(
        j['person_id'] as String,
        j['label'] as String,
        j['started_at_ms'] as int,
        (j['ticks'] as List).cast<Map<String, dynamic>>(),
        (j['meta'] as Map).cast<String, dynamic>(),
      );
}

/// Activity state for a tick within a session, by label — mirrors what the
/// real ActivityGate would settle on for these scenarios (see instructions.md
/// / meeting notes): stress and reaction are physically still (resting
/// motion-wise); recovery sessions start right after exercise, so they're
/// `recovering` throughout; artifact sessions are still too, the problem is
/// signal contact, not gross motion.
ActivityStateKind _activityForLabel(String label) {
  switch (label) {
    case 'recovery':
      return ActivityStateKind.recovering;
    case 'normal_rest':
    case 'stress':
    case 'reaction':
    case 'artifact':
    default:
      return ActivityStateKind.resting;
  }
}

Future<Baseline> _buildBaseline(
  BaselineService baselineService,
  List<_SessionFile> normalRestSessions,
  double trustedQuality,
) async {
  final results = <CalibrationSessionResult>[];
  for (final session in normalRestSessions) {
    final hrTicks = <double>[];
    final hrvTicks = <double>[];
    final rrTicks = <double>[];
    for (final tick in session.ticks) {
      final quality = (tick['quality'] as num).toDouble();
      final rrQuality = (tick['rr_quality'] as num).toDouble();
      if (quality >= trustedQuality && tick['hr'] != null) {
        hrTicks.add((tick['hr'] as num).toDouble());
      }
      if (quality >= trustedQuality && tick['hrv'] != null) {
        hrvTicks.add((tick['hrv'] as num).toDouble());
      }
      if ((quality < rrQuality ? quality : rrQuality) >= trustedQuality && tick['rr'] != null) {
        rrTicks.add((tick['rr'] as num).toDouble());
      }
    }
    final result = baselineService.evaluateSession(
      hrTicks: hrTicks,
      hrvTicks: hrvTicks,
      rrTicks: rrTicks,
      nowMs: session.startedAtMs,
    );
    if (result.success) results.add(result);
  }
  if (results.isEmpty) {
    throw StateError('no successful normal_rest calibration sessions — cannot build a baseline');
  }
  return baselineService.computeBaseline(results, nowMs: results.last.timestamp);
}

Future<void> _recordSession(
  _SessionFile session,
  Baseline baseline,
  Thresholds thresholds,
  FeatureSpec featureSpec,
  String outputDir,
) async {
  final trends = Trends(
    windowS: thresholds.windowsS.trend,
    trendMinPoints: thresholds.trend.minPoints,
    mlMetricMinPoints: thresholds.ml.metricMinPoints,
  );
  final deviationEngine = DeviationEngine(thresholds: thresholds);
  final fusionEngine = FusionEngine(thresholds: thresholds);
  final riskEngine = RiskEngine(thresholds: thresholds);
  final featureBuilder = FeatureBuilder(thresholds: thresholds);

  final writer = RecordModeWriter(
    documentsDirProvider: () async => Directory(outputDir),
    featureNames: featureSpec.featureNames,
  );

  final activity = _activityForLabel(session.label);
  final activityState = ActivityState(
    timestamp: session.startedAtMs,
    state: activity,
    confidence: 1.0,
    basis: ActivityBasis.selfReport,
  );

  final isRecovery = session.label == 'recovery';
  final timeSinceExerciseS = isRecovery ? 0.0 : null;

  final meta = Map<String, dynamic>.from(session.meta)
    ..['synthetic'] = true
    ..['generator'] = 'training/ml3/synthetic/generate_physiology.py + tool/synthetic_ml3_recorder.dart';
  if (isRecovery && session.meta['back_to_baseline_s'] != null) {
    final backS = (session.meta['back_to_baseline_s'] as num).toDouble();
    meta['back_to_baseline_timestamp'] = session.startedAtMs + (backS * 1000).round();
  }

  await writer.start(
    label: session.label,
    personId: session.personId,
    deviceLabel: 'synthetic',
    nowMs: session.startedAtMs,
    meta: meta,
  );

  for (final tick in session.ticks) {
    final t = (tick['t'] as num).toDouble();
    final nowMs = session.startedAtMs + (t * 1000).round();
    final hr = (tick['hr'] as num?)?.toDouble();
    final hrv = (tick['hrv'] as num?)?.toDouble();
    final rr = (tick['rr'] as num?)?.toDouble();
    final quality = (tick['quality'] as num).toDouble();
    final rrQuality = (tick['rr_quality'] as num).toDouble();
    final fingerPresent = tick['finger_present'] as bool;

    final reading = VitalsReading(
      timestamp: nowMs,
      hr: hr,
      hrv: hrv,
      rr: rr,
      spo2: null,
      oxTrend: null,
      quality: quality,
      rrQuality: rrQuality,
      fingerPresent: fingerPresent,
      source: VitalsReadingSource.replay,
    );

    final hrTrusted = quality >= thresholds.quality.trusted;
    final rrTrusted = (quality < rrQuality ? quality : rrQuality) >= thresholds.quality.trusted;
    trends.record('hr', t, hr, hrTrusted);
    trends.record('hrv', t, hrv, hrTrusted); // HRV shares HR's quality gate, per DeviationEngine
    trends.record('rr', t, rr, rrTrusted);

    final featureRow = featureBuilder.build(
      nowS: t,
      nowMs: nowMs,
      reading: reading,
      baseline: baseline,
      activity: activity,
      trends: trends,
      timeSinceExerciseS: timeSinceExerciseS,
      elapsedScanS: t,
    );

    final flags = deviationEngine.evaluate(
      reading: reading,
      baseline: baseline,
      activity: activity,
      trends: trends,
      nowMs: nowMs,
    );

    final fusion = fusionEngine.evaluate(
      flags: flags,
      fingerPresent: fingerPresent,
      scanEndedByUser: false,
      inCooldown: false,
      nowS: t,
      nowMs: nowMs,
    );

    final risk = riskEngine.evaluate(
      nowS: t,
      nowMs: nowMs,
      flags: flags,
      fusion: fusion,
      anomalyScoreRaw: null, // no trained model exists yet — matches real "rules-only" behavior
      riskProbabilityRaw: null,
      alertEscalated: false,
    );

    writer.writeTick(vitals: reading, activity: activityState, featureRow: featureRow, risk: risk);
  }

  await writer.stop();
}

/// Entry point called from test/tool/synthetic_ml3_recorder_run_test.dart.
Future<void> run(String outputDir) async {
  final intermediateDir = Directory('$outputDir/_intermediate');
  if (!intermediateDir.existsSync()) {
    throw StateError('no such directory: ${intermediateDir.path} — run generate_physiology.py first');
  }

  final bundle = _FileAssetBundle();
  final thresholds = await Thresholds.load(bundle: bundle);
  final featureSpec = await FeatureSpec.load(bundle: bundle);
  final baselineService = BaselineService(thresholds: thresholds);

  final files = intermediateDir.listSync().whereType<File>().where((f) => f.path.endsWith('.json')).toList();
  final sessions = files.map((f) => _SessionFile.fromJson(jsonDecode(f.readAsStringSync()) as Map<String, dynamic>)).toList();

  final byPerson = <String, List<_SessionFile>>{};
  for (final s in sessions) {
    byPerson.putIfAbsent(s.personId, () => []).add(s);
  }

  var sessionCount = 0;
  for (final entry in byPerson.entries) {
    final personId = entry.key;
    final personSessions = entry.value;
    final normalRest = personSessions.where((s) => s.label == 'normal_rest').toList();

    final Baseline baseline;
    try {
      baseline = await _buildBaseline(baselineService, normalRest, thresholds.quality.trusted);
    } catch (e) {
      stderr.writeln('$personId: skipping entirely — $e');
      continue;
    }

    for (final session in personSessions) {
      await _recordSession(session, baseline, thresholds, featureSpec, outputDir);
      sessionCount++;
    }
    stdout.writeln('$personId: baseline hr=${baseline.hr.mean.toStringAsFixed(1)}'
        '±${baseline.hr.sd.toStringAsFixed(1)}, recorded ${personSessions.length} sessions');
  }

  stdout.writeln('wrote $sessionCount session CSVs to $outputDir');
}
