import '../detection/activity_gate.dart' show MotionClassResult;
import 'tree_model.dart';

/// Classifies motion (`still | fidgeting | walking | running`) from the 9
/// `activity_features` using a `decision_tree` or `random_forest` model.
class ActivityClassifier {
  ActivityClassifier(this.model);

  final TreeModel model;

  MotionClassResult classify(List<double> activityFeatures) {
    final counts = List<double>.filled(model.classes.length, 0);
    for (final tree in model.trees) {
      final leaf = tree.leafFor(activityFeatures);
      final dist = tree.value[leaf];
      var total = 0.0;
      for (final v in dist) {
        total += v;
      }
      for (var i = 0; i < dist.length && i < counts.length; i++) {
        counts[i] += total == 0 ? 0.0 : dist[i] / total;
      }
    }

    var bestIdx = 0;
    for (var i = 1; i < counts.length; i++) {
      if (counts[i] > counts[bestIdx]) bestIdx = i;
    }
    final confidence = counts[bestIdx] / model.trees.length;
    return MotionClassResult(className: model.classes[bestIdx], confidence: confidence);
  }
}
