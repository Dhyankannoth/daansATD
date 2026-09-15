import 'dart:async';
import 'dart:math' as math;

import 'package:sensors_plus/sensors_plus.dart';

import '../core/clock.dart';
import '../dsp/resample.dart' show resampleLinear;
import '../dsp/spectrum.dart' show dominantRate;
import '../dsp/stats.dart' show mean, std;

class MotionSample {
  const MotionSample(this.t, this.x, this.y, this.z, this.mag);
  final double t;
  final double x, y, z, mag;
}

/// Keeps a 6 s rolling window of accelerometer magnitude (gravity included,
/// per §7.1) and derives motion std and the 9 `activity_features`.
class MotionService {
  MotionService({required this.clock});

  final Clock clock;
  final List<MotionSample> _buffer = [];
  StreamSubscription<AccelerometerEvent>? _sub;

  void start() {
    _sub = accelerometerEventStream(samplingPeriod: SensorInterval.gameInterval)
        .listen(_onEvent);
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    _buffer.clear();
  }

  void _onEvent(AccelerometerEvent e) {
    final t = clock.nowS();
    final mag = math.sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
    _buffer.add(MotionSample(t, e.x, e.y, e.z, mag));
    final cutoff = t - 6.0;
    while (_buffer.isNotEmpty && _buffer.first.t < cutoff) {
      _buffer.removeAt(0);
    }
  }

  /// Std of |a| over the last [windowS] seconds.
  double motionStd(double windowS) {
    final cutoff = clock.nowS() - windowS;
    final mags = _buffer.where((s) => s.t >= cutoff).map((s) => s.mag).toList();
    return std(mags);
  }

  /// The 9 `activity_features` (feature_spec.json order) over the last 5 s,
  /// or null if too little data has accumulated.
  List<double>? activityFeatures() {
    final cutoff = clock.nowS() - 5.0;
    final window = _buffer.where((s) => s.t >= cutoff).toList();
    if (window.length < 2) return null;

    final mags = window.map((s) => s.mag).toList();
    final xs = window.map((s) => s.x).toList();
    final ys = window.map((s) => s.y).toList();
    final zs = window.map((s) => s.z).toList();

    final magMean = mean(mags);
    final magStd = std(mags);
    final magRange = mags.reduce(math.max) - mags.reduce(math.min);
    final magEnergy = magStd * magStd;

    final times = window.map((s) => s.t).toList();
    final resampled = resampleLinear(times, mags, 50, times.first, times.last);
    final dom = dominantRate(resampled, 50, [0.5, 5.0], 0.1, minSamples: 10);
    final domFreq = dom?.freqHz ?? 0.0;

    final demeaned = mags.map((m) => m - magMean).toList();
    var zeroCross = 0;
    for (var i = 1; i < demeaned.length; i++) {
      if ((demeaned[i - 1] < 0) != (demeaned[i] < 0)) zeroCross++;
    }

    return [
      magMean,
      magStd,
      magRange,
      magEnergy,
      domFreq,
      zeroCross.toDouble(),
      std(xs),
      std(ys),
      std(zs),
    ];
  }
}
