/// Core app constants, timing thresholds, and regulatory copy.
class PulseConstants {
  PulseConstants._();

  // Timing
  static const int spotScanDurationSeconds = 20;
  static const int instructionCycleSeconds = 4;
  static const int checkInTimeoutSeconds = 30;
  static const int cooldownSeconds = 180;
  static const int calibrationDurationSeconds = 60;

  // 8-Point Spacing Grid
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space48 = 48.0;
  static const double space64 = 64.0;

  // Min touch target
  static const double minTouchTarget = 48.0;

  // Non-diagnostic Copy & Regulatory Text
  static const String appTitle = 'PulseGuard';
  static const String appTagline = 'Early-Warning Physiological Monitoring';

  static const String clinicalDisclaimer =
      'PulseGuard is an early-warning and pre-recognition application designed to observe '
      'multi-system physiological deviations from your personal baseline. '
      'It is NOT a diagnostic medical device and does NOT diagnose anaphylaxis or any other clinical condition. '
      'Never ignore professional medical advice or delay seeking immediate emergency medical treatment because of '
      'readings in this app. If you believe you are experiencing a severe allergic reaction or other medical emergency, '
      'immediately call emergency services or use your prescribed emergency medication as directed by your physician.';

  static const String checkInPromptTitle = 'Something has changed';
  static const String checkInPromptSubtitle =
      'We noticed changes across multiple vital signals compared to your personal baseline.';
  static const String checkInQuestion = 'Are you feeling okay?';

  static const String escalationHeadline = 'Please get help immediately';
  static const String escalationSubtitle =
      'Your readings show significant multi-system changes and you indicated feeling unwell.';
  static const String escalationMedicationNotice =
      'Use your prescribed emergency medication (e.g., epinephrine auto-injector) if instructed by your healthcare professional.';

  static const String defaultEmergencyNumber = '911';
}
