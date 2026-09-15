import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pulseguard/engine/core/config/thresholds.dart';
import 'package:pulseguard/engine/core/models/activity_state.dart';
import 'package:pulseguard/engine/detection/activity_gate.dart';

Thresholds _load() {
  final json = jsonDecode(File('assets/config/thresholds.json').readAsStringSync())
      as Map<String, dynamic>;
  return Thresholds.fromJson(json);
}

void main() {
  test('still with no exercise history classifies as resting', () {
    final gate = ActivityGate(thresholds: _load());
    gate.startScan(timeSinceExerciseS: null);
    final state = gate.classify(motionStdShort: 0.05, nowMs: 0);
    expect(state.state, ActivityStateKind.resting);
    expect(state.basis, ActivityBasis.accelerometer);
  });

  test('still shortly after exercise classifies as recovering for the whole scan', () {
    final gate = ActivityGate(thresholds: _load());
    gate.startScan(timeSinceExerciseS: 60);
    final early = gate.classify(motionStdShort: 0.05, nowMs: 0);
    expect(early.state, ActivityStateKind.recovering);
    // stays recovering even much later in the same scan
    final later = gate.classify(motionStdShort: 0.05, nowMs: 100000);
    expect(later.state, ActivityStateKind.recovering);
  });

  test('exercise too long ago does not count as recovering', () {
    final gate = ActivityGate(thresholds: _load());
    gate.startScan(timeSinceExerciseS: 700); // > recovering_max_since_exercise_s (600)
    final state = gate.classify(motionStdShort: 0.05, nowMs: 0);
    expect(state.state, ActivityStateKind.resting);
  });

  test('high motion classifies as exercising', () {
    final gate = ActivityGate(thresholds: _load());
    gate.startScan(timeSinceExerciseS: null);
    final state = gate.classify(motionStdShort: 2.0, nowMs: 0);
    expect(state.state, ActivityStateKind.exercising);
  });

  test('moderate motion (fidgeting) classifies as unknown', () {
    final gate = ActivityGate(thresholds: _load());
    gate.startScan(timeSinceExerciseS: null);
    final state = gate.classify(motionStdShort: 0.5, nowMs: 0);
    expect(state.state, ActivityStateKind.unknown);
  });

  test('classifier result takes precedence and sets basis to classifier', () {
    final gate = ActivityGate(thresholds: _load());
    gate.startScan(timeSinceExerciseS: null);
    final state = gate.classify(
      motionStdShort: 0.0,
      nowMs: 0,
      classifierResult: const MotionClassResult(className: 'running', confidence: 0.9),
    );
    expect(state.state, ActivityStateKind.exercising);
    expect(state.basis, ActivityBasis.classifier);
    expect(state.confidence, 0.9);
  });
}
