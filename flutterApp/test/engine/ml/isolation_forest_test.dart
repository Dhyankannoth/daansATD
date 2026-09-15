import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:pulseguard/engine/ml/isolation_forest.dart';
import 'package:pulseguard/engine/ml/tree_model.dart';

const _eulerGamma = 0.5772156649;
double _c(double n) {
  if (n <= 1) return 0;
  return 2 * (math.log(n - 1) + _eulerGamma) - 2 * (n - 1) / n;
}

const _json = '''
{
  "model_type": "isolation_forest",
  "feature_spec_version": 1,
  "feature_indices": [0],
  "max_samples": 16,
  "trees": [
    {
      "feature": [0, -2, -2],
      "threshold": [0.0, -2, -2],
      "left": [1, -1, -1],
      "right": [2, -1, -1],
      "n_samples": [10, 5, 5],
      "value": [[0], [0], [0]]
    }
  ]
}
''';

void main() {
  test('isolation forest score matches the c(n) path-length formula', () {
    final model = TreeModel.tryParse(_json, expectedFeatureSpecVersion: 1)!;
    final forest = IsolationForest(model);

    // x0 = 1.0 > threshold 0.0 -> right child (node 2), depth 1, n_samples=5.
    final score = forest.score([1.0]);

    final expectedPathLength = 1 + _c(5);
    final expectedScore = math.pow(2, -expectedPathLength / _c(16)).toDouble();
    expect(score, closeTo(expectedScore, 1e-9));
  });
}
