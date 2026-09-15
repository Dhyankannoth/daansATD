enum BodySystem {
  cardiovascular,
  respiratory,
  autonomic;

  String toJson() => name;

  static BodySystem fromJson(String value) =>
      BodySystem.values.firstWhere((e) => e.name == value);
}

/// One system's deviation-from-baseline verdict for a single tick.
class DeviationFlag {
  const DeviationFlag({
    required this.timestamp,
    required this.system,
    required this.deviating,
    required this.severity,
    required this.metric,
    required this.value,
    required this.baseline,
    required this.z,
    required this.trusted,
    required this.reason,
    this.recoveringSuppressed = false,
  });

  final int timestamp;
  final BodySystem system;
  final bool deviating;

  /// 0..1
  final double severity;
  final String metric;
  final double? value;
  final double baseline;
  final double? z;
  final bool trusted;
  final String reason;

  /// True when this tick would otherwise be deviating but was suppressed
  /// because the metric is moving back toward baseline during recovery.
  final bool recoveringSuppressed;

  factory DeviationFlag.fromJson(Map<String, dynamic> json) {
    return DeviationFlag(
      timestamp: json['timestamp'] as int,
      system: BodySystem.fromJson(json['system'] as String),
      deviating: json['deviating'] as bool,
      severity: (json['severity'] as num).toDouble(),
      metric: json['metric'] as String,
      value: (json['value'] as num?)?.toDouble(),
      baseline: (json['baseline'] as num).toDouble(),
      z: (json['z'] as num?)?.toDouble(),
      trusted: json['trusted'] as bool,
      reason: json['reason'] as String,
      recoveringSuppressed: json['recovering_suppressed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp,
    'system': system.toJson(),
    'deviating': deviating,
    'severity': severity,
    'metric': metric,
    'value': value,
    'baseline': baseline,
    'z': z,
    'trusted': trusted,
    'reason': reason,
    'recovering_suppressed': recoveringSuppressed,
  };
}
