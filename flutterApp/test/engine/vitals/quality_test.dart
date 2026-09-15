import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:pulseguard/engine/vitals/quality.dart';

void main() {
  test('clean correlated signal scores >= 0.7', () {
    final red = List<double>.generate(90, (i) => math.sin(2 * math.pi * 1.2 * i / 30));
    final green = List<double>.generate(90, (i) => 0.8 * math.sin(2 * math.pi * 1.2 * i / 30));
    final q = computeQuality(
      hrWindowOk: true,
      validFrac: 1.0,
      keptFrac: 1.0,
      filteredRed: red,
      filteredGreen: green,
    );
    expect(q, greaterThanOrEqualTo(0.7));
  });

  test('independent noise on red and green scores < 0.4', () {
    final r1 = math.Random(1);
    final r2 = math.Random(2);
    final red = List<double>.generate(90, (_) => r1.nextDouble() * 2 - 1);
    final green = List<double>.generate(90, (_) => r2.nextDouble() * 2 - 1);
    final q = computeQuality(
      hrWindowOk: true,
      validFrac: 1.0,
      keptFrac: 1.0,
      filteredRed: red,
      filteredGreen: green,
    );
    expect(q, lessThan(0.4));
  });

  test('failed HR window forces quality to 0', () {
    final red = List<double>.generate(90, (i) => math.sin(2 * math.pi * 1.2 * i / 30));
    final green = List<double>.generate(90, (i) => math.sin(2 * math.pi * 1.2 * i / 30));
    final q = computeQuality(
      hrWindowOk: false,
      validFrac: 1.0,
      keptFrac: 1.0,
      filteredRed: red,
      filteredGreen: green,
    );
    expect(q, 0);
  });
}
