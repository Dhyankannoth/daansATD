import 'package:flutter/foundation.dart' show debugPrint;

import '../api/events.dart' show PlacementHint;
import '../core/config/thresholds.dart';
import 'frame_averager.dart' show FrameAverage;

class FrameValidation {
  const FrameValidation({
    required this.fingerPresent,
    required this.valid,
    required this.rawHint,
  });

  final bool fingerPresent;
  final bool valid;
  final PlacementHint rawHint;
}

/// Per-frame placement/quality checks (§7.1), plus 300 ms debouncing of the
/// displayed [PlacementHint] (the raw per-frame verdict in [FrameValidation]
/// is never debounced — the sample buffer needs it accurate every frame).
class FrameValidator {
  FrameValidator({required this.thresholds});

  final Thresholds thresholds;

  double? _prevR;
  PlacementHint? _debouncedHint;
  PlacementHint? _pendingHint;
  double? _pendingSinceS;
  double _lastLogT = -1;

  FrameValidation validate(
    FrameAverage avg, {
    required double t,
    required double motionStdShort,
  }) {
    final f = thresholds.frame;
    final m = thresholds.motion;

    final fingerCheck =
        avg.r > f.fingerRatio * avg.g && avg.r > f.fingerRatio * avg.b;
    final lightCheck = avg.r > f.minRed;
    final fingerPresent = fingerCheck && lightCheck;

    final clippingCheck = avg.satFrac < f.maxSatFrac;
    final jumpCheck =
        _prevR == null || (avg.r - _prevR!).abs() / _prevR! < f.maxJump;
    final motionCheck = motionStdShort < m.fidgetStd;

    final valid =
        fingerCheck && lightCheck && clippingCheck && jumpCheck && motionCheck;

    PlacementHint rawHint;
    if (!fingerCheck) {
      rawHint = avg.r <= f.minRed
          ? PlacementHint.noFinger
          : PlacementHint.coverLens;
    } else if (!lightCheck) {
      rawHint = PlacementHint.coverFlash;
    } else if (!clippingCheck) {
      rawHint = PlacementHint.pressLighter;
    } else if (!jumpCheck || !motionCheck) {
      rawHint = PlacementHint.keepStill;
    } else {
      rawHint = PlacementHint.ok;
    }

    _prevR = avg.r;
    _debounce(rawHint, t);

    // TEMP DIAGNOSTIC — remove once sensor issue is root-caused.
    if (t - _lastLogT >= 1.0) {
      _lastLogT = t;
      debugPrint(
        '[FRAME-DIAG] t=${t.toStringAsFixed(1)}s r=${avg.r.toStringAsFixed(1)} '
        'g=${avg.g.toStringAsFixed(1)} b=${avg.b.toStringAsFixed(1)} '
        'satFrac=${avg.satFrac.toStringAsFixed(3)} finger=$fingerCheck '
        'light=$lightCheck clip=$clippingCheck jump=$jumpCheck '
        'motion=$motionCheck(std=${motionStdShort.toStringAsFixed(3)}) valid=$valid',
      );
    }

    return FrameValidation(
      fingerPresent: fingerPresent,
      valid: valid,
      rawHint: rawHint,
    );
  }

  /// The debounced hint for display, or null if nothing has been observed
  /// long enough yet (only on the very first frames).
  PlacementHint? get debouncedHint => _debouncedHint;

  void _debounce(PlacementHint raw, double t) {
    if (raw == _debouncedHint) {
      _pendingHint = null;
      _pendingSinceS = null;
      return;
    }
    if (raw != _pendingHint) {
      _pendingHint = raw;
      _pendingSinceS = t;
      return;
    }
    if (t - _pendingSinceS! >= 0.3) {
      _debouncedHint = raw;
      _pendingHint = null;
      _pendingSinceS = null;
    }
  }

  void reset() {
    _prevR = null;
    _debouncedHint = null;
    _pendingHint = null;
    _pendingSinceS = null;
  }
}
