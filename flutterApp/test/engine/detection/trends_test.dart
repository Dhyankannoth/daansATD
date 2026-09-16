import 'package:flutter_test/flutter_test.dart';
import 'package:pulseguard/engine/detection/trends.dart';

void main() {
  test('slopePerMin recovers a known linear trend', () {
    final trends = Trends(windowS: 60, trendMinPoints: 5, mlMetricMinPoints: 5);
    // hr rises 6 bpm/min => 0.1 bpm/s
    for (var t = 0; t <= 30; t++) {
      trends.record('hr', t.toDouble(), 70 + 0.1 * t, true);
    }
    expect(trends.slopePerMin('hr'), closeTo(6.0, 0.2));
  });

  test('slopePerMin is null below trendMinPoints', () {
    final trends = Trends(
      windowS: 60,
      trendMinPoints: 30,
      mlMetricMinPoints: 5,
    );
    trends.record('hr', 0, 70, true);
    trends.record('hr', 1, 71, true);
    expect(trends.slopePerMin('hr'), isNull);
  });

  test('untrusted or null values are not recorded', () {
    final trends = Trends(windowS: 60, trendMinPoints: 2, mlMetricMinPoints: 2);
    trends.record('hr', 0, 70, false);
    trends.record('hr', 1, null, true);
    expect(trends.slopePerMin('hr'), isNull);
  });

  test('values older than the window are pruned', () {
    final trends = Trends(windowS: 10, trendMinPoints: 1, mlMetricMinPoints: 1);
    trends.record('hr', 0, 70, true);
    trends.record('hr', 20, 90, true);
    expect(trends.std('hr'), 0); // only the most recent point remains
  });

  test('std reflects variability once mlMetricMinPoints is reached', () {
    final trends = Trends(windowS: 60, trendMinPoints: 2, mlMetricMinPoints: 3);
    trends.record('hr', 0, 70, true);
    trends.record('hr', 1, 72, true);
    expect(trends.std('hr'), isNull);
    trends.record('hr', 2, 68, true);
    expect(trends.std('hr'), isNotNull);
  });
}
