import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:pulseguard/engine/dsp/bandpass.dart';
import 'package:pulseguard/engine/dsp/stats.dart' show std;

List<double> _sine(double freqHz, double fs, int n, {double amplitude = 1.0}) {
  return List<double>.generate(
    n,
    (i) => amplitude * math.sin(2 * math.pi * freqHz * i / fs),
  );
}

void main() {
  const fs = 30.0;
  const n = 300; // 10 s
  const lowHz = 0.7;
  const highHz = 3.5;
  const padS = 1.5;

  // Ignore edge artifacts: measure only the middle 60% of samples.
  List<double> middle(List<double> x) =>
      x.sublist((x.length * 0.2).round(), (x.length * 0.8).round());

  test('band-pass keeps most amplitude of an in-band 1.2 Hz sine', () {
    final x = _sine(1.2, fs, n);
    final y = bandpass(x, fs, lowHz: lowHz, highHz: highHz, padS: padS);
    final inAmp = std(middle(x)) * math.sqrt2;
    final outAmp = std(middle(y)) * math.sqrt2;
    expect(outAmp / inAmp, greaterThanOrEqualTo(0.8));
  });

  test('band-pass removes most of an out-of-band 0.1 Hz sine', () {
    final x = _sine(0.1, fs, n);
    final y = bandpass(x, fs, lowHz: lowHz, highHz: highHz, padS: padS);
    final inAmp = std(middle(x)) * math.sqrt2;
    final outAmp = std(middle(y)) * math.sqrt2;
    expect(outAmp / inAmp, lessThanOrEqualTo(0.1));
  });

  test('band-pass removes most of an out-of-band 8 Hz sine', () {
    final x = _sine(8.0, fs, n);
    final y = bandpass(x, fs, lowHz: lowHz, highHz: highHz, padS: padS);
    final inAmp = std(middle(x)) * math.sqrt2;
    final outAmp = std(middle(y)) * math.sqrt2;
    expect(outAmp / inAmp, lessThanOrEqualTo(0.1));
  });
}
