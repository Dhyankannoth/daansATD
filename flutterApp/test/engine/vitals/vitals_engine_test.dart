import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:pulseguard/engine/core/config/thresholds.dart';
import 'package:pulseguard/engine/core/models/frame_sample.dart';
import 'package:pulseguard/engine/vitals/vitals_engine.dart';

class _FileBundle implements AssetBundleLike {
  @override
  Future<String> loadString(String key) => File(key).readAsString();
}

List<FrameSample> _syntheticBuffer({
  required double bpm,
  required double durationS,
  double fs = 30,
}) {
  final period = 60.0 / bpm;
  final n = (fs * durationS).round();
  return List<FrameSample>.generate(n, (i) {
    final t = i / fs;
    final phase = (t % period) / period;
    final dip = math.exp(-((phase - 0.5) * (phase - 0.5)) / (2 * 0.02));
    final r = 150.0 - 20.0 * dip;
    final g = 100.0 - 12.0 * dip;
    final b = 90.0 - 5.0 * dip;
    return FrameSample(
      t: t,
      r: r,
      g: g,
      b: b,
      valid: true,
      fingerPresent: true,
    );
  });
}

void main() {
  test(
    'end-to-end tick over a 65 s synthetic 72 bpm buffer resolves HR and quality',
    () async {
      final thresholds = await Thresholds.load(bundle: _FileBundle());
      final engine = VitalsEngine(thresholds: thresholds);
      final buffer = _syntheticBuffer(bpm: 72, durationS: 65);

      final reading = engine.tick(buffer: buffer, nowS: 65.0, nowMs: 65000);

      expect(reading.fingerPresent, isTrue);
      expect(reading.hr, isNotNull);
      expect(reading.hr!, closeTo(72.0, 3.0));
      expect(reading.quality, greaterThan(0));
    },
  );

  test('empty buffer yields an all-null, zero-quality reading', () async {
    final thresholds = await Thresholds.load(bundle: _FileBundle());
    final engine = VitalsEngine(thresholds: thresholds);

    final reading = engine.tick(buffer: const [], nowS: 10.0, nowMs: 10000);

    expect(reading.hr, isNull);
    expect(reading.hrv, isNull);
    expect(reading.rr, isNull);
    expect(reading.quality, 0);
    expect(reading.fingerPresent, isFalse);
  });

  test('resetScan clears the oxygenation reference between scans', () async {
    final thresholds = await Thresholds.load(bundle: _FileBundle());
    final engine = VitalsEngine(thresholds: thresholds);
    final buffer = _syntheticBuffer(bpm: 72, durationS: 65);

    engine.tick(buffer: buffer, nowS: 65.0, nowMs: 65000);
    engine.resetScan();
    // Should not throw and should behave like a fresh engine afterward.
    final reading = engine.tick(buffer: buffer, nowS: 65.0, nowMs: 65000);
    expect(reading.oxTrend, isNull); // reference not yet re-established
  });
}
