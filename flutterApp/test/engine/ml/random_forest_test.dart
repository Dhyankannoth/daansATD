import 'package:flutter_test/flutter_test.dart';
import 'package:pulseguard/engine/ml/random_forest.dart';
import 'package:pulseguard/engine/ml/tree_model.dart';

const _json = '''
{
  "model_type": "random_forest",
  "feature_spec_version": 1,
  "feature_indices": [0],
  "classes": ["normal", "reaction"],
  "trees": [
    {
      "feature": [-2],
      "threshold": [-2],
      "left": [-1],
      "right": [-1],
      "n_samples": [10],
      "value": [[8, 2]]
    },
    {
      "feature": [-2],
      "threshold": [-2],
      "left": [-1],
      "right": [-1],
      "n_samples": [20],
      "value": [[4, 16]]
    }
  ]
}
''';

void main() {
  test('normalizes raw per-leaf counts before averaging across trees', () {
    final model = TreeModel.tryParse(_json, expectedFeatureSpecVersion: 1)!;
    final rf = RandomForest(model);

    // tree1: P(reaction) = 2/10 = 0.2; tree2: P(reaction) = 16/20 = 0.8
    // ensemble = mean(0.2, 0.8) = 0.5
    final p = rf.riskProbability([0.0]);
    expect(p, closeTo(0.5, 1e-9));
  });

  test('unknown class returns 0', () {
    final model = TreeModel.tryParse(_json, expectedFeatureSpecVersion: 1)!;
    final rf = RandomForest(model);
    expect(rf.probabilityOf('nonexistent', [0.0]), 0);
  });
}
