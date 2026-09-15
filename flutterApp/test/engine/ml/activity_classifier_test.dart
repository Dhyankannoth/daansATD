import 'package:flutter_test/flutter_test.dart';
import 'package:pulseguard/engine/ml/activity_classifier.dart';
import 'package:pulseguard/engine/ml/tree_model.dart';

const _json = '''
{
  "model_type": "decision_tree",
  "feature_spec_version": 1,
  "feature_indices": [0],
  "classes": ["still", "fidgeting", "walking", "running"],
  "trees": [
    {
      "feature": [0, -2, -2],
      "threshold": [1.0, -2, -2],
      "left": [1, -1, -1],
      "right": [2, -1, -1],
      "n_samples": [10, 6, 4],
      "value": [[0,0,0,0], [6,0,0,0], [0,0,0,4]]
    }
  ]
}
''';

void main() {
  test('classifies low motion as still and high motion as running', () {
    final model = TreeModel.tryParse(_json, expectedFeatureSpecVersion: 1)!;
    final classifier = ActivityClassifier(model);

    final still = classifier.classify([0.2]);
    expect(still.className, 'still');
    expect(still.confidence, 1.0);

    final running = classifier.classify([5.0]);
    expect(running.className, 'running');
    expect(running.confidence, 1.0);
  });
}
