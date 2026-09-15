enum ActivityStateKind {
  resting,
  recovering,
  exercising,
  unknown;

  String toJson() => name;

  static ActivityStateKind fromJson(String value) =>
      ActivityStateKind.values.firstWhere((e) => e.name == value);
}

/// How an [ActivityState] classification was derived.
enum ActivityBasis {
  selfReport,
  accelerometer,
  classifier;

  String toJson() => switch (this) {
    ActivityBasis.selfReport => 'self_report',
    ActivityBasis.accelerometer => 'accelerometer',
    ActivityBasis.classifier => 'classifier',
  };

  static ActivityBasis fromJson(String value) => switch (value) {
    'self_report' => ActivityBasis.selfReport,
    'accelerometer' => ActivityBasis.accelerometer,
    'classifier' => ActivityBasis.classifier,
    _ => throw ArgumentError('Unknown activity basis: $value'),
  };
}

/// Current motion/exercise classification of the user during a scan.
class ActivityState {
  const ActivityState({
    required this.timestamp,
    required this.state,
    required this.confidence,
    required this.basis,
  });

  final int timestamp;
  final ActivityStateKind state;
  final double confidence;
  final ActivityBasis basis;

  factory ActivityState.fromJson(Map<String, dynamic> json) {
    return ActivityState(
      timestamp: json['timestamp'] as int,
      state: ActivityStateKind.fromJson(json['state'] as String),
      confidence: (json['confidence'] as num).toDouble(),
      basis: ActivityBasis.fromJson(json['basis'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp,
    'state': state.toJson(),
    'confidence': confidence,
    'basis': basis.toJson(),
  };
}
