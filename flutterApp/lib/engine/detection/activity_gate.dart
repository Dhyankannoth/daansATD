import '../core/config/thresholds.dart';
import '../core/models/activity_state.dart';

/// Optional motion-classifier output (from `ml/activity_classifier.dart`),
/// kept as a small local type so this file has no `ml/` dependency.
class MotionClassResult {
  const MotionClassResult({required this.className, required this.confidence});
  final String className; // one of thresholds/feature_spec activity_classes
  final double confidence;
}

/// Classifies the user's current activity from accelerometer motion (or an
/// optional classifier result), combined with their self-reported exercise
/// recency. Threshold-based motion classification only; a classifier can be
/// plugged in via [classify]'s `classifierResult` parameter.
class ActivityGate {
  ActivityGate({required this.thresholds});

  final Thresholds thresholds;

  bool _recoveringEligible = false;

  /// Call once at the start of a scan. Whether "still" resolves to
  /// [ActivityStateKind.recovering] is fixed for the whole scan.
  void startScan({required double? timeSinceExerciseS}) {
    _recoveringEligible =
        timeSinceExerciseS != null &&
        timeSinceExerciseS < thresholds.deviation.recoveringMaxSinceExerciseS;
  }

  ActivityState classify({
    required double motionStdShort,
    required int nowMs,
    MotionClassResult? classifierResult,
  }) {
    final String motionClass;
    final double confidence;
    final ActivityBasis basis;

    if (classifierResult != null) {
      motionClass = classifierResult.className;
      confidence = classifierResult.confidence;
      basis = ActivityBasis.classifier;
    } else {
      final m = thresholds.motion;
      if (motionStdShort > m.exerciseStd) {
        motionClass = 'running';
      } else if (motionStdShort > m.fidgetStd) {
        motionClass = 'fidgeting';
      } else {
        motionClass = 'still';
      }
      confidence = 1.0;
      basis = ActivityBasis.accelerometer;
    }

    final ActivityStateKind state;
    switch (motionClass) {
      case 'walking':
      case 'running':
        state = ActivityStateKind.exercising;
        break;
      case 'fidgeting':
        state = ActivityStateKind.unknown;
        break;
      default:
        state = _recoveringEligible
            ? ActivityStateKind.recovering
            : ActivityStateKind.resting;
    }

    return ActivityState(
      timestamp: nowMs,
      state: state,
      confidence: confidence,
      basis: basis,
    );
  }
}
