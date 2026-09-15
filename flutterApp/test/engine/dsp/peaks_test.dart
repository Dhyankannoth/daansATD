import 'package:flutter_test/flutter_test.dart';
import 'package:pulseguard/engine/dsp/peaks.dart';

void main() {
  test('parabolic refinement recovers a known sub-sample peak within 0.05 samples', () {
    // Sample a true parabola y = -(i - i0)^2 at integer i near the vertex.
    const i0 = 10.4;
    double f(int i) => -((i - i0) * (i - i0));
    final offset = parabolicPeakOffset(f(9), f(10), f(11));
    final recovered = 10 + offset;
    expect((recovered - i0).abs(), lessThan(0.05));
  });

  test('parabolic refinement returns 0 for a flat (degenerate) window', () {
    expect(parabolicPeakOffset(1.0, 1.0, 1.0), 0);
  });

  test('findBeats detects evenly spaced synthetic dips', () {
    const fs = 30.0;
    const periodS = 0.8; // 75 bpm
    final n = (fs * 6).round();
    final filtered = List<double>.generate(n, (i) {
      final t = i / fs;
      final phase = (t % periodS) / periodS;
      // Sharp dip near phase 0.5 of each cycle.
      final dip = -1.0 * (1 - ((phase - 0.5).abs() * 2)).clamp(0.0, 1.0);
      return dip;
    });
    final beats = findBeats(filtered, fs,
        minGapS: 0.3, minHeightSd: 0.3, edgeIgnoreS: 0.3);
    expect(beats.length, greaterThan(3));
    for (var i = 1; i < beats.length; i++) {
      expect(beats[i] - beats[i - 1], closeTo(periodS, 0.15));
    }
  });
}
