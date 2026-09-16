// Runs the ML-3 synthetic data recorder (tool/synthetic_ml3_recorder.dart).
// Not a real test — a `flutter test`-driven entry point, because plain
// `dart run` can't resolve `dart:ui` (see that file's header comment for why).
//
// Usage:
//   SYNTHETIC_OUTPUT_DIR=/path/to/recordings_synthetic flutter test test/tool/synthetic_ml3_recorder_run_test.dart
//
// Requires training/ml3/synthetic/generate_physiology.py to have already
// written <output-dir>/_intermediate/*.json.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/synthetic_ml3_recorder.dart' as recorder;

void main() {
  final outputDir = Platform.environment['SYNTHETIC_OUTPUT_DIR'];
  test(
    'generate synthetic ML-3 recordings from intermediate physiology JSON',
    () async => recorder.run(outputDir!),
    skip: outputDir == null || outputDir.isEmpty
        ? 'set SYNTHETIC_OUTPUT_DIR to run this (not a real test — a data-generation entry point)'
        : false,
  );
}
