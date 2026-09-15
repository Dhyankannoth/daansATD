import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import '../core/models/activity_state.dart';
import '../core/models/baseline.dart';
import '../core/models/emergency_contact.dart';
import '../core/models/vitals_reading.dart';
import 'engine_snapshot.dart';
import 'events.dart';

/// The public contract between the PulseGuard logic engine and the UI. This
/// is the only surface the UI developer should depend on — everything else
/// under `lib/engine/` is an implementation detail.
abstract class PulseGuardApi {
  // lifecycle
  Future<void> initialize();
  Future<void> dispose();

  // state
  ValueListenable<EngineSnapshot> get snapshot;
  Stream<VitalsReading> get vitals;
  Stream<WaveformSample> get waveform;
  Stream<PlacementHint> get placement;
  Stream<ActivityState> get activity;
  Stream<RiskAssessment> get risk;
  Stream<AlertEvent> get alerts;
  CameraController? get cameraController;

  // baseline
  bool get hasBaseline;
  Baseline? get baseline;
  Stream<CalibrationProgress> get calibration;
  Future<void> startCalibration();
  Future<void> cancelCalibration();
  Future<void> loadDemoBaseline();
  Future<void> clearBaseline();

  // scanning
  Future<void> startScan({Duration? timeSinceExercise});
  Future<ScanSummary> endScan();
  Stream<ScanSummary> get scanFinished;

  // replay
  Future<void> startReplay(String assetPath, {double speed = 1.0, bool useDemoBaseline = true});
  Future<void> stopReplay();

  // alerts
  void respondCheckIn({required bool ok});
  void cancelEscalation();
  EmergencyContact? get contact;
  Future<void> setContact(EmergencyContact contact);

  // record mode
  Future<void> startRecording({
    required String label,
    required String personId,
    String deviceLabel = '',
    bool includeRawSamples = false,
  });
  Future<RecordingResult> stopRecording();
}
