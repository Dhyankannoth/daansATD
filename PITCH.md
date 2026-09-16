# AllerGuard (PulseGuard) — Pitch & Demo Script

*VMedithon 3.0 — Team Hack Daniels*

---

## The problem

Anaphylaxis kills fast, and the thing that kills people isn't lack of awareness — it's **delay**. Someone having an early reaction usually notices *something*, and hesitates anyway. As blood pressure drops, they get dizzy, confused, or lose consciousness — exactly when they can no longer call for help or use their own epi-pen.

We built for the hardest version of this problem: **a solo athlete mid-workout.** Exercise already produces a racing heart, sweating, and flushing — the exact same signs as early anaphylaxis. Someone in that situation is primed to dismiss real symptoms as "just exertion," and there's often nobody around to notice for them.

## Our approach

**AllerGuard turns a phone's existing camera into a passive vitals monitor and compares what it sees against *your own* body's normal — not a population average.** No wearable, no extra hardware. Cover the rear camera and flash with a finger, and the phone extracts heart rate, heart rate variability, and respiration rate from the pulse signal in real time.

The core insight: a fixed threshold ("HR > 120 = alert") is useless for a runner whose resting HR is 50 and whose exercising HR is 160. What matters is *deviation from what's normal for this specific person, in this specific activity state.* That's the entire architecture.

## How it works — five stages

```
Camera PPG → Vitals extraction → Activity-state gate → Personal-baseline
deviation → Multi-system fusion (rule-based) → Check-in → Escalation
```

1. **Signal processing** — classical DSP, not ML. Bandpass filtering + beat detection on the raw pixel signal extracts HR, HRV (RMSSD), and respiration rate once per second, with a live quality/trust score so noisy data never gets treated as real.
2. **Activity awareness** — accelerometer-based classifier distinguishes resting from active, so the right baseline gets applied.
3. **Personal baseline + anomaly detection** — a guided 2.5-minute calibration scan learns *your* resting mean and spread for HR/HRV/RR. Live readings are converted to z-scores against that personal baseline — the same physiological principle behind GA²LEN's clinical anaphylaxis criteria, automated from a sensor stream instead of a clinician's observation. An **Isolation Forest** flags physiologically unusual combinations; a **Random Forest risk classifier** gives a secondary corroborating "how reaction-like is this pattern" score.
4. **Recovery modeling** — we also trained a **gradient-boosting regressor that predicts expected recovery time** from a personal baseline trajectory, so the system understands not just "is this deviating" but "is this recovering on a normal timeline" — the same personalization principle applied to the recovery phase, not just the onset phase.
5. **Rule-based fusion, deliberately not ML** — requiring 2+ organ systems (cardiovascular, respiratory, autonomic) to deviate together, sustained over time, not a single noisy blip. This mirrors GA²LEN's actual clinical "2+ systems" criterion, and it's rule-based on purpose: when a system might escalate to contacting someone's emergency contact, "why did it fire" needs to be inspectable, not a black box.
6. **Check-in before escalation** — the system asks "are you okay?" first, with a visible countdown. Only silence triggers escalation to a named emergency contact. This is the actual safety mechanism: cutting through hesitation, not diagnosing.

## What's actually built and working tonight

- Full camera-PPG signal pipeline: ROI extraction, frame-quality gating, bandpass filtering, beat detection, HR/HRV/RR computation — running live on-device, validated against real finger-over-camera testing (not just simulation).
- A real, guided personal-baseline calibration flow (2.5 minutes), producing per-user mean/SD baselines that the rest of the system reads from.
- All three trained models loaded and verified live in the app: Isolation Forest anomaly detector, Random Forest risk classifier, and the recovery-time regressor — each independently confirmed to load and score correctly against real feature vectors.
- The full 5-level rule-based fusion engine, check-in modal with countdown, and escalation screen (simulated contact notification for demo safety).
- End-to-end pipeline integrity confirmed via automated replay testing — synthetic vitals traces run through the exact same code path as live camera data, with no special-casing.

## What we're honest about

We built this to be defensible under scrutiny, not just impressive on stage:

- **The models are trained on synthetic data, not real recordings.** There is no public labeled anaphylaxis dataset anywhere — that's not a gap specific to us, it's a gap in the entire field. We generated realistic synthetic physiological trajectories and replayed them through our *actual* feature-computation code (not a separate approximation), so the training data has the right shape even though it's not from real biology. Real on-device recordings are the next step, not a hypothetical one — we built the recording pipeline and training scripts to make that swap a one-command operation once that data exists.
- **Camera-only sensing covers 3 of the 4 organ systems** GA²LEN's clinical criteria use (cardiovascular, respiratory, autonomic) — there's no camera-based proxy for skin/mucosal signs like flushing or hives.
- **Non-exercise arousal (fear, stress, a jump-scare) can look like early anaphylaxis to a sensor** — same HR-up/HRV-down signature. We don't pretend the classifier alone solves this. The check-in step is what actually catches it: a false alarm gets dismissed by a person who's fine, not silently escalated.
- **Camera PPG is device-dependent.** Signal quality varies by phone, lighting, and finger placement technique — we tuned thresholds against real on-device testing rather than assuming defaults would work everywhere.

## Demo flow (suggested)

1. **Show the calibration** — open the app, start the 2.5-minute personal baseline scan, point out the live waveform and signal-quality meter (this isn't a black box — you can see the actual pulse signal being extracted).
2. **Show a live scan** — place a finger, walk through the real-time HR/HRV/RR readout and the activity-state indicator.
3. **Trigger a reaction scenario** — replay a synthetic reaction trace through the same live pipeline (no special-casing, it's the identical code path), and show the risk level escalating through the fusion engine as multiple systems start deviating together.
4. **Show the check-in** — let the countdown run out (or tap "I need help") to reach the escalation screen, and point out the plain-language explanation of *why* it fired (which systems deviated, by how much) — this is the explainability payoff.
5. **Close on the honesty section** — briefly state the synthetic-data and camera-limitation caveats unprompted. It reads as rigor, not weakness, and heads off the obvious judge question before it's asked.

## The pitch, in one line

**Most anaphylaxis tools wait for someone to already know something's wrong and act on it. AllerGuard watches continuously, compares against your own body instead of a population average, and escalates on your behalf the moment you can't answer for yourself — using hardware everyone already has in their pocket.**
