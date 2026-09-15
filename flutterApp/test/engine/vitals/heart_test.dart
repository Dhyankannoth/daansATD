import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:pulseguard/engine/dsp/peaks.dart' show findBeats;
import 'package:pulseguard/engine/vitals/heart.dart';

List<double> _jitteredBeats({
  required double bpm,
  required double durationS,
  double jitterFrac = 0.03,
  int seed = 42,
}) {
  final period = 60.0 / bpm;
  final rnd = math.Random(seed);
  final beats = <double>[];
  var t = period / 2;
  while (t < durationS) {
    beats.add(t);
    final jitter = (rnd.nextDouble() * 2 - 1) * jitterFrac * period;
    t += period + jitter;
  }
  return beats;
}

List<double> _dipSignal(
  List<double> beatTimes,
  double fs,
  double durationS, {
  double width = 0.08,
}) {
  final n = (durationS * fs).round();
  final out = List<double>.filled(n, 0.0);
  for (var i = 0; i < n; i++) {
    final t = i / fs;
    var val = 0.0;
    for (final bt in beatTimes) {
      final dt = t - bt;
      if (dt.abs() > width * 4) continue;
      val += -math.exp(-(dt * dt) / (2 * width * width));
    }
    out[i] = val;
  }
  return out;
}

void main() {
  const fs = 30.0;
  const durationS = 12.0;

  group('computeHr from synthetic jittered PPG', () {
    for (final bpm in [60.0, 72.0, 110.0]) {
      test('$bpm bpm recovered within +/-2 bpm', () {
        final beats = _jitteredBeats(bpm: bpm, durationS: durationS);
        final signal = _dipSignal(beats, fs, durationS);
        final detected = findBeats(
          signal,
          fs,
          minGapS: 0.3,
          minHeightSd: 0.3,
          edgeIgnoreS: 0.3,
        );
        final result = computeHr(
          detected,
          ibiMinS: 0.3,
          ibiMaxS: 1.5,
          hrIbiTolerance: 0.25,
          hrMinIntervals: 5,
        );
        expect(result, isNotNull);
        expect(result!.hr, closeTo(bpm, 2.0));
      });
    }
  });

  test(
    'RMSSD of alternating 800/860 ms intervals is within +/-10 ms of 60 ms',
    () {
      final beats = <double>[0];
      for (var i = 0; i < 30; i++) {
        beats.add(beats.last + (i.isEven ? 0.8 : 0.86));
      }
      final rmssd = computeRmssd(
        beats,
        hrvIbiTolerance: 0.2,
        hrvMinIntervals: 16,
        hrvMinPairs: 15,
      );
      expect(rmssd, isNotNull);
      expect(rmssd!, closeTo(60.0, 10.0));
    },
  );

  test('a single artifact spike does not change HR by more than 2 bpm', () {
    const bpm = 72.0;
    final beats = _jitteredBeats(bpm: bpm, durationS: durationS);
    final signal = _dipSignal(beats, fs, durationS);

    final baseline = computeHr(
      findBeats(signal, fs, minGapS: 0.3, minHeightSd: 0.3, edgeIgnoreS: 0.3),
      ibiMinS: 0.3,
      ibiMaxS: 1.5,
      hrIbiTolerance: 0.25,
      hrMinIntervals: 5,
    );
    expect(baseline, isNotNull);

    // Insert one large, isolated artifact spike mid-signal.
    final withArtifact = [...signal];
    final spikeIdx = (durationS / 2 * fs).round();
    withArtifact[spikeIdx] -= 5.0;

    final detected = findBeats(
      withArtifact,
      fs,
      minGapS: 0.3,
      minHeightSd: 0.3,
      edgeIgnoreS: 0.3,
    );
    final result = computeHr(
      detected,
      ibiMinS: 0.3,
      ibiMaxS: 1.5,
      hrIbiTolerance: 0.25,
      hrMinIntervals: 5,
    );

    expect(result, isNotNull);
    expect((result!.hr - baseline!.hr).abs(), lessThanOrEqualTo(2.0));
  });

  test('computeHr returns null with too few clean intervals', () {
    final result = computeHr(
      [0, 0.8],
      ibiMinS: 0.3,
      ibiMaxS: 1.5,
      hrIbiTolerance: 0.25,
      hrMinIntervals: 5,
    );
    expect(result, isNull);
  });

  test('computeRmssd returns null below hrvMinIntervals', () {
    final result = computeRmssd(
      [0, 0.8, 1.6],
      hrvIbiTolerance: 0.2,
      hrvMinIntervals: 16,
      hrvMinPairs: 15,
    );
    expect(result, isNull);
  });
}
