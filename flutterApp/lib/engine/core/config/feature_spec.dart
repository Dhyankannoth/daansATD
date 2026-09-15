import 'dart:convert';

import 'thresholds.dart' show AssetBundleLike;
import 'package:flutter/services.dart' show rootBundle;

class FeatureDef {
  const FeatureDef({
    required this.index,
    required this.name,
    required this.formula,
  });
  final int index;
  final String name;
  final String formula;

  factory FeatureDef.fromJson(Map<String, dynamic> j) => FeatureDef(
    index: j['index'] as int,
    name: j['name'] as String,
    formula: j['formula'] as String,
  );
}

/// Typed, validated view over `assets/config/feature_spec.json`. This is the
/// single source of truth for ML feature order — the Dart feature builder
/// must produce values in exactly this order.
class FeatureSpec {
  const FeatureSpec({
    required this.version,
    required this.features,
    required this.modelSubsets,
    required this.activityFeatures,
    required this.activityClasses,
  });

  final int version;
  final List<FeatureDef> features;

  /// model name -> list of feature indices used by that model.
  final Map<String, List<int>> modelSubsets;
  final List<String> activityFeatures;
  final List<String> activityClasses;

  List<String> get featureNames => features.map((f) => f.name).toList();

  static Future<FeatureSpec> load({
    String assetPath = 'assets/config/feature_spec.json',
    AssetBundleLike? bundle,
  }) async {
    final raw = await (bundle ?? _RootBundleAdapter()).loadString(assetPath);
    return FeatureSpec.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  factory FeatureSpec.fromJson(Map<String, dynamic> j) {
    final features = (j['features'] as List)
        .map((e) => FeatureDef.fromJson(e as Map<String, dynamic>))
        .toList();
    final modelSubsets = <String, List<int>>{
      for (final entry in (j['model_subsets'] as Map<String, dynamic>).entries)
        entry.key: (entry.value as List).map((e) => e as int).toList(),
    };
    final spec = FeatureSpec(
      version: j['version'] as int,
      features: features,
      modelSubsets: modelSubsets,
      activityFeatures: (j['activity_features'] as List)
          .map((e) => e as String)
          .toList(),
      activityClasses: (j['activity_classes'] as List)
          .map((e) => e as String)
          .toList(),
    );
    spec._validate();
    return spec;
  }

  void _validate() {
    for (var i = 0; i < features.length; i++) {
      if (features[i].index != i) {
        throw FormatException(
          'feature_spec.json indices must be contiguous from 0; found ${features[i].index} at position $i',
        );
      }
    }
    final maxIndex = features.length - 1;
    for (final entry in modelSubsets.entries) {
      for (final idx in entry.value) {
        if (idx < 0 || idx > maxIndex) {
          throw FormatException(
            'model_subsets["${entry.key}"] contains out-of-range index $idx',
          );
        }
      }
    }
  }
}

class _RootBundleAdapter implements AssetBundleLike {
  @override
  Future<String> loadString(String key) => rootBundle.loadString(key);
}
