import 'dart:async';
import 'package:camera/camera.dart';
import '../../engine/core/models/vitals_reading.dart';
import '../../engine/sources/vitals_source.dart';

/// Concrete [VitalsSource] implementing the wearable / HealthKit / Health Connect
/// ingestion path specified in the architecture.
///
/// Converts wearable heart rate, HRV, and SpO2 streams into normalized [TickInput]s,
/// allowing future smartwatch integration without modifying any detection or ML logic.
class HealthDataSource implements VitalsSource {
  final _ticksController = StreamController<TickInput>.broadcast();
  bool _running = false;
  Timer? _mockStreamTimer;

  @override
  Stream<TickInput> get ticks => _ticksController.stream;

  @override
  CameraController? get cameraController => null;

  bool get isRunning => _running;

  @override
  Future<void> start() async {
    _running = true;
  }

  /// Ingests a wearable vitals reading directly into the orchestrator.
  void ingestReading({
    required double hr,
    required double hrv,
    double? spo2,
    double? rr,
    double quality = 0.95,
  }) {
    if (!_running || _ticksController.isClosed) return;

    final reading = VitalsReading(
      timestamp: DateTime.now().millisecondsSinceEpoch,
      hr: hr,
      hrv: hrv,
      rr: rr,
      spo2: spo2,
      oxTrend: null,
      quality: quality,
      rrQuality: quality,
      fingerPresent: true,
      source: VitalsReadingSource.watch,
    );

    _ticksController.add(TickInput(vitals: reading));
  }

  @override
  Future<void> stop() async {
    _running = false;
    _mockStreamTimer?.cancel();
    _mockStreamTimer = null;
    if (!_ticksController.isClosed) {
      await _ticksController.close();
    }
  }
}
