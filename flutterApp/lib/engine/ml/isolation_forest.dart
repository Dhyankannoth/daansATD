import 'dart:math' as math;

import '../dsp/stats.dart' show mean;
import 'tree_model.dart';

const double _eulerGamma = 0.5772156649;

double _c(double n) {
  if (n <= 1) return 0;
  return 2 * (math.log(n - 1) + _eulerGamma) - 2 * (n - 1) / n;
}

/// Scores a feature row's anomalousness (0..1, higher = more anomalous)
/// against an isolation-forest [TreeModel].
class IsolationForest {
  IsolationForest(this.model) : assert(model.modelType == 'isolation_forest');

  final TreeModel model;

  double score(List<double> fullFeatureRow) {
    final x = model.selectFeatures(fullFeatureRow);
    final maxSamples = (model.maxSamples ?? 256).toDouble();
    final paths = model.trees.map((t) => _pathLength(t, x)).toList();
    final meanPath = mean(paths);
    final cMax = _c(maxSamples);
    if (cMax == 0) return 0;
    return math.pow(2, -meanPath / cMax).toDouble();
  }

  double _pathLength(TreeNode tree, List<double> x) {
    var node = 0;
    var depth = 0;
    while (!tree.isLeaf(node)) {
      final f = tree.feature[node];
      final t = tree.threshold[node];
      node = x[f] <= t ? tree.left[node] : tree.right[node];
      depth++;
    }
    return depth + _c(tree.nSamples[node].toDouble());
  }
}
