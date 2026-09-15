import 'dart:async';

import '../api/events.dart' show AlertEvent, AlertEventKind, RiskLevel;
import '../core/config/thresholds.dart';
import '../core/models/escalation_payload.dart';
import 'alert_effects.dart';

enum AlertControllerState { none, checkIn, escalated, cooldown }

/// The check-in / escalation / cooldown state machine (§7.11):
/// `none -> checkIn -> (userOk | escalated -> cancelled) -> cooldown -> none`.
/// Escalation is always simulated: no SMS/calls are ever sent.
class AlertController {
  AlertController({
    required this.thresholds,
    AlertEffects? effects,
  }) : effects = effects ?? DefaultAlertEffects();

  final Thresholds thresholds;
  final AlertEffects effects;

  final _eventsController = StreamController<AlertEvent>.broadcast(sync: true);
  Stream<AlertEvent> get events => _eventsController.stream;

  AlertControllerState _state = AlertControllerState.none;
  AlertControllerState get state => _state;

  EscalationPayload? _activePayload;
  EscalationPayload? get activePayload => _activePayload;

  int? _checkInDeadlineMs;
  int? _cooldownUntilMs;

  /// Seconds remaining in the open check-in countdown, or null if none is
  /// open. Recomputed on demand (not just at [tick] time) for snapshot reads.
  int? checkInRemainingSeconds(int nowMs) {
    if (_state != AlertControllerState.checkIn || _checkInDeadlineMs == null) return null;
    return ((_checkInDeadlineMs! - nowMs) / 1000).ceil();
  }

  void dispose() => _eventsController.close();

  /// Call once per scan-orchestration tick. Opens a check-in when [level]
  /// is `high` and nothing is already active; advances the countdown;
  /// auto-escalates on timeout; clears an expired cooldown.
  void tick({
    required RiskLevel level,
    required int nowMs,
    required EscalationPayload Function() buildPayload,
  }) {
    if (_state == AlertControllerState.cooldown) {
      if (_cooldownUntilMs != null && nowMs >= _cooldownUntilMs!) {
        _state = AlertControllerState.none;
        _cooldownUntilMs = null;
        _emit(AlertEventKind.cooldownEnded, nowMs);
      }
      return;
    }

    if (_state == AlertControllerState.checkIn) {
      final deadline = _checkInDeadlineMs!;
      if (nowMs >= deadline) {
        _escalate(nowMs);
      } else {
        final remaining = ((deadline - nowMs) / 1000).ceil();
        effects.onCheckInTick(remaining);
        _emit(AlertEventKind.checkInTick, nowMs, remainingSeconds: remaining);
      }
      return;
    }

    if (_state == AlertControllerState.none && level == RiskLevel.high) {
      _openCheckIn(nowMs, buildPayload());
    }
  }

  void _openCheckIn(int nowMs, EscalationPayload payload) {
    _state = AlertControllerState.checkIn;
    _checkInDeadlineMs = nowMs + (thresholds.alerts.checkinTimeoutS * 1000).round();
    _activePayload = payload;
    effects.onCheckInOpened();
    effects.enableWakelock();
    _emit(
      AlertEventKind.checkInOpened,
      nowMs,
      remainingSeconds: thresholds.alerts.checkinTimeoutS.round(),
      payload: _activePayload,
    );
  }

  /// The user answered the check-in. `ok: true` -> resolved, cooldown
  /// starts. `ok: false` -> escalated (simulated contact).
  void respondCheckIn({required bool ok, required int nowMs}) {
    if (_state != AlertControllerState.checkIn) return;
    if (ok) {
      _activePayload = _activePayload?.copyWith(status: EscalationStatus.userOk);
      _emit(AlertEventKind.resolved, nowMs, payload: _activePayload);
      _startCooldown(nowMs);
    } else {
      _escalate(nowMs);
    }
  }

  void _escalate(int nowMs) {
    _state = AlertControllerState.escalated;
    _activePayload = _activePayload?.copyWith(status: EscalationStatus.escalated);
    effects.onEscalated();
    _emit(AlertEventKind.escalated, nowMs, payload: _activePayload);
  }

  /// Cancels an open check-in or an already-escalated alert; starts cooldown.
  void cancelEscalation(int nowMs) {
    if (_state != AlertControllerState.checkIn && _state != AlertControllerState.escalated) {
      return;
    }
    _activePayload = _activePayload?.copyWith(status: EscalationStatus.cancelled);
    _emit(AlertEventKind.resolved, nowMs, payload: _activePayload);
    _startCooldown(nowMs);
  }

  void _startCooldown(int nowMs) {
    _state = AlertControllerState.cooldown;
    _cooldownUntilMs = nowMs + (thresholds.alerts.cooldownS * 1000).round();
    effects.disableWakelock();
    _emit(AlertEventKind.cooldownStarted, nowMs);
  }

  /// Called by the orchestrator when a scan ends without the user having
  /// answered an open check-in: resolves it as escalated.
  EscalationPayload? resolveUnansweredOnScanEnd(int nowMs) {
    if (_state == AlertControllerState.checkIn) {
      _escalate(nowMs);
    }
    return _activePayload;
  }

  /// Resets check-in state for a new scan. An active cooldown is preserved.
  void resetForNewScan() {
    if (_state != AlertControllerState.cooldown) {
      _state = AlertControllerState.none;
      _activePayload = null;
      _checkInDeadlineMs = null;
    }
  }

  void _emit(AlertEventKind kind, int nowMs, {int? remainingSeconds, EscalationPayload? payload}) {
    _eventsController.add(AlertEvent(
      kind: kind,
      timestamp: nowMs,
      remainingSeconds: remainingSeconds,
      payload: payload,
    ));
  }
}
