import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/widgets.dart';

import '../core/clock.dart';
import '../core/config/thresholds.dart';

/// Camera init, torch, exposure-lock handshake, and the raw frame stream.
/// Pure plumbing — ROI averaging, validation and vitals live elsewhere.
class CameraService with WidgetsBindingObserver {
  CameraService({required this.thresholds, required this.clock});

  final Thresholds thresholds;
  final Clock clock;

  CameraController? controller;
  String? _lastError;
  String? get lastError => _lastError;

  final _framesController = StreamController<(CameraImage, double)>.broadcast();

  /// Each event is (frame, arrivalTimeSeconds) — the arrival time is
  /// stamped by [clock], never trusted from the platform.
  Stream<(CameraImage, double)> get frames => _framesController.stream;

  final _appBackgroundedController = StreamController<void>.broadcast();
  Stream<void> get appBackgrounded => _appBackgroundedController.stream;

  Future<bool> start() async {
    WidgetsBinding.instance.addObserver(this);
    try {
      final cameras = await availableCameras();
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final imageFormat = defaultTargetPlatform == TargetPlatform.iOS
          ? ImageFormatGroup.bgra8888
          : ImageFormatGroup.yuv420;
      final c = CameraController(
        back,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: imageFormat,
      );
      controller = c;
      await c.initialize();

      var torchOk = true;
      try {
        await c.setFlashMode(FlashMode.torch);
      } catch (_) {
        torchOk = false;
      }
      await c.setFocusMode(FocusMode.locked);

      await c.startImageStream((image) {
        if (!_framesController.isClosed) {
          _framesController.add((image, clock.nowS()));
        }
      });

      if (!torchOk) {
        try {
          await c.setFlashMode(FlashMode.torch);
        } catch (_) {}
      }

      return true;
    } on CameraException catch (e) {
      _lastError = 'Camera error: ${e.description ?? e.code}';
      return false;
    } catch (e) {
      _lastError = 'Camera unavailable: $e';
      return false;
    }
  }

  /// Runs the exposure step-down loop (§7.1 settle phase) using recent
  /// saturation fractions supplied by the caller. Locks exposure afterward.
  Future<void> lockExposureIfSaturated({
    required double Function() latestSatFrac,
  }) async {
    final c = controller;
    if (c == null) return;
    final camThresholds = thresholds.camera;
    var offset = 0.0;
    double? stepSize;
    double? minOffset;
    try {
      stepSize = await c.getExposureOffsetStepSize();
      minOffset = await c.getMinExposureOffset();
    } catch (_) {}

    if (stepSize != null && minOffset != null) {
      for (var i = 0; i < camThresholds.maxExposureSteps; i++) {
        if (latestSatFrac() <= thresholds.frame.maxSatFrac) break;
        offset = (offset - stepSize).clamp(minOffset, 0.0);
        try {
          await c.setExposureOffset(offset);
        } catch (_) {
          break;
        }
        await clock.delay(
          Duration(milliseconds: camThresholds.exposureStepWaitMs),
        );
      }
    }
    try {
      await c.setExposureMode(ExposureMode.locked);
    } catch (_) {}
  }

  Future<void> stop() async {
    WidgetsBinding.instance.removeObserver(this);
    final c = controller;
    controller = null;
    if (c != null) {
      try {
        await c.setFlashMode(FlashMode.off);
      } catch (_) {}
      try {
        await c.stopImageStream();
      } catch (_) {}
      await c.dispose();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && controller != null) {
      _appBackgroundedController.add(null);
    }
  }

  Future<void> dispose() async {
    await stop();
    await _framesController.close();
    await _appBackgroundedController.close();
  }
}
