/// One tick's ML feature vector, in `feature_spec.json` order.
class FeatureRow {
  const FeatureRow({
    required this.timestamp,
    required this.values,
    required this.valid,
  });

  final int timestamp;

  /// Length matches `feature_spec.json`'s `features` list when [valid].
  final List<double> values;

  /// False when the row gate (baseline present, trusted-tick fraction,
  /// trend availability, etc.) was not satisfied this tick.
  final bool valid;

  factory FeatureRow.fromJson(Map<String, dynamic> json) {
    return FeatureRow(
      timestamp: json['timestamp'] as int,
      values: (json['values'] as List)
          .map((e) => (e as num).toDouble())
          .toList(),
      valid: json['valid'] as bool,
    );
  }

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp,
    'values': values,
    'valid': valid,
  };
}
