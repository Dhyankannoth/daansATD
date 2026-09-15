import 'package:flutter_test/flutter_test.dart';
import 'package:pulseguard/engine/dsp/resample.dart';

void main() {
  test('resampleLinear of a ramp is exact', () {
    // source: value = 2*t, sampled irregularly
    final times = [0.0, 0.3, 0.7, 1.0, 1.5, 2.0];
    final values = times.map((t) => 2 * t).toList();
    final out = resampleLinear(times, values, 10, 0, 2.0);
    for (var i = 0; i < out.length; i++) {
      final t = i / 10;
      expect(out[i], closeTo(2 * t, 1e-9));
    }
  });

  test(
    'resampleLinear flat-extrapolates before first and after last sample',
    () {
      final times = [1.0, 2.0];
      final values = [10.0, 20.0];
      final out = resampleLinear(times, values, 1, 0.0, 3.0);
      expect(out.first, 10.0);
      expect(out.last, 20.0);
    },
  );

  test('binAverage averages fixed-size bins', () {
    final values = List<double>.generate(10, (i) => i.toDouble());
    final out = binAverage(values, 10, 0.5); // bins of 5 samples
    expect(out.length, 2);
    expect(out[0], closeTo(2.0, 1e-9)); // mean of 0..4
    expect(out[1], closeTo(7.0, 1e-9)); // mean of 5..9
  });
}
