import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pulseguard/engine/core/config/feature_spec.dart';
import 'package:pulseguard/engine/core/config/thresholds.dart';

class _FileBundle implements AssetBundleLike {
  @override
  Future<String> loadString(String key) => File(key).readAsString();
}

void main() {
  group('Thresholds', () {
    test('loads and validates assets/config/thresholds.json', () async {
      final t = await Thresholds.load(bundle: _FileBundle());
      expect(t.version, 1);
      expect(t.beats.hrMinIntervals, 5);
      expect(t.filter.respBandHz, [0.1, 0.6]);
    });

    test('rejects unsupported version', () {
      final json =
          jsonDecode(File('assets/config/thresholds.json').readAsStringSync())
              as Map<String, dynamic>;
      json['version'] = 99;
      expect(() => Thresholds.fromJson(json), throwsFormatException);
    });
  });

  group('FeatureSpec', () {
    test('loads and validates assets/config/feature_spec.json', () async {
      final spec = await FeatureSpec.load(bundle: _FileBundle());
      expect(spec.version, 1);
      expect(spec.features.length, 16);
      expect(spec.modelSubsets['isolation_forest'], isNotEmpty);
      expect(spec.activityClasses, [
        'still',
        'fidgeting',
        'walking',
        'running',
      ]);
    });

    test(
      'feature names match the canonical order used by the feature builder',
      () async {
        final spec = await FeatureSpec.load(bundle: _FileBundle());
        expect(spec.featureNames, [
          'hr_z',
          'hrv_z',
          'rr_z',
          'hr_slope_z',
          'hrv_slope_z',
          'rr_slope_z',
          'hr_var_z',
          'hrv_var_z',
          'rr_var_z',
          'hr_pct',
          'hrv_pct',
          'rr_pct',
          'is_resting',
          'is_recovering',
          'is_unknown',
          'since_exercise',
        ]);
      },
    );

    test('rejects non-contiguous indices', () {
      final json =
          jsonDecode(File('assets/config/feature_spec.json').readAsStringSync())
              as Map<String, dynamic>;
      (json['features'] as List)[2]['index'] = 99;
      expect(() => FeatureSpec.fromJson(json), throwsFormatException);
    });

    test('rejects out-of-range model subset index', () {
      final json =
          jsonDecode(File('assets/config/feature_spec.json').readAsStringSync())
              as Map<String, dynamic>;
      (json['model_subsets'] as Map<String, dynamic>)['isolation_forest'] = [
        999,
      ];
      expect(() => FeatureSpec.fromJson(json), throwsFormatException);
    });
  });
}
