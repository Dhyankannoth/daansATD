import 'dart:async';
import 'dart:math' as math;

import 'package:camera/camera.dart';

import '../acquisition/camera_service.dart';
import '../acquisition/frame_averager.dart';
import '../acquisition/frame_validator.dart';
import '../acquisition/motion_service.dart';
import '../acquisition/sample_buffer.dart';
import '../api/events.dart' show WaveformSample, PlacementHint;
import '../core/clock.dart';
import '../core/config/thresholds.dart';
import '../core/models/frame_sample.dart';
import '../core/models/vitals_reading.dart' show VitalsReadingSource;
import '../vitals/oxygenation.dart' show OxCalibration;
import '../vitals/vitals_engine.dart';
import 'vitals_source.dart';

/// Camera-backed [VitalsSource]: init/torch/exposure via [CameraService],
/// per-frame ROI averaging and validation, a rolling [SampleBuffer], and a
/// 1 Hz [VitalsEngine] tick, converged into [TickInput] like replay.
///
/// NOTE: this integrates real device I/O (camera + accelerometer) and has
/// not been exercised on a physical device in this environment — verify per
/// the on-device checklist in the final deliverables summary before relying
/// on it.
class CameraVitalsSource implements VitalsSource {
  CameraVitalsSource({required this.thresholds, required this.clock, this.oxCalibration});

  final Thresholds thresholds;
  final Clock clock;
  final OxCalibration? oxCalibration;

  late final CameraService _cameraService = CameraService(thresholds: thresholds, clock: clock);
  late final FrameAverager _averager = FrameAverager(
    roiFraction: thresholds.frame.roiFraction,
    pixelStep: thresholds.frame.pixelStep,
    satPixel: thresholds.frame.satPixel,
  );
  late final FrameValidator _validator = FrameValidator(thresholds: thresholds);
  late final MotionService _motion = MotionService(clock: clock);
  late final SampleBuffer _buffer = SampleBuffer(windowS: thresholds.windowsS.buffer);
  late final VitalsEngine _vitalsEngine = VitalsEngine(thresholds: thresholds);

  final _ticksController = StreamController<TickInput>.broadcast();
  @override
  Stream<TickInput> get ticks => _ticksController.stream;

  final _placementController = StreamController<PlacementHint>.broadcast();
  Stream<PlacementHint> get placement => _placementController.stream;

  @override
  CameraController? get cameraController => _cameraService.controller;

  StreamSubscription<(CameraImage, double)>? _frameSub;
  StreamSubscription<void>? _bgSub;
  Timer? _tickTimer;

  bool _settled = false;
  double? _settleStartS;
  double? _fingerLostSinceS;
  PlacementHint? _lastEmittedHint;

  @override
  Future<void> start() async {
    _settled = false;
    _settleStartS = null;
    _fingerLostSinceS = null;
    _buffer.clear();
    _vitalsEngine.resetScan();
    _validator.reset();

    _motion.start();
    final ok = await _cameraService.start();
    if (!ok) {
      throw StateError(_cameraService.lastError ?? 'Camera failed to start');
    }
    _frameSub = _cameraService.frames.listen(_onFrame);
    _bgSub = _cameraService.appBackgrounded.listen((_) {
      unawaited(stop());
    });
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) => _emitTick());
  }

  @override
  Future<void> stop() async {
    _tickTimer?.cancel();
    _tickTimer = null;
    await _frameSub?.cancel();
    await _bgSub?.cancel();
    await _motion.stop();
    await _cameraService.stop();
    if (!_ticksController.isClosed) await _ticksController.close();
    if (!_placementController.isClosed) await _placementController.close();
  }

  void _onFrame((CameraImage, double) event) {
    final (image, t) = event;
    final avg = _averageFrame(image);
    final motionStd = _motion.motionStd(thresholds.motion.windowShortS);
    final validation = _validator.validate(avg, t: t, motionStdShort: motionStd);

    final hint = _validator.debouncedHint;
    if (hint != null && hint != _lastEmittedHint && !_placementController.isClosed) {
      _lastEmittedHint = hint;
      _placementController.add(hint);
    }

    if (!_settled) {
      if (validation.fingerPresent) {
        _settleStartS ??= t;
        if (t - _settleStartS! >= thresholds.camera.settleS) {
          _settled = true;
          unawaited(
              _cameraService.lockExposureIfSaturated(latestSatFrac: () => avg.satFrac));
        }
      } else {
        _settleStartS = null;
      }
      return;
    }

    if (!validation.fingerPresent) {
      _fingerLostSinceS ??= t;
      if (t - _fingerLostSinceS! > thresholds.frame.fingerLostResetS) {
        _buffer.clear();
        _vitalsEngine.resetScan();
      }
    } else {
      _fingerLostSinceS = null;
    }

    _buffer.add(FrameSample(
      t: t,
      r: avg.r,
      g: avg.g,
      b: avg.b,
      valid: validation.valid,
      fingerPresent: validation.fingerPresent,
    ));
  }

  FrameAverage _averageFrame(CameraImage image) {
    if (image.format.group == ImageFormatGroup.bgra8888) {
      final p = image.planes[0];
      return _averager.averageBgra8888(
        bytes: p.bytes,
        bytesPerRow: p.bytesPerRow,
        width: image.width,
        height: image.height,
      );
    }
    final y = image.planes[0];
    final u = image.planes[1];
    final v = image.planes[2];
    return _averager.averageYuv420(
      yPlane: y.bytes,
      yRowStride: y.bytesPerRow,
      uPlane: u.bytes,
      uRowStride: u.bytesPerRow,
      uPixelStride: u.bytesPerPixel ?? 1,
      vPlane: v.bytes,
      vRowStride: v.bytesPerRow,
      vPixelStride: v.bytesPerPixel ?? 1,
      width: image.width,
      height: image.height,
    );
  }

  void _emitTick() {
    if (!_settled || _ticksController.isClosed) return;
    final nowS = clock.nowS();
    final reading = _vitalsEngine.tick(
      buffer: _buffer.samples,
      nowS: nowS,
      nowMs: clock.nowMs(),
      oxCalibration: oxCalibration,
      source: VitalsReadingSource.camera,
    );
    final motionStdShort = _motion.motionStd(thresholds.motion.windowShortS);
    final waveform = _computeWaveform(nowS, reading.fingerPresent);
    _ticksController.add(TickInput(
      vitals: reading,
      motionStdShort: motionStdShort,
      waveform: waveform,
    ));
  }

  WaveformSample? _computeWaveform(double nowS, bool fingerPresent) {
    if (!fingerPresent) return null;
    final samples = _buffer.samples;
    if (samples.isEmpty) return null;
    final last = samples.last;

    final avgWindow = samples.where((s) => s.t >= nowS - 1.0).map((s) => s.r).toList();
    final stdWindow = samples.where((s) => s.t >= nowS - 5.0).map((s) => s.r).toList();
    if (avgWindow.isEmpty || stdWindow.isEmpty) return null;

    final movAvg = avgWindow.reduce((a, b) => a + b) / avgWindow.length;
    final mean = stdWindow.reduce((a, b) => a + b) / stdWindow.length;
    var sumSq = 0.0;
    for (final v in stdWindow) {
      sumSq += (v - mean) * (v - mean);
    }
    final stdDev = math.sqrt(sumSq / stdWindow.length);
    if (stdDev == 0) return null;

    final value = (-(last.r - movAvg) / stdDev).clamp(-1.5, 1.5);
    return WaveformSample(t: last.t, value: value, simulated: false);
  }

  Future<void> dispose() async {
    await stop();
    await _cameraService.dispose();
  }
}
