import 'package:flutter_test/flutter_test.dart';
import 'package:pulseguard/engine/vitals/oxygenation.dart';

void main() {
  test('ratio is computed exactly from known AC/DC per channel', () {
    final tracker = OxygenationTracker(referenceWindows: 10);
    // AC_r/DC_r = 2/10 = 0.2; AC_g/DC_g = 1/20 = 0.05; ratio = 0.2/0.05 = 4.0
    final result = tracker.tick(
      acRed: 2,
      dcRed: 10,
      acGreen: 1,
      dcGreen: 20,
      qualityTrusted: true,
    );
    expect(result.ratio, closeTo(4.0, 1e-9));
  });

  test('oxTrend is null until the reference window fills', () {
    final tracker = OxygenationTracker(referenceWindows: 3);
    for (var i = 0; i < 2; i++) {
      final r = tracker.tick(
          acRed: 2, dcRed: 10, acGreen: 1, dcGreen: 20, qualityTrusted: true);
      expect(r.oxTrend, isNull);
    }
    final r3 = tracker.tick(
        acRed: 2, dcRed: 10, acGreen: 1, dcGreen: 20, qualityTrusted: true);
    // Reference now set (median of the 3 identical ratios = 4.0); trend = 0%.
    expect(r3.oxTrend, closeTo(0.0, 1e-9));
  });

  test('spo2 stays null without a calibration', () {
    final tracker = OxygenationTracker(referenceWindows: 1);
    final r = tracker.tick(
        acRed: 2, dcRed: 10, acGreen: 1, dcGreen: 20, qualityTrusted: true);
    expect(r.spo2, isNull);
  });

  test('untrusted quality tick yields all-null result and does not seed the reference',
      () {
    final tracker = OxygenationTracker(referenceWindows: 1);
    final r = tracker.tick(
        acRed: 2, dcRed: 10, acGreen: 1, dcGreen: 20, qualityTrusted: false);
    expect(r.ratio, isNull);
    expect(r.oxTrend, isNull);
    expect(tracker.reference, isNull);
  });

  test('reset clears the reference', () {
    final tracker = OxygenationTracker(referenceWindows: 1);
    tracker.tick(acRed: 2, dcRed: 10, acGreen: 1, dcGreen: 20, qualityTrusted: true);
    expect(tracker.reference, isNotNull);
    tracker.reset();
    expect(tracker.reference, isNull);
  });
}
