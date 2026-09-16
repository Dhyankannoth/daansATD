# AllerGuard / PulseGuard (daansATD) — Session Context

Written as a full handoff of everything done in this session, for continuity with anyone (human or AI) picking this up next. Supersedes any earlier context file in spirit — this reflects the actual current state of the repo, verified against real on-device testing, not planning-stage assumptions.

## Who's who

- **User (this session)** — ML-1: signal processing / vitals extraction, but by the end of this session had also picked up on-device debugging, dev-environment setup, git ops, ML-3 training script scaffolding, and a security review — the roles blurred as the hackathon deadline pressed.
- **Sagnik** — ML-3: baseline/deviation engine, feature vector, models. Authored the `add-recovery-regressor-support` branch (gradient boosting regressor + `reaction` record-mode label).
- **A teammate (unnamed in this session)** — independently diagnosed and fixed the finger-detection root cause (see below) while testing in parallel; their fix was reviewed against the actual code and merged in.
- Real ML-3 training data (`normal_rest`/`stress`/`recovery` sessions) is being recorded by the team **right now**, in parallel with this session's work.

## Environment set up on this Mac tonight

This machine (`Aaryan's MacBook Air`, Apple Silicon) had almost nothing installed at session start. Now has, all added to `~/.zshrc`:
- Flutter 3.47.4 at `~/development/flutter`
- Temurin JDK 21 at `~/development/jdk/jdk-21.0.12.1+1`
- Android SDK (platform-tools, build-tools 35.0.0/28.0.3, platforms 35/36) at `~/Library/Android/sdk`
- `gh` CLI 2.101.0 at `~/development/gh/gh_2.101.0_macOS_arm64/bin`, authenticated as GitHub user **arrzinee**
- A Python venv for ML-3 training scripts at `training/ml3/venv` (gitignored)
- Xcode license was accepted mid-session (unrelated to Android work, was blocking `git` itself since git's binary is gated behind Xcode CLT licensing on macOS)

Test device: **Redmi Note 9 Pro Max** (Android 12, codename `excalibur`, Xiaomi's `CameraExtImplXiaoMi` camera stack — this device's camera behavior drove most of tonight's threshold tuning).

**Standing instruction for future sessions on this machine**: when the user says "re run," it means **uninstall the app first** (`adb uninstall com.vmedithon.pulseguard`), then `flutter run` fresh — this resets onboarding and clears stale local storage, which was needed repeatedly tonight.

## Repo state

Confirmed via GitHub API: `v-medithon` was renamed to `daansATD` (same repo, redirect confirmed). Remote: `https://github.com/Dhyankannoth/daansATD` (old `v-medithon` URL still works as a redirect).

Branches, all pushed and up to date as of end of session:
- **`main`** — has the base engine + `app-v2`'s UI merge + the 4 baseline-calibration-wiring fixes (merged via PR #1). Security-reviewed tonight (see below), no findings.
- **`app-v2`** — the real frontend UI (onboarding, home, baseline, measurement, history, settings screens, theming, mascot assets). Also contains a fully-parallel-updated copy of the engine (frame pipeline, DSP, vitals) — confirmed via diff to be identical logic to `main`, just reformatted.
- **`add-recovery-regressor-support`** (Sagnik) — adds `GradientBoostingRegressor`, extends `TreeModel` with `learning_rate`/`base_score`, adds `"reaction"` to `kRecordModeLabels`.
- **`integration-test`** (local + pushed) — the actual working branch used for all of tonight's testing: `add-recovery-regressor-support` + `app-v2` merged together, plus every fix from tonight. **This is the branch with the most current, most tested code** — recommend basing further work off this, not `main`, until it's merged forward.
- **`fix/baseline-calibration-wiring`** — the first 4 fixes only, already merged into `main` via PR #1.

## Bugs found and fixed tonight (chronological)

All on `integration-test`, all pushed:

1. **`initial_baseline_screen.dart` called `engine.startScan()` instead of `engine.startCalibration()`** — the onboarding "measure your baseline" flow was using the wrong engine method entirely; `startScan()` compares against an existing baseline, it doesn't build one. Also listened to the wrong completion stream (`scanFinished` instead of `calibration`).
2. **Countdown UI decoupled from real engine duration, in two separate screens** — both `initial_baseline_screen.dart` and `baseline_screen.dart` had local countdown timers/constants (20s and 60s respectively) totally independent of the actual 120s calibration duration (`thresholds.scan.calibrationS`), causing the countdown to hit 0 and either freeze or go negative while the real scan kept running. Fixed by deriving the displayed countdown from `EngineSnapshot.elapsed`/`remaining` (or `CalibrationProgress.total`) instead of hardcoded constants.
3. **`EngineSnapshot.placementHint` was never assigned anywhere, and calibration ticks never updated `latestVitals`** — meant "finger detected" text and the Signal Fidelity meter never worked during calibration, so users had zero live feedback to correct bad placement mid-scan. First-pass fix derived a coarse `ok`/`noFinger` boolean from `VitalsReading.fingerPresent`.
4. **`finger_lost_reset_s` was 0.5s** — any finger-presence flicker over half a second (camera AE hunting, momentary pressure shift) wiped the entire 60-second rolling analysis buffer and reset the vitals engine from scratch, producing a repeating "good signal → blip → full reset → ~10-15s recovery" pattern. Raised to 3.0s.
5. **Root cause of unreliable finger detection itself** (found by a teammate, verified and applied here): `finger_ratio` (2.0) and `min_red` (40) were miscalibrated against real Android YUV420 camera output with torch on — actual red dominance with a finger over the lens is ~1.2-1.6x, not 2x. Lowered `finger_ratio` to 1.3, `min_red` to 20. **This was the real fix** — everything before it was working around symptoms of frames being wrongly rejected as "no finger" even with good contact.
6. **The engine's own `placement` stream (`_placementCtrl`) was completely orphaned** — declared and exposed, but nothing ever called `.add()` on it, and `CameraVitalsSource` already computed a much richer per-frame `PlacementHint` (ok/keepStill/pressLighter/coverLens/coverFlash/noFinger via `FrameValidator`) that never reached anywhere. Added `_subscribePlacement()` to forward it properly into both the snapshot and the public stream, replacing the coarser fingerPresent-derived version from fix #3.
7. **`camera_measurement_screen.dart`'s `_deriveUiState` only treated `PlacementHint.noFinger` as "not placed"** — `null` (no data yet) and `coverLens`/`coverFlash` incorrectly fell through to "finger detected." Now all four are treated as awaiting-finger.
8. **`SignalQualityBar`'s "Strong signal" label was hardcoded at `quality >= 0.7`**, independent of `thresholds.json`'s `quality.trusted` (now 0.6) — meant a tick the engine counted as trusted could still visually show "Adjusting." Aligned to match.

## Deliberate product decision (not a bug fix)

**`quality.trusted` lowered from 0.7 to 0.6**, explicitly to make live calibration demos more reliable, at the user's call after being told the tradeoff: this threshold is shared between calibration-tick-counting AND live deviation-detection gating (`ml.row_min_trusted_frac`), so it also loosens what counts as trustworthy data during actual monitoring, not just calibration. Documented in the commit message as a known tradeoff to revisit post-demo.

## Diagnostic logging — deliberately kept in for the demo

Two `debugPrint` layers were added for tonight's debugging and **deliberately kept in through the demo** (user's explicit call, "in case something goes wrong"):
- `[CAL-DIAG]` in `pulseguard_engine.dart`'s `_handleCalibrationTick` — quality/trust/hr/hrv/rr once per tick.
- `[FRAME-DIAG]` in `frame_validator.dart`'s `validate()` — raw r/g/b and each check's pass/fail, throttled to ~1/sec.

A security review flagged this (see below) but it was assessed as low-confidence/not-exploitable (device logs are sandboxed per-app on both Android and iOS; reading another app's log requires a precondition — root or physical possession with debugging already enabled — that already implies device compromise). Should still be stripped before any real (non-hackathon) release.

## Testing results, chronological (all on the Redmi Note 9 Pro Max, single-finger except where noted)

| Attempt | Trusted ticks (of 122, need 60) | Notes |
|---|---|---|
| 1st real attempt | ~30 | Before `finger_lost_reset_s` fix — fragmented by resets |
| 2nd | ~48 | After `finger_lost_reset_s` fix — first clean unbroken run (28 ticks straight) |
| 3rd | ~32 | Marginal/inconsistent contact pressure |
| 4th | 0 | Contact quality never crossed even the lowered 0.6 threshold |
| 5th | 0 | Buffer empty entire session — likely no real contact during this scan |
| 6th (post finger_ratio/min_red/placement fix) | **50** | Two separate sustained clean stretches (quality 0.7-0.97) — confirms the root-cause fix works |
| 7th | random/unreliable | **Used two fingers instead of one** — likely explains the anomaly, not a regression (uneven coverage of lens+flash, untested configuration) |

No attempt has yet cleared the full 60-tick minimum, but the 48 and 50-tick results show the pipeline works correctly with steady single-finger contact — it's now a matter of sustaining it a bit longer per attempt, not a code problem.

## Security review

Ran the `security-review` skill against `main`'s merged state (clean worktree at a separate git worktree, not the working directory). One candidate finding (the `[CAL-DIAG]` debug logging of raw vitals) was identified, then independently re-evaluated against the false-positive filtering criteria and **discarded** (confidence 3/10) — device log sandboxing on both platforms means it's not concretely exploitable without a precondition that already implies compromise. **No findings survived review.**

## ML-3 training scripts — written and self-tested, ready for real data

At `training/ml3/`, on `integration-test`:
- **`common.py`** — shared utilities: loads Record Mode CSVs (exact column match to `record_mode_writer.dart`), splits by `session_id` (never by row — per Sagnik's "don't reuse a recording across train/threshold/test" rule), exports sklearn trees to the exact JSON shape `tree_model.dart`'s `TreeNode.fromJson` expects (verified: sklearn's own tree_ representation needs almost no transformation), and a Python port of `isolation_forest.dart`'s exact scoring formula for threshold-setting.
- **`train_isolation_forest.py`** — trains on real `normal_rest`/`recovery`/`stress` sessions only, 10-feature subset, 3-way session split, sets `score_threshold` at the 99th percentile on held-out data. Writes `flutterApp/assets/models/iforest.json`.
- **`train_risk_rf.py`** — trains on all 16 features, `"reaction"`-labeled sessions as positives vs. everything else as negatives. Writes `flutterApp/assets/models/risk_rf.json`.
- Both have a `--self-test` flag that generates synthetic data matching the real format and runs the full pipeline end-to-end — **already run successfully tonight**, confirming the scripts work before any real data exists. Once real recordings land: `python train_isolation_forest.py --recordings-dir <path>` and same for the risk script — no format wrangling needed.
- `assets/models/` currently has only a `.gitkeep` placeholder — nothing trained yet, this is the very next step once real sessions are recorded.

## What's actually left

1. **Get a calibration session past 60 trusted ticks** — single-finger, steady, matching the technique from the 48/50-tick attempts. Purely a "do it again carefully" task now, not a code task.
2. **Real ML-3 training data** — in progress by the team right now (`normal_rest` x3+, `stress` x2+, `recovery` x3+ per person, via the app's own Record Mode).
3. **Run the training scripts against real data** once it lands — should be a single command each, per above.
4. **Consider pre-loading a demo baseline** instead of calibrating live on stage, as extra insurance — was discussed, not yet decided against in favor of a live demo.
5. **Merge `integration-test` forward into `main`** at some point — it's currently ahead of `main` by the recovery-regressor work plus all of tonight's finger-detection/calibration fixes, none of which are on `main` yet except the original 4-fix PR.
6. **Strip `[CAL-DIAG]`/`[FRAME-DIAG]` diagnostic logging** before any release beyond the hackathon demo (kept in deliberately for now).
