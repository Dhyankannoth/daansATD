import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:pulseguard/engine/dsp/biquad.dart';
import 'package:pulseguard/engine/dsp/stats.dart' show std;

void main() {
  test('low-pass attenuates a high frequency more than a low one', () {
    const fs = 100.0;
    const n = 500;
    final low = List<double>.generate(
      n,
      (i) => math.sin(2 * math.pi * 1 * i / fs),
    );
    final high = List<double>.generate(
      n,
      (i) => math.sin(2 * math.pi * 30 * i / fs),
    );
    final coeffs = lowPassCoeffs(5.0, fs);
    final lowOut = applyBiquad(low, coeffs);
    final highOut = applyBiquad(high, coeffs);
    final lowRatio = std(lowOut.sublist(100)) / std(low.sublist(100));
    final highRatio = std(highOut.sublist(100)) / std(high.sublist(100));
    expect(lowRatio, greaterThan(highRatio));
  });

  test('high-pass attenuates a low frequency more than a high one', () {
    const fs = 100.0;
    const n = 500;
    final low = List<double>.generate(
      n,
      (i) => math.sin(2 * math.pi * 0.2 * i / fs),
    );
    final high = List<double>.generate(
      n,
      (i) => math.sin(2 * math.pi * 20 * i / fs),
    );
    final coeffs = highPassCoeffs(5.0, fs);
    final lowOut = applyBiquad(low, coeffs);
    final highOut = applyBiquad(high, coeffs);
    final lowRatio = std(lowOut.sublist(100)) / std(low.sublist(100));
    final highRatio = std(highOut.sublist(100)) / std(high.sublist(100));
    expect(highRatio, greaterThan(lowRatio));
  });
}
