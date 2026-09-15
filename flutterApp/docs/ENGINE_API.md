# PulseGuard Engine — Integration Guide

This is the integration guide for the UI developer. The engine (`lib/engine/`)
is a self-contained logic layer with one public entry point:

```dart
import 'package:pulseguard/pulseguard_engine.dart';

final engine = PulseGuardEngine();
await engine.initialize();
```

Everything you need — models, enums, the `PulseGuardApi` interface, and
`PulseGuardEngine` itself — is exported from `lib/pulseguard_engine.dart`.
Don't import anything under `lib/engine/` directly.

The engine has no dependency on `provider` or any state-management package.
Wrap it in whatever you use (Riverpod, Bloc, plain `setState` +
`ValueListenableBuilder`) — it only exposes plain `Stream`s and one
`ValueListenable<EngineSnapshot>`.

## Quick start

```dart
class MyScreen extends StatefulWidget { ... }

class _MyScreenState extends State<MyScreen> {
  final engine = PulseGuardEngine();

  @override
  void initState() {
    super.initState();
    engine.initialize();
  }

  @override
  void dispose() {
    engine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<EngineSnapshot>(
      valueListenable: engine.snapshot,
      builder: (context, snapshot, _) {
        // snapshot.phase, snapshot.risk, snapshot.latestVitals, ...
        if (snapshot.phase == EnginePhase.scanning && engine.cameraController != null) {
          return CameraPreview(engine.cameraController!);
        }
        return Text(snapshot.message);
      },
    );
  }
}
```

## `EnginePhase`

| Phase | Meaning |
|---|---|
| `uninitialized` | Before `initialize()` completes. |
| `idle` | Ready; no scan/calibration/replay running. |
| `preparingCamera` | Camera is starting up. |
| `settling` | (Reserved for the camera pipeline's exposure-lock settle window.) |
| `scanning` | A live camera scan is running. |
| `calibrating` | A calibration scan is running. |
| `replaying` | A replay trace is streaming. |
| `finished` | A scan/calibration just ended; `scanFinished`/`calibration` carries the result. |
| `error` | Something failed (e.g. camera permission denied); `snapshot.error` has the message. |

## Streams and the snapshot

- `snapshot` (`ValueListenable<EngineSnapshot>`) — always-current summary; the
  cheapest way to drive most of the UI.
- `vitals` — one `VitalsReading` per second while scanning/replaying.
- `waveform` — ~30 Hz pulse trace samples for a live waveform widget.
  `simulated: true` during replay.
- `placement` — debounced `PlacementHint` (camera scans only); use
  `hint.message` for the on-screen instruction text.
- `activity` — current `ActivityState` (resting/recovering/exercising/unknown).
- `risk` — one `RiskAssessment` per second; `level` drives the risk UI,
  `statusText` and `reasons` are ready-to-display copy.
- `alerts` — check-in/escalation state machine transitions
  (`AlertEvent.kind`: `checkInOpened`, `checkInTick`, `resolved`, `escalated`,
  `cooldownStarted`, `cooldownEnded`).
- `scanFinished` — one `ScanSummary` per completed/aborted scan.
- `calibration` — `CalibrationProgress` updates during `startCalibration()`.

## Risk levels and quality bands

`RiskLevel` is `normal < monitoring < elevated < high < critical`. ML
(pattern-model) signals alone can reach `elevated` but never `high` — `high`
always requires a rule-based trigger (persistent multi-system deviation,
signal-loss watchdog) or a sustained ML risk score *combined with* a
persistent system.

Every vitals value has a trust band, driven by `VitalsReading.quality` (and
`rrQuality` for RR):

| Band | Condition | Show it? | Feed the risk engine? |
|---|---|---|---|
| trusted | `quality >= 0.7` (RR: `min(quality, rrQuality) >= 0.7`) | yes | yes |
| display-only | value present but `quality < 0.7` | yes, dim it | no |
| hidden | value is `null` | no | no |

A `null` field on `VitalsReading` always means "not derivable this tick" —
never render it as 0 or repeat the last value.

## SpO2 / oxTrend labelling

`spo2` and `oxTrend` are **display-only and experimental** — never treat them
as clinically meaningful, and never gate any UI warning on them alone.

- `spo2` is `null` unless a per-device calibration file
  (`assets/config/spo2_calibration.json`) is present; most builds will never
  populate it. Label it "experimental" wherever shown.
- `oxTrend` is a % change in the red/green absorption ratio versus the start
  of the current scan; it is `null` for the first ~10 s of a scan while the
  reference is establishing. A **positive** value means the ratio increased,
  which is *expected* to accompany lower oxygenation but is **unvalidated** —
  don't word it as "oxygen dropped."

## Wording rules

No engine-produced string ever says "anaphylaxis detected," "diagnosis," or
implies clinical accuracy. All user-facing copy lives in
`lib/engine/api/engine_strings.dart` — reword freely there; the rest of the
engine references it by name.

## Scan → check-in → escalation sequence

```
startScan() ──▶ preparingCamera ──▶ scanning ──(1 Hz ticks: vitals/activity/risk)──▶
                                                          │
                                     risk.level == high, no open check-in
                                                          ▼
                                          alerts: checkInOpened (30 s countdown)
                                                          │
                        ┌─────────────────────────────────┼─────────────────────────┐
                        ▼                                 ▼                         ▼
              respondCheckIn(ok: true)          respondCheckIn(ok: false)      timeout (30 s)
                        │                                 │                         │
                        ▼                                 ▼                         ▼
              alerts: resolved (userOk)          alerts: escalated            alerts: escalated
                        │                                 │                         │
                        └─────────────────┬───────────────┴─────────────────────────┘
                                          ▼
                          cooldown (180 s) — alerts: cooldownStarted → cooldownEnded
```

`endScan()` always returns a `ScanSummary`. If a check-in was open and
unanswered, ending the scan resolves it as `escalated`. During cooldown, a
new `high` tick does **not** reopen a check-in, but risk levels are still
computed and shown.

Escalation is always simulated — the engine never sends an SMS, makes a
call, or hits the network. `EscalationPayload.contact.method` is always
`"simulated"`.

## Replay (demo insurance)

```dart
await engine.startReplay('assets/traces/reaction.json', speed: 1.0);
```

Available traces: `normal.json`, `reaction.json`, `signal_loss.json`
(all under `assets/traces/`). `useDemoBaseline: true` (default) loads
`assets/demo/baseline.json` for the duration of the replay without touching
the user's real stored baseline. `cameraController` is `null` during replay;
the waveform is a synthetic pulse shape (`WaveformSample.simulated == true`).
Record mode is disabled during replay.

## Debug page

`lib/engine/debug/engine_debug_page.dart` is a plain-text harness — buttons
for Start scan / End scan / Calibrate / Replay reaction / I'm fine / I need
help, plus a live snapshot dump. It is **not** product UI; to try it, push it
temporarily instead of your real screen, e.g. in `main.dart` during
development:

```dart
runApp(MaterialApp(home: EngineDebugPage(engine: PulseGuardEngine())));
```

Do not wire it into the shipped `main.dart`.

## Known simplifications (see the final deliverables summary for the full list)

- `CameraVitalsSource` (real camera → vitals pipeline) has not been
  exercised on a physical device in this environment — verify per the
  on-device checklist before relying on it for a demo.
- Record mode only writes rows during live camera scans, not calibration.
- The activity-classifier ML model isn't yet wired into the camera source
  (falls back to the threshold-based motion classifier, which is fully
  implemented and tested).
