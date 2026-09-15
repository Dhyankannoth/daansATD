import 'deviation_flag.dart';
import 'emergency_contact.dart';
import 'vitals_reading.dart';

enum EscalationTriggerType {
  multiSystem,
  mlSupported,
  signalLoss;

  String toJson() => switch (this) {
        EscalationTriggerType.multiSystem => 'multi_system',
        EscalationTriggerType.mlSupported => 'ml_supported',
        EscalationTriggerType.signalLoss => 'signal_loss',
      };

  static EscalationTriggerType fromJson(String value) => switch (value) {
        'multi_system' => EscalationTriggerType.multiSystem,
        'ml_supported' => EscalationTriggerType.mlSupported,
        'signal_loss' => EscalationTriggerType.signalLoss,
        _ => throw ArgumentError('Unknown trigger type: $value'),
      };
}

enum EscalationStatus {
  pending,
  userOk,
  escalated,
  cancelled;

  String toJson() => switch (this) {
        EscalationStatus.pending => 'pending',
        EscalationStatus.userOk => 'user_ok',
        EscalationStatus.escalated => 'escalated',
        EscalationStatus.cancelled => 'cancelled',
      };

  static EscalationStatus fromJson(String value) => switch (value) {
        'pending' => EscalationStatus.pending,
        'user_ok' => EscalationStatus.userOk,
        'escalated' => EscalationStatus.escalated,
        'cancelled' => EscalationStatus.cancelled,
        _ => throw ArgumentError('Unknown escalation status: $value'),
      };
}

/// The payload built when a check-in / escalation opens, carried through
/// to its resolution.
class EscalationPayload {
  const EscalationPayload({
    required this.triggeredAt,
    required this.triggerType,
    required this.systems,
    required this.reasons,
    required this.vitalsSnapshot,
    this.timeoutSeconds = 30,
    required this.contact,
    required this.status,
    this.cooldownUntil,
  });

  final int triggeredAt;
  final EscalationTriggerType triggerType;
  final List<BodySystem> systems;
  final List<String> reasons;
  final VitalsReading vitalsSnapshot;
  final int timeoutSeconds;
  final EmergencyContact contact;
  final EscalationStatus status;
  final int? cooldownUntil;

  EscalationPayload copyWith({
    EscalationStatus? status,
    int? cooldownUntil,
    bool cooldownUntilIsSet = false,
  }) {
    return EscalationPayload(
      triggeredAt: triggeredAt,
      triggerType: triggerType,
      systems: systems,
      reasons: reasons,
      vitalsSnapshot: vitalsSnapshot,
      timeoutSeconds: timeoutSeconds,
      contact: contact,
      status: status ?? this.status,
      cooldownUntil:
          cooldownUntilIsSet ? cooldownUntil : (cooldownUntil ?? this.cooldownUntil),
    );
  }

  factory EscalationPayload.fromJson(Map<String, dynamic> json) {
    return EscalationPayload(
      triggeredAt: json['triggered_at'] as int,
      triggerType: EscalationTriggerType.fromJson(json['trigger_type'] as String),
      systems: (json['systems'] as List)
          .map((e) => BodySystem.fromJson(e as String))
          .toList(),
      reasons: (json['reasons'] as List).map((e) => e as String).toList(),
      vitalsSnapshot:
          VitalsReading.fromJson(json['vitals_snapshot'] as Map<String, dynamic>),
      timeoutSeconds: json['timeout_seconds'] as int? ?? 30,
      contact: EmergencyContact.fromJson(json['contact'] as Map<String, dynamic>),
      status: EscalationStatus.fromJson(json['status'] as String),
      cooldownUntil: json['cooldown_until'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'triggered_at': triggeredAt,
        'trigger_type': triggerType.toJson(),
        'systems': systems.map((e) => e.toJson()).toList(),
        'reasons': reasons,
        'vitals_snapshot': vitalsSnapshot.toJson(),
        'timeout_seconds': timeoutSeconds,
        'contact': contact.toJson(),
        'status': status.toJson(),
        'cooldown_until': cooldownUntil,
      };
}
