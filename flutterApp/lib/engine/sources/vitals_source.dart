import 'package:camera/camera.dart';

import '../api/events.dart' show WaveformSample;
import '../core/models/vitals_reading.dart';

/// One tick's worth of data a [VitalsSource] feeds to the orchestrator, from
/// the `ActivityState` step of the pipeline onward (§7.12).
class TickInput {
  const TickInput({
    required this.vitals,
    this.motionClassName,
    this.motionStdShort,
    this.motionConfidence = 1.0,
    this.waveform,
  });

  final VitalsReading vitals;

  /// Pre-classified motion (e.g. from a replay trace's `motion` field, or a
  /// camera source's optional ML classifier). Takes precedence over
  /// [motionStdShort] when present.
  final String? motionClassName;

  /// Raw short-window accelerometer std, for the threshold-based activity
  /// gate path, when no pre-classified label is available.
  final double? motionStdShort;
  final double motionConfidence;
  final WaveformSample? waveform;
}

/// Abstracts where per-tick vitals come from: the live camera pipeline or a
/// replay trace. Both converge at [TickInput] so the orchestrator runs one
/// code path regardless of source.
abstract class VitalsSource {
  Stream<TickInput> get ticks;

  /// Non-null only for a camera-backed source, for `CameraPreview`.
  CameraController? get cameraController;

  Future<void> start();
  Future<void> stop();
}
