import 'package:flutter/services.dart' show HapticFeedback;
import 'package:wakelock_plus/wakelock_plus.dart';

/// Side effects the alert controller triggers on state transitions. Kept as
/// an interface so tests (and the debug page) can substitute a no-op or
/// recording implementation.
abstract class AlertEffects {
  void onCheckInOpened();
  void onCheckInTick(int remainingSeconds);
  void onEscalated();
  Future<void> enableWakelock();
  Future<void> disableWakelock();
}

/// Default implementation: heavy haptic feedback on open/escalate (and each
/// countdown second), plus keeping the screen on via `wakelock_plus`.
class DefaultAlertEffects implements AlertEffects {
  @override
  void onCheckInOpened() => HapticFeedback.heavyImpact();

  @override
  void onCheckInTick(int remainingSeconds) => HapticFeedback.heavyImpact();

  @override
  void onEscalated() => HapticFeedback.heavyImpact();

  @override
  Future<void> enableWakelock() => WakelockPlus.enable();

  @override
  Future<void> disableWakelock() => WakelockPlus.disable();
}
