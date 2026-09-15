import 'activity_state.dart';

/// Resting-state statistics for a single vitals metric (HR, HRV, or RR).
class MetricBaseline {
  const MetricBaseline({
    required this.mean,
    required this.sd,
    required this.variance,
    required this.sdFloorApplied,
    required this.sessionCount,
    required this.updatedAt,
  });

  final double mean;
  final double sd;
  final double variance;
  final bool sdFloorApplied;
  final int sessionCount;

  /// Epoch milliseconds.
  final int updatedAt;

  MetricBaseline copyWith({
    double? mean,
    double? sd,
    double? variance,
    bool? sdFloorApplied,
    int? sessionCount,
    int? updatedAt,
  }) {
    return MetricBaseline(
      mean: mean ?? this.mean,
      sd: sd ?? this.sd,
      variance: variance ?? this.variance,
      sdFloorApplied: sdFloorApplied ?? this.sdFloorApplied,
      sessionCount: sessionCount ?? this.sessionCount,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory MetricBaseline.fromJson(Map<String, dynamic> json) {
    return MetricBaseline(
      mean: (json['mean'] as num).toDouble(),
      sd: (json['sd'] as num).toDouble(),
      variance: (json['variance'] as num).toDouble(),
      sdFloorApplied: json['sd_floor_applied'] as bool,
      sessionCount: json['session_count'] as int,
      updatedAt: json['updated_at'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'mean': mean,
        'sd': sd,
        'variance': variance,
        'sd_floor_applied': sdFloorApplied,
        'session_count': sessionCount,
        'updated_at': updatedAt,
      };
}

/// A user's personal resting baseline for HR, HRV and RR.
class Baseline {
  const Baseline({
    required this.hr,
    required this.hrv,
    required this.rr,
    this.activityState = ActivityStateKind.resting,
    required this.isDemo,
  });

  final MetricBaseline hr;
  final MetricBaseline hrv;
  final MetricBaseline rr;

  /// Always [ActivityStateKind.resting] — baselines are only computed at rest.
  final ActivityStateKind activityState;
  final bool isDemo;

  Baseline copyWith({
    MetricBaseline? hr,
    MetricBaseline? hrv,
    MetricBaseline? rr,
    ActivityStateKind? activityState,
    bool? isDemo,
  }) {
    return Baseline(
      hr: hr ?? this.hr,
      hrv: hrv ?? this.hrv,
      rr: rr ?? this.rr,
      activityState: activityState ?? this.activityState,
      isDemo: isDemo ?? this.isDemo,
    );
  }

  factory Baseline.fromJson(Map<String, dynamic> json) {
    return Baseline(
      hr: MetricBaseline.fromJson(json['hr'] as Map<String, dynamic>),
      hrv: MetricBaseline.fromJson(json['hrv'] as Map<String, dynamic>),
      rr: MetricBaseline.fromJson(json['rr'] as Map<String, dynamic>),
      activityState: json['activity_state'] != null
          ? ActivityStateKind.fromJson(json['activity_state'] as String)
          : ActivityStateKind.resting,
      isDemo: json['is_demo'] as bool,
    );
  }

  Map<String, dynamic> toJson() => {
        'hr': hr.toJson(),
        'hrv': hrv.toJson(),
        'rr': rr.toJson(),
        'activity_state': activityState.toJson(),
        'is_demo': isDemo,
      };
}
