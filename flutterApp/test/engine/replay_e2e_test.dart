import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pulseguard/engine/alerts/alert_effects.dart';
import 'package:pulseguard/engine/api/engine_snapshot.dart';
import 'package:pulseguard/engine/api/events.dart';
import 'package:pulseguard/engine/core/config/thresholds.dart'
    show AssetBundleLike;
import 'package:pulseguard/engine/core/clock.dart';
import 'package:pulseguard/engine/core/models/escalation_payload.dart';
import 'package:pulseguard/engine/pulseguard_engine.dart';

class _FileBundle implements AssetBundleLike {
  @override
  Future<String> loadString(String key) => File(key).readAsString();
}

/// No-op effects: avoids touching platform channels (haptics, wakelock)
/// that require a real Flutter binding.
class _NoopAlertEffects implements AlertEffects {
  @override
  void onCheckInOpened() {}
  @override
  void onCheckInTick(int remainingSeconds) {}
  @override
  void onEscalated() {}
  @override
  Future<void> enableWakelock() async {}
  @override
  Future<void> disableWakelock() async {}
}

void main() {
  test(
    'reaction.json (with demo baseline) reaches high between t=50s and t=110s '
    'and opens exactly one check-in',
    () async {
      final clock = FakeClock();
      final engine = PulseGuardEngine(
        clock: clock,
        bundle: _FileBundle(),
        alertEffects: _NoopAlertEffects(),
      );
      await engine.initialize();

      var checkInOpenedCount = 0;
      final highTimestampsMs = <int>[];
      engine.alerts.listen((e) {
        if (e.kind == AlertEventKind.checkInOpened) checkInOpenedCount++;
      });
      engine.risk.listen((r) {
        if (r.level == RiskLevel.high) highTimestampsMs.add(r.timestamp);
      });

      await engine.startReplay(
        'assets/traces/reaction.json',
        speed: 100,
        useDemoBaseline: true,
      );
      final summary = await engine.scanFinished.first;

      expect(summary.endReason, ScanEndReason.replayFinished);
      expect(checkInOpenedCount, 1);
      expect(highTimestampsMs, isNotEmpty);
      final firstHighS = highTimestampsMs.first / 1000.0;
      expect(firstHighS, greaterThanOrEqualTo(50.0));
      expect(firstHighS, lessThanOrEqualTo(110.0));

      await engine.dispose();
    },
  );

  test('normal.json (with demo baseline) never exceeds monitoring', () async {
    final clock = FakeClock();
    final engine = PulseGuardEngine(
      clock: clock,
      bundle: _FileBundle(),
      alertEffects: _NoopAlertEffects(),
    );
    await engine.initialize();

    final levels = <RiskLevel>[];
    engine.risk.listen((r) => levels.add(r.level));

    await engine.startReplay(
      'assets/traces/normal.json',
      speed: 100,
      useDemoBaseline: true,
    );
    final summary = await engine.scanFinished.first;

    expect(summary.endReason, ScanEndReason.replayFinished);
    expect(levels, isNotEmpty);
    for (final l in levels) {
      expect(l.index, lessThanOrEqualTo(RiskLevel.monitoring.index));
    }

    await engine.dispose();
  });

  test(
    'signal_loss.json opens a check-in (multi_system or signal_loss) and never '
    'crashes on null vitals',
    () async {
      final clock = FakeClock();
      final engine = PulseGuardEngine(
        clock: clock,
        bundle: _FileBundle(),
        alertEffects: _NoopAlertEffects(),
      );
      await engine.initialize();

      final openedPayloads = <EscalationPayload>[];
      engine.alerts.listen((e) {
        if (e.kind == AlertEventKind.checkInOpened && e.payload != null) {
          openedPayloads.add(e.payload!);
        }
      });

      await engine.startReplay(
        'assets/traces/signal_loss.json',
        speed: 100,
        useDemoBaseline: true,
      );
      final summary = await engine.scanFinished.first;

      expect(summary.endReason, ScanEndReason.replayFinished);
      expect(openedPayloads, isNotEmpty);
      expect(
        openedPayloads.first.triggerType,
        anyOf(
          EscalationTriggerType.multiSystem,
          EscalationTriggerType.signalLoss,
        ),
      );

      await engine.dispose();
    },
  );
}
