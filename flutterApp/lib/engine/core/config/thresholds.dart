import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Typed view over `assets/config/thresholds.json`. All tunable numbers in
/// the engine come from here — no magic numbers in logic files.
class Thresholds {
  const Thresholds({
    required this.version,
    required this.camera,
    required this.frame,
    required this.motion,
    required this.windowsS,
    required this.scan,
    required this.filter,
    required this.beats,
    required this.resp,
    required this.quality,
    required this.spo2,
    required this.baseline,
    required this.trend,
    required this.deviation,
    required this.fusion,
    required this.ml,
    required this.alerts,
    required this.ox,
  });

  final int version;
  final CameraThresholds camera;
  final FrameThresholds frame;
  final MotionThresholds motion;
  final WindowsSThresholds windowsS;
  final ScanThresholds scan;
  final FilterThresholds filter;
  final BeatsThresholds beats;
  final RespThresholds resp;
  final QualityThresholds quality;
  final Spo2Thresholds spo2;
  final BaselineThresholds baseline;
  final TrendThresholds trend;
  final DeviationThresholds deviation;
  final FusionThresholds fusion;
  final MlThresholds ml;
  final AlertsThresholds alerts;
  final OxThresholds ox;

  static Future<Thresholds> load({
    String assetPath = 'assets/config/thresholds.json',
    AssetBundleLike? bundle,
  }) async {
    final raw = await (bundle ?? _RootBundleAdapter()).loadString(assetPath);
    return Thresholds.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  factory Thresholds.fromJson(Map<String, dynamic> j) {
    final t = Thresholds(
      version: j['version'] as int,
      camera: CameraThresholds.fromJson(j['camera'] as Map<String, dynamic>),
      frame: FrameThresholds.fromJson(j['frame'] as Map<String, dynamic>),
      motion: MotionThresholds.fromJson(j['motion'] as Map<String, dynamic>),
      windowsS: WindowsSThresholds.fromJson(j['windows_s'] as Map<String, dynamic>),
      scan: ScanThresholds.fromJson(j['scan'] as Map<String, dynamic>),
      filter: FilterThresholds.fromJson(j['filter'] as Map<String, dynamic>),
      beats: BeatsThresholds.fromJson(j['beats'] as Map<String, dynamic>),
      resp: RespThresholds.fromJson(j['resp'] as Map<String, dynamic>),
      quality: QualityThresholds.fromJson(j['quality'] as Map<String, dynamic>),
      spo2: Spo2Thresholds.fromJson(j['spo2'] as Map<String, dynamic>),
      baseline: BaselineThresholds.fromJson(j['baseline'] as Map<String, dynamic>),
      trend: TrendThresholds.fromJson(j['trend'] as Map<String, dynamic>),
      deviation: DeviationThresholds.fromJson(j['deviation'] as Map<String, dynamic>),
      fusion: FusionThresholds.fromJson(j['fusion'] as Map<String, dynamic>),
      ml: MlThresholds.fromJson(j['ml'] as Map<String, dynamic>),
      alerts: AlertsThresholds.fromJson(j['alerts'] as Map<String, dynamic>),
      ox: OxThresholds.fromJson(j['ox'] as Map<String, dynamic>),
    );
    t._validate();
    return t;
  }

  void _validate() {
    if (version != 1) {
      throw FormatException('Unsupported thresholds.json version: $version');
    }
  }
}

class CameraThresholds {
  const CameraThresholds({
    required this.settleS,
    required this.exposureStepWaitMs,
    required this.maxExposureSteps,
  });
  final double settleS;
  final int exposureStepWaitMs;
  final int maxExposureSteps;
  factory CameraThresholds.fromJson(Map<String, dynamic> j) => CameraThresholds(
        settleS: (j['settle_s'] as num).toDouble(),
        exposureStepWaitMs: j['exposure_step_wait_ms'] as int,
        maxExposureSteps: j['max_exposure_steps'] as int,
      );
}

class FrameThresholds {
  const FrameThresholds({
    required this.roiFraction,
    required this.pixelStep,
    required this.fingerRatio,
    required this.minRed,
    required this.satPixel,
    required this.maxSatFrac,
    required this.maxJump,
    required this.fingerLostResetS,
  });
  final double roiFraction;
  final int pixelStep;
  final double fingerRatio;
  final double minRed;
  final double satPixel;
  final double maxSatFrac;
  final double maxJump;
  final double fingerLostResetS;
  factory FrameThresholds.fromJson(Map<String, dynamic> j) => FrameThresholds(
        roiFraction: (j['roi_fraction'] as num).toDouble(),
        pixelStep: j['pixel_step'] as int,
        fingerRatio: (j['finger_ratio'] as num).toDouble(),
        minRed: (j['min_red'] as num).toDouble(),
        satPixel: (j['sat_pixel'] as num).toDouble(),
        maxSatFrac: (j['max_sat_frac'] as num).toDouble(),
        maxJump: (j['max_jump'] as num).toDouble(),
        fingerLostResetS: (j['finger_lost_reset_s'] as num).toDouble(),
      );
}

class MotionThresholds {
  const MotionThresholds({
    required this.fidgetStd,
    required this.exerciseStd,
    required this.windowShortS,
    required this.windowLongS,
  });
  final double fidgetStd;
  final double exerciseStd;
  final double windowShortS;
  final double windowLongS;
  factory MotionThresholds.fromJson(Map<String, dynamic> j) => MotionThresholds(
        fidgetStd: (j['fidget_std'] as num).toDouble(),
        exerciseStd: (j['exercise_std'] as num).toDouble(),
        windowShortS: (j['window_short_s'] as num).toDouble(),
        windowLongS: (j['window_long_s'] as num).toDouble(),
      );
}

class WindowsSThresholds {
  const WindowsSThresholds({
    required this.buffer,
    required this.analysis,
    required this.hr,
    required this.spo2,
    required this.hrv,
    required this.rrMin,
    required this.rrMax,
    required this.trend,
  });
  final double buffer;
  final double analysis;
  final double hr;
  final double spo2;
  final double hrv;
  final double rrMin;
  final double rrMax;
  final double trend;
  factory WindowsSThresholds.fromJson(Map<String, dynamic> j) => WindowsSThresholds(
        buffer: (j['buffer'] as num).toDouble(),
        analysis: (j['analysis'] as num).toDouble(),
        hr: (j['hr'] as num).toDouble(),
        spo2: (j['spo2'] as num).toDouble(),
        hrv: (j['hrv'] as num).toDouble(),
        rrMin: (j['rr_min'] as num).toDouble(),
        rrMax: (j['rr_max'] as num).toDouble(),
        trend: (j['trend'] as num).toDouble(),
      );
}

class ScanThresholds {
  const ScanThresholds({
    required this.maxS,
    required this.noSignalEndS,
    required this.calibrationS,
  });
  final double maxS;
  final double noSignalEndS;
  final double calibrationS;
  factory ScanThresholds.fromJson(Map<String, dynamic> j) => ScanThresholds(
        maxS: (j['max_s'] as num).toDouble(),
        noSignalEndS: (j['no_signal_end_s'] as num).toDouble(),
        calibrationS: (j['calibration_s'] as num).toDouble(),
      );
}

class FilterThresholds {
  const FilterThresholds({
    required this.resampleHz,
    required this.bandpassLowHz,
    required this.bandpassHighHz,
    required this.padS,
    required this.respHz,
    required this.respBandHz,
    required this.respStepHz,
  });
  final double resampleHz;
  final double bandpassLowHz;
  final double bandpassHighHz;
  final double padS;
  final double respHz;
  final List<double> respBandHz;
  final double respStepHz;
  factory FilterThresholds.fromJson(Map<String, dynamic> j) => FilterThresholds(
        resampleHz: (j['resample_hz'] as num).toDouble(),
        bandpassLowHz: (j['bandpass_low_hz'] as num).toDouble(),
        bandpassHighHz: (j['bandpass_high_hz'] as num).toDouble(),
        padS: (j['pad_s'] as num).toDouble(),
        respHz: (j['resp_hz'] as num).toDouble(),
        respBandHz:
            (j['resp_band_hz'] as List).map((e) => (e as num).toDouble()).toList(),
        respStepHz: (j['resp_step_hz'] as num).toDouble(),
      );
}

class BeatsThresholds {
  const BeatsThresholds({
    required this.minGapS,
    required this.minHeightSd,
    required this.edgeIgnoreS,
    required this.ibiMinS,
    required this.ibiMaxS,
    required this.hrIbiTolerance,
    required this.hrvIbiTolerance,
    required this.hrMinIntervals,
    required this.hrvMinIntervals,
    required this.hrvMinPairs,
  });
  final double minGapS;
  final double minHeightSd;
  final double edgeIgnoreS;
  final double ibiMinS;
  final double ibiMaxS;
  final double hrIbiTolerance;
  final double hrvIbiTolerance;
  final int hrMinIntervals;
  final int hrvMinIntervals;
  final int hrvMinPairs;
  factory BeatsThresholds.fromJson(Map<String, dynamic> j) => BeatsThresholds(
        minGapS: (j['min_gap_s'] as num).toDouble(),
        minHeightSd: (j['min_height_sd'] as num).toDouble(),
        edgeIgnoreS: (j['edge_ignore_s'] as num).toDouble(),
        ibiMinS: (j['ibi_min_s'] as num).toDouble(),
        ibiMaxS: (j['ibi_max_s'] as num).toDouble(),
        hrIbiTolerance: (j['hr_ibi_tolerance'] as num).toDouble(),
        hrvIbiTolerance: (j['hrv_ibi_tolerance'] as num).toDouble(),
        hrMinIntervals: j['hr_min_intervals'] as int,
        hrvMinIntervals: j['hrv_min_intervals'] as int,
        hrvMinPairs: j['hrv_min_pairs'] as int,
      );
}

class RespThresholds {
  const RespThresholds({
    required this.minProminence,
    required this.agreeBpm,
    required this.agreeQuality,
    required this.singleQuality,
  });
  final double minProminence;
  final double agreeBpm;
  final double agreeQuality;
  final double singleQuality;
  factory RespThresholds.fromJson(Map<String, dynamic> j) => RespThresholds(
        minProminence: (j['min_prominence'] as num).toDouble(),
        agreeBpm: (j['agree_bpm'] as num).toDouble(),
        agreeQuality: (j['agree_quality'] as num).toDouble(),
        singleQuality: (j['single_quality'] as num).toDouble(),
      );
}

class QualityThresholds {
  const QualityThresholds({
    required this.trusted,
    required this.displayMin,
    required this.minValidFrac,
    required this.maxGapS,
  });
  final double trusted;
  final double displayMin;
  final double minValidFrac;
  final double maxGapS;
  factory QualityThresholds.fromJson(Map<String, dynamic> j) => QualityThresholds(
        trusted: (j['trusted'] as num).toDouble(),
        displayMin: (j['display_min'] as num).toDouble(),
        minValidFrac: (j['min_valid_frac'] as num).toDouble(),
        maxGapS: (j['max_gap_s'] as num).toDouble(),
      );
}

class Spo2Thresholds {
  const Spo2Thresholds({required this.referenceWindows});
  final int referenceWindows;
  factory Spo2Thresholds.fromJson(Map<String, dynamic> j) =>
      Spo2Thresholds(referenceWindows: j['reference_windows'] as int);
}

class BaselineThresholds {
  const BaselineThresholds({
    required this.minTicksHr,
    required this.minTicksHrv,
    required this.minTicksRr,
    required this.sdFloorHr,
    required this.sdFloorHrvMs,
    required this.sdFloorHrvFrac,
    required this.sdFloorRr,
    required this.updateAlpha,
    required this.minSessionsForSessionSd,
  });
  final int minTicksHr;
  final int minTicksHrv;
  final int minTicksRr;
  final double sdFloorHr;
  final double sdFloorHrvMs;
  final double sdFloorHrvFrac;
  final double sdFloorRr;
  final double updateAlpha;
  final int minSessionsForSessionSd;
  factory BaselineThresholds.fromJson(Map<String, dynamic> j) => BaselineThresholds(
        minTicksHr: j['min_ticks_hr'] as int,
        minTicksHrv: j['min_ticks_hrv'] as int,
        minTicksRr: j['min_ticks_rr'] as int,
        sdFloorHr: (j['sd_floor_hr'] as num).toDouble(),
        sdFloorHrvMs: (j['sd_floor_hrv_ms'] as num).toDouble(),
        sdFloorHrvFrac: (j['sd_floor_hrv_frac'] as num).toDouble(),
        sdFloorRr: (j['sd_floor_rr'] as num).toDouble(),
        updateAlpha: (j['update_alpha'] as num).toDouble(),
        minSessionsForSessionSd: j['min_sessions_for_session_sd'] as int,
      );
}

class TrendThresholds {
  const TrendThresholds({required this.minPoints});
  final int minPoints;
  factory TrendThresholds.fromJson(Map<String, dynamic> j) =>
      TrendThresholds(minPoints: j['min_points'] as int);
}

class DeviationThresholds {
  const DeviationThresholds({
    required this.hrZ,
    required this.rrZ,
    required this.hrvZ,
    required this.severityScale,
    required this.recoveringHrSlope,
    required this.recoveringRrSlope,
    required this.recoveringHrvSlope,
    required this.recoveringMaxSinceExerciseS,
  });
  final double hrZ;
  final double rrZ;
  final double hrvZ;
  final double severityScale;
  final double recoveringHrSlope;
  final double recoveringRrSlope;
  final double recoveringHrvSlope;
  final double recoveringMaxSinceExerciseS;
  factory DeviationThresholds.fromJson(Map<String, dynamic> j) => DeviationThresholds(
        hrZ: (j['hr_z'] as num).toDouble(),
        rrZ: (j['rr_z'] as num).toDouble(),
        hrvZ: (j['hrv_z'] as num).toDouble(),
        severityScale: (j['severity_scale'] as num).toDouble(),
        recoveringHrSlope: (j['recovering_hr_slope'] as num).toDouble(),
        recoveringRrSlope: (j['recovering_rr_slope'] as num).toDouble(),
        recoveringHrvSlope: (j['recovering_hrv_slope'] as num).toDouble(),
        recoveringMaxSinceExerciseS:
            (j['recovering_max_since_exercise_s'] as num).toDouble(),
      );
}

class FusionThresholds {
  const FusionThresholds({
    required this.persistenceWindow,
    required this.persistenceMin,
    required this.watchdogFingerLostS,
    required this.watchdogRecentS,
  });
  final int persistenceWindow;
  final int persistenceMin;
  final double watchdogFingerLostS;
  final double watchdogRecentS;
  factory FusionThresholds.fromJson(Map<String, dynamic> j) => FusionThresholds(
        persistenceWindow: j['persistence_window'] as int,
        persistenceMin: j['persistence_min'] as int,
        watchdogFingerLostS: (j['watchdog_finger_lost_s'] as num).toDouble(),
        watchdogRecentS: (j['watchdog_recent_s'] as num).toDouble(),
      );
}

class MlThresholds {
  const MlThresholds({
    required this.rowWindowS,
    required this.rowMinTrustedFrac,
    required this.carryForwardS,
    required this.metricMinPoints,
    required this.smoothingS,
    required this.fallbackAnomalyThreshold,
    required this.riskHigh,
    required this.sustainS,
  });
  final double rowWindowS;
  final double rowMinTrustedFrac;
  final double carryForwardS;
  final int metricMinPoints;
  final double smoothingS;
  final double fallbackAnomalyThreshold;
  final double riskHigh;
  final double sustainS;
  factory MlThresholds.fromJson(Map<String, dynamic> j) => MlThresholds(
        rowWindowS: (j['row_window_s'] as num).toDouble(),
        rowMinTrustedFrac: (j['row_min_trusted_frac'] as num).toDouble(),
        carryForwardS: (j['carry_forward_s'] as num).toDouble(),
        metricMinPoints: j['metric_min_points'] as int,
        smoothingS: (j['smoothing_s'] as num).toDouble(),
        fallbackAnomalyThreshold: (j['fallback_anomaly_threshold'] as num).toDouble(),
        riskHigh: (j['risk_high'] as num).toDouble(),
        sustainS: (j['sustain_s'] as num).toDouble(),
      );
}

class AlertsThresholds {
  const AlertsThresholds({required this.checkinTimeoutS, required this.cooldownS});
  final double checkinTimeoutS;
  final double cooldownS;
  factory AlertsThresholds.fromJson(Map<String, dynamic> j) => AlertsThresholds(
        checkinTimeoutS: (j['checkin_timeout_s'] as num).toDouble(),
        cooldownS: (j['cooldown_s'] as num).toDouble(),
      );
}

class OxThresholds {
  const OxThresholds({required this.calibrationAsset});
  final String calibrationAsset;
  factory OxThresholds.fromJson(Map<String, dynamic> j) =>
      OxThresholds(calibrationAsset: j['calibration_asset'] as String);
}

/// Minimal seam over asset loading so config can be loaded in tests without
/// a Flutter binding.
abstract class AssetBundleLike {
  Future<String> loadString(String key);
}

class _RootBundleAdapter implements AssetBundleLike {
  @override
  Future<String> loadString(String key) => rootBundle.loadString(key);
}
