/// Where a [VitalsReading] tick originated.
enum VitalsReadingSource {
  camera,
  replay,
  watch;

  String toJson() => name;

  static VitalsReadingSource fromJson(String value) =>
      VitalsReadingSource.values.firstWhere((e) => e.name == value);
}

/// One second's worth of derived vitals.
///
/// A `null` field always means "not derivable this tick" — never 0 or a
/// stale repeat of the previous value.
class VitalsReading {
  const VitalsReading({
    required this.timestamp,
    required this.hr,
    required this.hrv,
    required this.rr,
    required this.spo2,
    required this.oxTrend,
    required this.quality,
    required this.rrQuality,
    required this.fingerPresent,
    required this.source,
  });

  /// Epoch milliseconds.
  final int timestamp;
  final double? hr;

  /// RMSSD in milliseconds.
  final double? hrv;
  final double? rr;

  /// Only non-null when phone-calibrated and in range. Display only.
  final double? spo2;

  /// % change of red/green ratio vs scan start. Display only.
  final double? oxTrend;

  /// 0..1
  final double quality;

  /// 0..1
  final double rrQuality;
  final bool fingerPresent;
  final VitalsReadingSource source;

  VitalsReading copyWith({
    int? timestamp,
    double? hr,
    bool hrIsSet = false,
    double? hrv,
    bool hrvIsSet = false,
    double? rr,
    bool rrIsSet = false,
    double? spo2,
    bool spo2IsSet = false,
    double? oxTrend,
    bool oxTrendIsSet = false,
    double? quality,
    double? rrQuality,
    bool? fingerPresent,
    VitalsReadingSource? source,
  }) {
    return VitalsReading(
      timestamp: timestamp ?? this.timestamp,
      hr: hrIsSet ? hr : (hr ?? this.hr),
      hrv: hrvIsSet ? hrv : (hrv ?? this.hrv),
      rr: rrIsSet ? rr : (rr ?? this.rr),
      spo2: spo2IsSet ? spo2 : (spo2 ?? this.spo2),
      oxTrend: oxTrendIsSet ? oxTrend : (oxTrend ?? this.oxTrend),
      quality: quality ?? this.quality,
      rrQuality: rrQuality ?? this.rrQuality,
      fingerPresent: fingerPresent ?? this.fingerPresent,
      source: source ?? this.source,
    );
  }

  factory VitalsReading.fromJson(Map<String, dynamic> json) {
    return VitalsReading(
      timestamp: json['timestamp'] as int,
      hr: (json['hr'] as num?)?.toDouble(),
      hrv: (json['hrv'] as num?)?.toDouble(),
      rr: (json['rr'] as num?)?.toDouble(),
      spo2: (json['spo2'] as num?)?.toDouble(),
      oxTrend: (json['ox_trend'] as num?)?.toDouble(),
      quality: (json['quality'] as num).toDouble(),
      rrQuality: (json['rr_quality'] as num).toDouble(),
      fingerPresent: json['finger_present'] as bool,
      source: VitalsReadingSource.fromJson(json['source'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp,
    'hr': hr,
    'hrv': hrv,
    'rr': rr,
    'spo2': spo2,
    'ox_trend': oxTrend,
    'quality': quality,
    'rr_quality': rrQuality,
    'finger_present': fingerPresent,
    'source': source.toJson(),
  };
}
