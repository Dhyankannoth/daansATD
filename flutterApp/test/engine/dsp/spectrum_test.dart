import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:pulseguard/engine/dsp/spectrum.dart';

void main() {
  test('dominantRate finds a known respiratory-band frequency', () {
    const fs = 4.0;
    const trueHz = 0.25; // 15 bpm
    final n = (fs * 60).round(); // 60 s
    final x = List<double>.generate(
        n, (i) => math.sin(2 * math.pi * trueHz * i / fs));
    final result = dominantRate(x, fs, [0.1, 0.6], 0.005, minSamples: 32);
    expect(result, isNotNull);
    expect(result!.freqHz, closeTo(trueHz, 0.01));
    expect(result.bpm, closeTo(15.0, 0.6));
    expect(result.prominence, greaterThan(1.0));
  });

  test('dominantRate returns null below minSamples', () {
    final x = List<double>.generate(10, (i) => i.toDouble());
    final result = dominantRate(x, 4.0, [0.1, 0.6], 0.01, minSamples: 32);
    expect(result, isNull);
  });
}
