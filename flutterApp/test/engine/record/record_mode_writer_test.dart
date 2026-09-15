import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pulseguard/engine/api/events.dart';
import 'package:pulseguard/engine/core/models/activity_state.dart';
import 'package:pulseguard/engine/core/models/deviation_flag.dart';
import 'package:pulseguard/engine/core/models/feature_row.dart';
import 'package:pulseguard/engine/core/models/vitals_reading.dart';
import 'package:pulseguard/engine/record/record_mode_writer.dart';

DeviationFlag _flag(BodySystem s, bool deviating) => DeviationFlag(
  timestamp: 0,
  system: s,
  deviating: deviating,
  severity: 0,
  metric: s.name,
  value: null,
  baseline: 0,
  z: null,
  trusted: true,
  reason: '',
);

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('pulseguard_record_test');
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  test('header matches spec and nulls are written as empty cells', () async {
    final writer = RecordModeWriter(
      documentsDirProvider: () async => tempDir,
      featureNames: List.generate(16, (i) => 'f$i'),
    );

    await writer.start(
      label: 'normal_rest',
      personId: 'p1',
      nowMs: 1700000000000,
      meta: {'thresholds_version': 1, 'feature_spec_version': 1},
    );

    const vitals = VitalsReading(
      timestamp: 1700000000000,
      hr: null,
      hrv: null,
      rr: null,
      spo2: null,
      oxTrend: null,
      quality: 0,
      rrQuality: 0,
      fingerPresent: false,
      source: VitalsReadingSource.camera,
    );
    const activity = ActivityState(
      timestamp: 0,
      state: ActivityStateKind.resting,
      confidence: 1.0,
      basis: ActivityBasis.accelerometer,
    );
    final featureRow = FeatureRow(timestamp: 0, values: const [], valid: false);
    final risk = RiskAssessment(
      timestamp: 0,
      level: RiskLevel.normal,
      statusText: 'All systems normal',
      flags: [
        _flag(BodySystem.cardiovascular, false),
        _flag(BodySystem.respiratory, false),
        _flag(BodySystem.autonomic, false),
      ],
      persistentSystems: const [],
      anomalyScore: null,
      riskProbability: null,
      mlActive: false,
      recoveringSuppressed: false,
      reasons: const [],
    );

    writer.writeTick(
      vitals: vitals,
      activity: activity,
      featureRow: featureRow,
      risk: risk,
    );
    final result = await writer.stop();

    final lines = File(result.csvPath).readAsLinesSync();
    expect(lines.length, 2); // header + 1 row
    final header = lines[0].split(',');
    expect(header.first, 'session_id');
    expect(header, contains('f0'));
    expect(header, contains('f15'));
    expect(header.last, 'auto_dev');

    final cells = lines[1].split(',');
    final hrIdx = header.indexOf('hr');
    expect(cells[hrIdx], ''); // null written as empty cell

    // meta.json exists and round-trips.
    final meta = jsonDecode(File(result.metaPath).readAsStringSync());
    expect(meta['thresholds_version'], 1);
  });

  test('rejects a label outside the allowed set', () async {
    final writer = RecordModeWriter(
      documentsDirProvider: () async => tempDir,
      featureNames: const [],
    );
    expect(
      () => writer.start(
        label: 'bogus',
        personId: 'p1',
        nowMs: 0,
        meta: const {},
      ),
      throwsArgumentError,
    );
  });

  test('includeRawSamples writes a second _raw.csv file', () async {
    final writer = RecordModeWriter(
      documentsDirProvider: () async => tempDir,
      featureNames: const [],
    );
    await writer.start(
      label: 'artifact',
      personId: 'p2',
      includeRawSamples: true,
      nowMs: 1700000000000,
      meta: const {},
    );
    writer.writeRawSample(
      t: 1.0,
      r: 100,
      g: 50,
      b: 40,
      satFrac: 0,
      valid: true,
      fingerPresent: true,
      motionStd: 0.1,
    );
    final result = await writer.stop();
    expect(result.rawCsvPath, isNotNull);
    expect(File(result.rawCsvPath!).existsSync(), isTrue);
    final rawLines = File(result.rawCsvPath!).readAsLinesSync();
    expect(rawLines.first, 't,r,g,b,sat_frac,valid,finger_present,motion_std');
    expect(rawLines.length, 2);
  });
}
