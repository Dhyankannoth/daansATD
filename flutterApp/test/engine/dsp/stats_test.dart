import 'package:flutter_test/flutter_test.dart';
import 'package:pulseguard/engine/dsp/stats.dart';

void main() {
  test('lsqSlope recovers a known line', () {
    final xs = [0.0, 1.0, 2.0, 3.0, 4.0];
    final ys = [1.0, 3.0, 5.0, 7.0, 9.0]; // y = 1 + 2x
    expect(lsqSlope(xs, ys), closeTo(2.0, 1e-9));
  });

  test('mean/median/std basic', () {
    final xs = [1.0, 2.0, 3.0, 4.0];
    expect(mean(xs), 2.5);
    expect(median(xs), 2.5);
    expect(std(xs), closeTo(1.1180339887, 1e-6));
  });

  test('pearson correlation of identical series is 1', () {
    final xs = [1.0, 2.0, 3.0, 4.0, 5.0];
    expect(pearson(xs, xs), closeTo(1.0, 1e-9));
  });

  test('pearson correlation of independent noise is near 0', () {
    final rng = List<double>.generate(200, (i) => (i * 37 % 101).toDouble());
    final rng2 = List<double>.generate(200, (i) => (i * 53 % 97).toDouble());
    expect(pearson(rng, rng2).abs(), lessThan(0.3));
  });

  test('percentile at 50 matches median', () {
    final xs = [5.0, 1.0, 3.0, 2.0, 4.0];
    expect(percentile(xs, 50), closeTo(median(xs), 1e-9));
  });
}
