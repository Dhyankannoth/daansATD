import '../../engine/api/engine_snapshot.dart';
import '../../engine/api/events.dart';
import '../../engine/core/models/activity_state.dart';

/// Persisted record of a finished spot measurement.
class MeasurementRecord {
  final String id;
  final int timestamp;
  final int durationSeconds;
  final double? medianHr;
  final double? medianHrv;
  final double? medianRr;
  final double? spo2;
  final RiskLevel maxRiskLevel;
  final AlertOutcome alertOutcome;
  final double trustedFraction;
  final ActivityStateKind activityState;
  final String? notes;

  const MeasurementRecord({
    required this.id,
    required this.timestamp,
    required this.durationSeconds,
    this.medianHr,
    this.medianHrv,
    this.medianRr,
    this.spo2,
    required this.maxRiskLevel,
    required this.alertOutcome,
    required this.trustedFraction,
    required this.activityState,
    this.notes,
  });

  factory MeasurementRecord.fromScanSummary({
    required ScanSummary summary,
    required ActivityStateKind activityState,
    double? spo2,
    String? notes,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return MeasurementRecord(
      id: 'scan_$now',
      timestamp: now,
      durationSeconds: summary.duration.inSeconds,
      medianHr: summary.medianHr,
      medianHrv: summary.medianHrv,
      medianRr: summary.medianRr,
      spo2: spo2,
      maxRiskLevel: summary.maxLevel,
      alertOutcome: summary.alertOutcome,
      trustedFraction: summary.trustedFraction,
      activityState: activityState,
      notes: notes,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp,
    'duration_seconds': durationSeconds,
    'median_hr': medianHr,
    'median_hrv': medianHrv,
    'median_rr': medianRr,
    'spo2': spo2,
    'max_risk_level': maxRiskLevel.toJson(),
    'alert_outcome': alertOutcome.name,
    'trusted_fraction': trustedFraction,
    'activity_state': activityState.toJson(),
    'notes': notes,
  };

  factory MeasurementRecord.fromJson(Map<String, dynamic> json) {
    return MeasurementRecord(
      id: json['id'] as String,
      timestamp: json['timestamp'] as int,
      durationSeconds: json['duration_seconds'] as int,
      medianHr: (json['median_hr'] as num?)?.toDouble(),
      medianHrv: (json['median_hrv'] as num?)?.toDouble(),
      medianRr: (json['median_rr'] as num?)?.toDouble(),
      spo2: (json['spo2'] as num?)?.toDouble(),
      maxRiskLevel: RiskLevel.fromJson(json['max_risk_level'] as String),
      alertOutcome: AlertOutcome.values.firstWhere(
        (e) => e.name == json['alert_outcome'],
        orElse: () => AlertOutcome.none,
      ),
      trustedFraction: (json['trusted_fraction'] as num).toDouble(),
      activityState: ActivityStateKind.fromJson(
        json['activity_state'] as String,
      ),
      notes: json['notes'] as String?,
    );
  }
}
