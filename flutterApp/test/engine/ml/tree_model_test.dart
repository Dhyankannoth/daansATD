import 'package:flutter_test/flutter_test.dart';
import 'package:pulseguard/engine/ml/tree_model.dart';

const _json = '''
{
  "model_type": "decision_tree",
  "feature_spec_version": 1,
  "feature_indices": [0, 2],
  "max_samples": 16,
  "score_threshold": 0.62,
  "classes": ["a", "b"],
  "trees": [
    {
      "feature": [0, -2, -2],
      "threshold": [1.5, -2, -2],
      "left": [1, -1, -1],
      "right": [2, -1, -1],
      "n_samples": [10, 4, 6],
      "value": [[0, 0], [3, 1], [1, 5]]
    }
  ]
}
''';

void main() {
  test('parses and validates feature_spec_version', () {
    final model = TreeModel.tryParse(_json, expectedFeatureSpecVersion: 1);
    expect(model, isNotNull);
    expect(model!.modelType, 'decision_tree');
    expect(model.featureIndices, [0, 2]);
  });

  test('version mismatch disables the model (returns null)', () {
    final model = TreeModel.tryParse(_json, expectedFeatureSpecVersion: 2);
    expect(model, isNull);
  });

  test('traversal goes left when x <= threshold, right otherwise', () {
    final model = TreeModel.tryParse(_json, expectedFeatureSpecVersion: 1)!;
    final tree = model.trees.first;

    // feature_indices selects full-row indices [0, 2] -> subset [x0, x2].
    final leftRow = model.selectFeatures([1.0, 99.0, 0.0]); // x0=1.0 <= 1.5
    expect(tree.leafFor(leftRow), 1);
    expect(tree.value[tree.leafFor(leftRow)], [3, 1]);

    final rightRow = model.selectFeatures([2.0, 99.0, 0.0]); // x0=2.0 > 1.5
    expect(tree.leafFor(rightRow), 2);
    expect(tree.value[tree.leafFor(rightRow)], [1, 5]);
  });

  test('isLeaf identifies nodes with left == right == -1', () {
    final model = TreeModel.tryParse(_json, expectedFeatureSpecVersion: 1)!;
    final tree = model.trees.first;
    expect(tree.isLeaf(0), isFalse);
    expect(tree.isLeaf(1), isTrue);
    expect(tree.isLeaf(2), isTrue);
  });
}
