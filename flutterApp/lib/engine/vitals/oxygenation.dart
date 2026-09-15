import '../dsp/stats.dart' show median;

/// Optional per-device SpO2 calibration, loaded from
/// `assets/config/spo2_calibration.json` when present. Absent by default —
/// `spo2` is then always null (display-only, experimental).
class OxCalibration {
  const OxCalibration({
    required this.deviceLabel,
    required this.a,
    required this.b,
    required this.ratioMin,
    required this.ratioMax,
    required this.spo2Min,
  });

  final String deviceLabel;
  final double a;
  final double b;
  final double ratioMin;
  final double ratioMax;
  final double spo2Min;

  factory OxCalibration.fromJson(Map<String, dynamic> j) => OxCalibration(
        deviceLabel: j['device_label'] as String,
        a: (j['a'] as num).toDouble(),
        b: (j['b'] as num).toDouble(),
        ratioMin: (j['ratio_min'] as num).toDouble(),
        ratioMax: (j['ratio_max'] as num).toDouble(),
        spo2Min: (j['spo2_min'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'device_label': deviceLabel,
        'a': a,
        'b': b,
        'ratio_min': ratioMin,
        'ratio_max': ratioMax,
        'spo2_min': spo2Min,
      };
}

class OxResult {
  const OxResult({required this.ratio, required this.oxTrend, required this.spo2});
  final double? ratio;
  final double? oxTrend;
  final double? spo2;
}

/// Tracks the within-scan red/green ratio reference and derives `oxTrend`
/// (and, if a calibration is supplied, an experimental `spo2`) each tick.
/// SpO2 and oxTrend are display-only: never consumed by deviation, fusion,
/// the feature builder, or any ML model.
class OxygenationTracker {
  OxygenationTracker({required this.referenceWindows});

  final int referenceWindows;
  final List<double> _acceptedRatios = [];
  double? _fixedReference;

  double? get reference => _fixedReference;

  void reset() {
    _acceptedRatios.clear();
    _fixedReference = null;
  }

  OxResult tick({
    required double acRed,
    required double dcRed,
    required double acGreen,
    required double dcGreen,
    required bool qualityTrusted,
    OxCalibration? calibration,
  }) {
    if (!qualityTrusted || dcRed == 0 || dcGreen == 0 || acGreen == 0) {
      return const OxResult(ratio: null, oxTrend: null, spo2: null);
    }

    final ratio = (acRed / dcRed) / (acGreen / dcGreen);

    if (_fixedReference == null && _acceptedRatios.length < referenceWindows) {
      _acceptedRatios.add(ratio);
      if (_acceptedRatios.length == referenceWindows) {
        _fixedReference = median(_acceptedRatios);
      }
    }

    final ref = _fixedReference;
    final oxTrend = ref == null ? null : (ratio / ref - 1) * 100;

    double? spo2;
    if (calibration != null &&
        ratio >= calibration.ratioMin &&
        ratio <= calibration.ratioMax) {
      final raw = calibration.a - calibration.b * ratio;
      spo2 = raw > 100 ? 100 : raw;
    }

    return OxResult(ratio: ratio, oxTrend: oxTrend, spo2: spo2);
  }
}
