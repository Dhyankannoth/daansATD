import 'tree_model.dart';

/// Predicts a single number (e.g. expected recovery time in minutes) from a
/// `gradient_boosting_regressor` [TreeModel]: sum every tree's leaf value,
/// scale by `learningRate`, add `baseScore`. Each tree is a plain regression
/// tree — same [TreeNode] shape as the classifiers, leaf `value` is a single-
/// element list instead of a class distribution.
class GradientBoostingRegressor {
  GradientBoostingRegressor(this.model)
      : assert(model.modelType == 'gradient_boosting_regressor'),
        assert(model.learningRate != null && model.baseScore != null,
            'gradient_boosting_regressor model file is missing learning_rate/base_score');

  final TreeModel model;

  double predict(List<double> fullFeatureRow) {
    final x = model.selectFeatures(fullFeatureRow);
    var sum = 0.0;
    for (final tree in model.trees) {
      final leaf = tree.leafFor(x);
      sum += tree.value[leaf][0];
    }
    return model.baseScore! + model.learningRate! * sum;
  }
}
