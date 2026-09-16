import 'dart:convert';

/// One decision tree stored as parallel arrays (sklearn-export friendly):
/// index `i` is a node; `left[i] == right[i] == -1` marks a leaf.
class TreeNode {
  const TreeNode({
    required this.feature,
    required this.threshold,
    required this.left,
    required this.right,
    required this.nSamples,
    required this.value,
  });

  final List<int> feature;
  final List<double> threshold;
  final List<int> left;
  final List<int> right;
  final List<int> nSamples;

  /// Per-leaf class distribution (counts or fractions); `value[i]` is a
  /// distribution over classes at node `i` (meaningful at leaves).
  final List<List<double>> value;

  bool isLeaf(int node) => left[node] == -1 && right[node] == -1;

  factory TreeNode.fromJson(Map<String, dynamic> j) => TreeNode(
    feature: (j['feature'] as List).map((e) => e as int).toList(),
    threshold: (j['threshold'] as List)
        .map((e) => (e as num).toDouble())
        .toList(),
    left: (j['left'] as List).map((e) => e as int).toList(),
    right: (j['right'] as List).map((e) => e as int).toList(),
    nSamples: (j['n_samples'] as List).map((e) => e as int).toList(),
    value: (j['value'] as List)
        .map((row) => (row as List).map((e) => (e as num).toDouble()).toList())
        .toList(),
  );

  /// Traverses from the root using [x] (already restricted to the model's
  /// `feature_indices` subset), returning the leaf node index reached.
  /// Goes left when `x[feature] <= threshold`.
  int leafFor(List<double> x) {
    var node = 0;
    while (!isLeaf(node)) {
      final f = feature[node];
      final t = threshold[node];
      node = x[f] <= t ? left[node] : right[node];
    }
    return node;
  }
}

/// A loaded tree-ensemble model: `iforest.json`, `risk_rf.json`,
/// `activity_tree.json`, etc, all sharing this JSON shape.
class TreeModel {
  const TreeModel({
    required this.modelType,
    required this.featureSpecVersion,
    required this.featureIndices,
    required this.maxSamples,
    required this.scoreThreshold,
    required this.classes,
    required this.trees,
  });

  final String modelType; // isolation_forest | random_forest | decision_tree
  final int featureSpecVersion;
  final List<int> featureIndices;
  final int? maxSamples;
  final double? scoreThreshold;
  final List<String> classes;
  final List<TreeNode> trees;

  /// Restricts a full feature row to this model's feature subset, in order.
  List<double> selectFeatures(List<double> fullRow) => [
    for (final i in featureIndices) fullRow[i],
  ];

  static TreeModel? tryParse(
    String json, {
    required int expectedFeatureSpecVersion,
  }) {
    final j = jsonDecode(json) as Map<String, dynamic>;
    final version = j['feature_spec_version'] as int;
    if (version != expectedFeatureSpecVersion) return null;
    return TreeModel(
      modelType: j['model_type'] as String,
      featureSpecVersion: version,
      featureIndices: (j['feature_indices'] as List)
          .map((e) => e as int)
          .toList(),
      maxSamples: j['max_samples'] as int?,
      scoreThreshold: (j['score_threshold'] as num?)?.toDouble(),
      classes: ((j['classes'] as List?) ?? const [])
          .map((e) => e as String)
          .toList(),
      trees: (j['trees'] as List)
          .map((t) => TreeNode.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }
}
