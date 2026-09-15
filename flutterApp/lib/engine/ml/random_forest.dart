import 'tree_model.dart';

/// Averages per-tree leaf class distributions (normalized to sum to 1, since
/// sklearn exports vary between counts and fractions) into an ensemble
/// class probability.
class RandomForest {
  RandomForest(this.model) : assert(model.modelType == 'random_forest');

  final TreeModel model;

  double probabilityOf(String className, List<double> fullFeatureRow) {
    final classIdx = model.classes.indexOf(className);
    if (classIdx == -1) return 0;
    final x = model.selectFeatures(fullFeatureRow);

    var sum = 0.0;
    for (final tree in model.trees) {
      final leaf = tree.leafFor(x);
      final dist = tree.value[leaf];
      var total = 0.0;
      for (final v in dist) {
        total += v;
      }
      sum += total == 0 ? 0.0 : dist[classIdx] / total;
    }
    return sum / model.trees.length;
  }

  /// Convenience for the risk classifier: `P(reaction)`.
  double riskProbability(List<double> fullFeatureRow) =>
      probabilityOf('reaction', fullFeatureRow);
}
