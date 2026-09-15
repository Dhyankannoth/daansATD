import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pulseguard/engine/acquisition/frame_averager.dart'
    show FrameAverage;
import 'package:pulseguard/engine/acquisition/frame_validator.dart';
import 'package:pulseguard/engine/api/events.dart' show PlacementHint;
import 'package:pulseguard/engine/core/config/thresholds.dart';

Thresholds _load() {
  final json =
      jsonDecode(File('assets/config/thresholds.json').readAsStringSync())
          as Map<String, dynamic>;
  return Thresholds.fromJson(json);
}

void main() {
  test('no finger and low red -> noFinger', () {
    final v = FrameValidator(thresholds: _load());
    final r = v.validate(
      const FrameAverage(r: 10, g: 10, b: 10, satFrac: 0),
      t: 0,
      motionStdShort: 0,
    );
    expect(r.fingerPresent, isFalse);
    expect(r.rawHint, PlacementHint.noFinger);
    expect(r.valid, isFalse);
  });

  test('finger check fails but red is high -> coverLens', () {
    final v = FrameValidator(thresholds: _load());
    // r not >> g/b (finger_ratio not met) despite decent red level.
    final r = v.validate(
      const FrameAverage(r: 100, g: 90, b: 90, satFrac: 0),
      t: 0,
      motionStdShort: 0,
    );
    expect(r.rawHint, PlacementHint.coverLens);
  });

  test('finger present but red below min_red -> coverFlash', () {
    final v = FrameValidator(thresholds: _load());
    // r > 2*g and r > 2*b, but r <= min_red (40)
    final r = v.validate(
      const FrameAverage(r: 30, g: 10, b: 10, satFrac: 0),
      t: 0,
      motionStdShort: 0,
    );
    expect(r.fingerPresent, isFalse); // light check fails too
    expect(r.rawHint, PlacementHint.coverFlash);
  });

  test('clipping (high saturation fraction) -> pressLighter', () {
    final v = FrameValidator(thresholds: _load());
    final r = v.validate(
      const FrameAverage(r: 200, g: 50, b: 50, satFrac: 0.5),
      t: 0,
      motionStdShort: 0,
    );
    expect(r.fingerPresent, isTrue);
    expect(r.rawHint, PlacementHint.pressLighter);
    expect(r.valid, isFalse);
  });

  test('sudden jump in red -> keepStill', () {
    final v = FrameValidator(thresholds: _load());
    v.validate(
      const FrameAverage(r: 100, g: 20, b: 20, satFrac: 0),
      t: 0,
      motionStdShort: 0,
    );
    // next frame jumps by > max_jump (3%) fraction of previous red value.
    final r = v.validate(
      const FrameAverage(r: 150, g: 20, b: 20, satFrac: 0),
      t: 0.033,
      motionStdShort: 0,
    );
    expect(r.rawHint, PlacementHint.keepStill);
  });

  test('excess motion -> keepStill', () {
    final v = FrameValidator(thresholds: _load());
    final r = v.validate(
      const FrameAverage(r: 100, g: 20, b: 20, satFrac: 0),
      t: 0,
      motionStdShort: 5.0,
    );
    expect(r.rawHint, PlacementHint.keepStill);
    expect(r.valid, isFalse);
  });

  test('all checks pass -> ok and valid', () {
    final v = FrameValidator(thresholds: _load());
    v.validate(
      const FrameAverage(r: 100, g: 20, b: 20, satFrac: 0),
      t: 0,
      motionStdShort: 0,
    );
    final r = v.validate(
      const FrameAverage(r: 101, g: 20, b: 20, satFrac: 0),
      t: 0.033,
      motionStdShort: 0,
    );
    expect(r.rawHint, PlacementHint.ok);
    expect(r.valid, isTrue);
    expect(r.fingerPresent, isTrue);
  });

  test('debounced hint only updates after holding for 300ms', () {
    final v = FrameValidator(thresholds: _load());
    // Start ok.
    v.validate(
      const FrameAverage(r: 100, g: 20, b: 20, satFrac: 0),
      t: 0,
      motionStdShort: 0,
    );
    v.validate(
      const FrameAverage(r: 100, g: 20, b: 20, satFrac: 0),
      t: 0.1,
      motionStdShort: 0,
    );
    expect(v.debouncedHint, isNull); // hasn't held 300ms yet on first value

    v.validate(
      const FrameAverage(r: 100, g: 20, b: 20, satFrac: 0),
      t: 0.35,
      motionStdShort: 0,
    );
    expect(v.debouncedHint, PlacementHint.ok);

    // Flip to noFinger only briefly (< 300ms) -> debounced hint unchanged.
    v.validate(
      const FrameAverage(r: 5, g: 5, b: 5, satFrac: 0),
      t: 0.4,
      motionStdShort: 0,
    );
    expect(v.debouncedHint, PlacementHint.ok);

    // Hold noFinger for >= 300ms -> debounced hint flips.
    v.validate(
      const FrameAverage(r: 5, g: 5, b: 5, satFrac: 0),
      t: 0.75,
      motionStdShort: 0,
    );
    expect(v.debouncedHint, PlacementHint.noFinger);
  });
}
