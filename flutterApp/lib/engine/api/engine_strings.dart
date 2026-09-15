/// Every user-facing string the engine produces, in one place so the UI
/// developer can reword freely without hunting through logic files.
///
/// Hard rule: never say "anaphylaxis detected", "diagnosis", or imply
/// clinical accuracy. Stick to "risk", "early warning", "unusual for you",
/// "experimental".
class EngineStrings {
  // Placement hints (frame_validator.dart)
  static const placementOk = 'Hold still — measuring';
  static const placementNoFinger = 'Place your fingertip over the camera and flash';
  static const placementCoverLens = 'Cover the camera lens completely';
  static const placementCoverFlash = 'Cover the flash too';
  static const placementPressLighter = 'Press more lightly';
  static const placementKeepStill = 'Keep still';

  // Risk status text (risk_engine.dart)
  static const statusNormal = 'All systems normal';
  static const statusRecovering = 'Recovering from exercise — tracking';
  static const statusMonitoringUnusual = 'Monitoring — unusual pattern';
  static const statusElevated = 'Unusual for you — stop activity and stay still';
  static const statusHigh = 'Checking on you';
  static const statusCritical = 'Contact notified (simulated)';

  // ML contribution reasons (risk_engine.dart)
  static const reasonMlAgrees = 'Pattern model agrees with the alert';
  static const reasonMlFlagged = 'Pattern model flagged this as unusual';
  static const reasonSignalLost = 'Signal lost while vitals were abnormal';

  // Recovery suppression (deviation_engine.dart)
  static String recoverySuppressed(String metricName) =>
      '$metricName elevated but falling — consistent with exercise recovery';

  // Deviation reasons (deviation_engine.dart)
  static const noBaselineYet = 'No baseline yet';
  static String noTrustedTick(String metricName) => 'No trusted $metricName this tick';

  // Calibration failure reasons (baseline_service.dart)
  static const calibrationFailHr =
      'Not enough steady pulse signal for heart rate — rest your finger lightly and try again.';
  static const calibrationFailHrv =
      'Not enough steady pulse signal for HRV — rest your finger lightly and try again.';
  static const calibrationFailRr =
      'Not enough steady breathing signal — rest your finger lightly and try again.';

  // Scan lifecycle
  static const scanStoppedAppBackgrounded =
      'Scan stopped because the app left the foreground';

  // Emergency contact
  static const contactNotSet = 'Emergency contact (not set)';
}
