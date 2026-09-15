import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:camera/camera.dart';

import '../api/events.dart' show WaveformSample;
import '../core/config/thresholds.dart' show AssetBundleLike;
import '../core/clock.dart';
import '../core/models/vitals_reading.dart';
import 'vitals_source.dart';

class ReplayTick {
  const ReplayTick({
    required this.t,
    required this.hr,
    required this.hrv,
    required this.rr,
    required this.quality,
    required this.rrQuality,
    required this.fingerPresent,
    required this.motion,
  });

  final double t;
  final double? hr;
  final double? hrv;
  final double? rr;
  final double quality;
  final double rrQuality;
  final bool fingerPresent;
  final String motion;

  factory ReplayTick.fromJson(Map<String, dynamic> j) => ReplayTick(
        t: (j['t'] as num).toDouble(),
        hr: (j['hr'] as num?)?.toDouble(),
        hrv: (j['hrv'] as num?)?.toDouble(),
        rr: (j['rr'] as num?)?.toDouble(),
        quality: (j['quality'] as num).toDouble(),
        rrQuality: (j['rr_quality'] as num).toDouble(),
        fingerPresent: j['finger_present'] as bool,
        motion: j['motion'] as String,
      );
}

class ReplayTrace {
  const ReplayTrace({
    required this.version,
    required this.name,
    required this.timeSinceExerciseS,
    required this.ticks,
  });

  final int version;
  final String name;
  final double? timeSinceExerciseS;
  final List<ReplayTick> ticks;

  factory ReplayTrace.fromJson(Map<String, dynamic> j) => ReplayTrace(
        version: j['version'] as int,
        name: j['name'] as String,
        timeSinceExerciseS: (j['time_since_exercise_s'] as num?)?.toDouble(),
        ticks: (j['ticks'] as List)
            .map((t) => ReplayTick.fromJson(t as Map<String, dynamic>))
            .toList(),
      );
}

/// Feeds a recorded [ReplayTrace] through the same tick pipeline the camera
/// source uses, at `1/speed` seconds per tick. Used both for the demo
/// insurance replay and for engine end-to-end tests (with a [FakeClock] and
/// a high speed, ticks resolve near-instantly).
class ReplayVitalsSource implements VitalsSource {
  ReplayVitalsSource({required this.clock, required this.bundle});

  final Clock clock;
  final AssetBundleLike bundle;

  final _controller = StreamController<TickInput>();
  @override
  Stream<TickInput> get ticks => _controller.stream;

  @override
  CameraController? get cameraController => null;

  String? _assetPath;
  double _speed = 1.0;
  ReplayTrace? _trace;
  bool _stopped = false;

  double? get timeSinceExerciseS => _trace?.timeSinceExerciseS;

  void configure({required String assetPath, double speed = 1.0}) {
    _assetPath = assetPath;
    _speed = speed;
  }

  @override
  Future<void> start() async {
    if (_assetPath == null) {
      throw StateError('ReplayVitalsSource.configure() must be called before start()');
    }
    final raw = await bundle.loadString(_assetPath!);
    _trace = ReplayTrace.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    _stopped = false;
    unawaited(_run());
  }

  @override
  Future<void> stop() async {
    _stopped = true;
  }

  Future<void> _run() async {
    final trace = _trace!;
    for (final tick in trace.ticks) {
      if (_stopped) return;
      final reading = VitalsReading(
        timestamp: (tick.t * 1000).round(),
        hr: tick.hr,
        hrv: tick.hrv,
        rr: tick.rr,
        spo2: null,
        oxTrend: null,
        quality: tick.quality,
        rrQuality: tick.rrQuality,
        fingerPresent: tick.fingerPresent,
        source: VitalsReadingSource.replay,
      );
      final waveform = _syntheticWaveform(tick);
      if (!_controller.isClosed) {
        _controller.add(TickInput(
          vitals: reading,
          motionClassName: tick.motion,
          waveform: waveform,
        ));
      }
      await clock.delay(Duration(milliseconds: (1000 / _speed).round()));
    }
    if (!_stopped && !_controller.isClosed) {
      await _controller.close();
    }
  }

  WaveformSample _syntheticWaveform(ReplayTick tick) {
    final hr = tick.hr ?? 70;
    final hz = hr / 60;
    final value = math.sin(2 * math.pi * hz * tick.t);
    return WaveformSample(t: tick.t, value: value, simulated: true);
  }
}
