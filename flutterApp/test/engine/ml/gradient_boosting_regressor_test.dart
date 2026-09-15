import 'package:flutter_test/flutter_test.dart';
import 'package:pulseguard/engine/ml/gradient_boosting_regressor.dart';
import 'package:pulseguard/engine/ml/tree_model.dart';

const _json = '''
{
  "model_type": "gradient_boosting_regressor",
  "feature_spec_version": 1,
  "feature_indices": [0],
  "learning_rate": 1.0,
  "base_score": 2.0,
  "trees": [
    { "feature": [-2], "threshold": [-2], "left": [-1], "right": [-1],
      "n_samples": [10], "value": [[5.0]] },
    { "feature": [-2], "threshold": [-2], "left": [-1], "right": [-1],
      "n_samples": [10], "value": [[3.0]] }
  ]
}
''';

void main() {
  test('sums leaf values across trees, scales by learning_rate, adds base_score', () {
    final model = TreeModel.tryParse(_json, expectedFeatureSpecVersion: 1)!;
    final gbr = GradientBoostingRegressor(model);

    // base_score(2.0) + learning_rate(1.0) * (5.0 + 3.0) = 10.0
    expect(gbr.predict([0.0]), closeTo(10.0, 1e-9));
  });

  test('missing learning_rate/base_score fails the assertion, not a silent wrong answer', () {
    const badJson = '''
    {
      "model_type": "gradient_boosting_regressor",
      "feature_spec_version": 1,
      "feature_indices": [0],
      "trees": [
        { "feature": [-2], "threshold": [-2], "left": [-1], "right": [-1],
          "n_samples": [10], "value": [[5.0]] }
      ]
    }
    ''';
    final model = TreeModel.tryParse(badJson, expectedFeatureSpecVersion: 1)!;
    expect(() => GradientBoostingRegressor(model), throwsA(isA<AssertionError>()));
  });
}
