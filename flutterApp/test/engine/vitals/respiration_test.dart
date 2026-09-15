import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:pulseguard/engine/dsp/resample.dart' show binAverage, resampleLinear;
import 'package:pulseguard/engine/dsp/spectrum.dart' show dominantRate;
import 'package:pulseguard/engine/vitals/respiration.dart';

void main() {
  const respHz = 4.0;
  const respBand = [0.1, 0.6];
  const respStep = 0.005;
  const minProminence = 3.0;

  test('72 bpm PPG with 0.25 Hz respiratory modulation resolves RR ~15 with quality 1.0',
      () {
    const fs = 30.0;
    const durationS = 60.0;
    const heartHz = 72.0 / 60.0;
    const respFreqHz = 0.25; // 15 breaths/min

    final n = (fs * durationS).round();
    // Intensity channel: slow breathing-driven baseline wander (dominant)
    // plus a small heartbeat ripple (mostly averaged out by binning).
    final intensity = List<double>.generate(n, (i) {
      final t = i / fs;
      final breath = math.sin(2 * math.pi * respFreqHz * t);
      final heartRipple = 0.1 * math.sin(2 * math.pi * heartHz * t);
      return breath + heartRipple;
    });
    final intensityBinned = binAverage(intensity, fs, 1.0 / respHz);
    final intensityResult = dominantRate(intensityBinned, respHz, respBand, respStep,
        minSamples: (32 * respHz).round());

    // Interval channel: beat interval duration modulated +/-40ms by breathing.
    final baseInterval = 1 / heartHz;
    final beatTimes = <double>[0];
    while (beatTimes.last < durationS) {
      final t = beatTimes.last;
      final mod = 0.04 * math.sin(2 * math.pi * respFreqHz * t);
      beatTimes.add(t + baseInterval + mod);
    }
    final intervalTimes = <double>[];
    final intervalValues = <double>[];
    for (var i = 1; i < beatTimes.length; i++) {
      intervalTimes.add(beatTimes[i]);
      intervalValues.add(beatTimes[i] - beatTimes[i - 1]);
    }
    final intervalGrid =
        resampleLinear(intervalTimes, intervalValues, respHz, 0, durationS);
    final intervalResult = dominantRate(intervalGrid, respHz, respBand, respStep,
        minSamples: (32 * respHz).round());

    final result = computeRr(
      intensityResult: intensityResult,
      intervalResult: intervalResult,
      minProminence: minProminence,
      agreeBpm: 3.0,
      agreeQuality: 1.0,
      singleQuality: 0.6,
    );

    expect(result.rr, isNotNull);
    expect(result.rr!, closeTo(15.0, 1.5));
    expect(result.rrQuality, 1.0);
  });

  test('pure noise yields no RR', () {
    // Fixed seed chosen so the periodogram's peak-to-mean ratio (across the
    // ~100 bins in the respiratory band) stays below minProminence, as it
    // would for most realistic noise once both channels must agree.
    final rnd = math.Random(11);
    final noise = List<double>.generate(400, (_) => rnd.nextDouble() * 2 - 1);
    final result = dominantRate(noise, respHz, respBand, respStep,
        minSamples: (32 * respHz).round());
    expect(result!.prominence, lessThan(minProminence));

    final combined = computeRr(
      intensityResult: result,
      intervalResult: null,
      minProminence: minProminence,
      agreeBpm: 3.0,
      agreeQuality: 1.0,
      singleQuality: 0.6,
    );
    expect(combined.rr, isNull);
    expect(combined.rrQuality, 0);
  });
}
