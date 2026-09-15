# PulseGuard — Mobile UI/UX Design Specification & Architecture

> **Document Version:** 1.0.0  
> **Status:** Approved Architectural Specification  
> **Author:** Lead Product Designer & UX Architect  
> **Target Framework:** Flutter 3.x / Dart 3.x (Material 3 Adaptive Design)  
> **Authoritative Baseline:** `docs/skills.md`  
> **Engine Integration:** `flutterApp/lib/pulseguard_engine.dart` (`PulseGuardApi`)

---

## Table of Contents

1. [Executive Summary & Product Purpose](#1-executive-summary--product-purpose)
2. [Conflict Identification & Authority Hierarchy](#2-conflict-identification--authority-hierarchy)
3. [Design Principles & Core Philosophy](#3-design-principles--core-philosophy)
4. [Color System (60/30/10 Rule & Semantic Risk Tokens)](#4-color-system-603010-rule--semantic-risk-tokens)
5. [Typography System](#5-typography-system)
6. [Spacing & Layout (8-Point Grid & Thumb Zone)](#6-spacing--layout-8-point-grid--thumb-zone)
7. [Reusable Component System](#7-reusable-component-system)
8. [Component State Matrix](#8-component-state-matrix)
9. [Information Architecture & Navigation](#9-information-architecture--navigation)
10. [Detailed Screen Specifications](#10-detailed-screen-specifications)
    * 10.1 Screen A: Initial Setup / Minimal Onboarding
    * 10.2 Screen B: Home / Monitoring Screen
    * 10.3 Screen C: Camera Measurement Screen & Native Animation
    * 10.4 Screen D: Measurement States & Signal Feedback
    * 10.5 Screen E: Results & Personal Baseline Comparison Screen
    * 10.6 Screen F: Early Warning & Check-In Dialog State
    * 10.7 Screen G: Escalation Screen (Emergency State)
    * 10.8 Screen H: Unresponsive User Countdown State
    * 10.9 Screen I: History & Trends Screen
    * 10.10 Screen J: Baseline & Calibration Screen
    * 10.11 Screen K: Emergency Contacts Screen
    * 10.12 Screen L: Settings & Clinical Disclaimer Screen
    * 10.13 Screen M: Wearable / Health Data Fallback Concept
11. [User State & Context Transitions](#11-user-state--context-transitions)
12. [Empty, Loading, and Error State Specifications](#12-empty-loading-and-error-state-specifications)
13. [Animation & Motion Guidelines](#13-animation--motion-guidelines)
14. [Accessibility & Outdoor Readability Rules](#14-accessibility--outdoor-readability-rules)
15. [Screen-by-Screen Implementation Checklist](#15-screen-by-screen-implementation-checklist)

---

## 1. Executive Summary & Product Purpose

### 1.1 Non-Diagnostic Early-Warning Role
PulseGuard is an early-warning physiological monitoring mobile application designed to detect multi-system physiological deviations from a user's personal baseline. It is **NOT** a diagnostic medical device and does **NOT** diagnose anaphylaxis or any other clinical condition.

### 1.2 Mandatory Language Constraints
The user interface, copy, error banners, notifications, and alerts must **NEVER** communicate:
* ❌ `"You have anaphylaxis"`
* ❌ `"Anaphylaxis detected"`
* ❌ `"Clinical diagnosis confirmed"`
* ❌ Any guaranteed medical prediction or guaranteed emergency dispatch

Instead, all user-facing language adheres strictly to the approved terminology dictionary:
* ✅ `"Possible physiological abnormality detected"`
* ✅ `"Your readings have changed significantly compared to your personal baseline"`
* ✅ `"We noticed changes across multiple vital signals"`
* ✅ `"Please check how you're feeling"`
* ✅ `"Consider using your prescribed emergency medication if instructed by your healthcare professional"`
* ✅ `"Consider seeking immediate emergency medical help if you are experiencing symptoms"`

### 1.3 Target Persona: Solo Outdoor Athlete
* **Context**: Running, cycling, hiking, or resting outdoors; potentially wearing sunglasses; screen viewed under direct bright sunlight.
* **Cognitive State**: Heart rate elevated from exercise, sweat, fatigue, high adrenaline, reduced fine-motor coordination, potential early allergic symptoms (dizziness, nausea, airway constriction, disorientation).
* **UX Imperatives**: Minimal cognitive load, high contrast (WCAG AAA), thumb-zone tap targets (minimum 48×48 dp), concise sentences, zero dashboard clutter during risk states.

---

## 2. Conflict Identification & Authority Hierarchy

In accordance with project governance rules, all project documents have been cross-referenced against `docs/skills.md`:

| Topic | `docs/skills.md` Guideline | Codebase / Platform Reality | Resolution & Authority |
|---|---|---|---|
| **Tech Stack** | Mentions React artifacts, Tailwind CSS classes (`rounded-2xl`, `backdrop-blur`), Lucide icons, Recharts | The project is a pure **Flutter (Dart 3.x)** mobile application (`flutterApp/` with `MaterialApp`, `ThemeData`, `PulseGuardEngine`) | **Flutter Native Rule**: The Flutter architecture and Material 3 design system supersede React/Tailwind syntax. Visual design rules (spacing, 60/30/10 colors, typography hierarchy, soft shadows) are implemented 1:1 via Flutter `ThemeData`, `TextStyle`, and custom Canvas/Widgets. |
| **Measurement Duration** | Instructional animation duration in `camera_finger_instruction.dart` loops every 4 seconds | PulseGuard PPG optical pipeline requires **15–20 seconds** of continuous recording for reliable HR/HRV/RR derivation | **Accurate Duration Rule**: The animation loop communicates *placement*, but the measurement progress bar and countdown explicit counter show **15–20 seconds**. The UI never tricks the user into thinking a 3-second scan suffices. |
| **Finger Asset** | `camera_finger_instruction.dart` referenced `assets/animations/finger.png` | Requirements explicitly mandate using `assets/animations/finger_2.png` and `assets/animations/phone.png` | **Asset Spec Rule**: Update asset reference to `finger_2.png` with correct anchor coordinates for camera module alignment. |
| **Smartwatch Flow** | Smartwatch connectivity is a future `VitalsSource` | Avoids cluttering onboarding with wearable pairing modals | **Passive Fallback Rule**: Follow `ENGINE_API.md`: if wearable data stream is present, use it; otherwise seamlessly fall back to Camera PPG without forcing user selection modals. |

---

## 3. Design Principles & Core Philosophy

1. **Clarity Over Novelty (The Calm Clinical Aesthetic)**
   The interface exudes the precision of modern medical technology (such as Apple Health, Philips Health, or Withings) combined with the approachable clarity of top consumer apps (Revolut, Airbnb). It avoids neon cyberpunk styling, dark glassmorphism gimmicks, and cartoonish illustrations.
2. **Personal Baseline Over Generic Norms**
   Population thresholds (e.g., "HR > 100 is tachycardia") cause dangerous false alarms during exercise. Every alert and status gauge anchors to the user’s learned personal resting and exercise baseline distributions ($\mu \pm 2\sigma$).
3. **The Human-in-the-Loop Confirmation Gate**
   Sensor deviation triggers a **Check-In**, never a panic siren. The user is asked `"Are you feeling okay?"` with immediate one-touch responses: `[ I'M OKAY ]` or `[ I'M NOT FEELING WELL ]`.
4. **Peak-End Rule & Calming Resolution**
   * **Peak Moment**: Fast, frictionless check-in response and rapid emergency call trigger without navigating nested menus.
   * **End Moment**: Calming green reassurance card with summary and cooldown timeline indicator once safe.
5. **Fail-Safe Fallback (Watchdog Escalation)**
   If multi-system deviations persist and the user does not respond within 30 seconds, the application initiates an automated emergency escalation sequence.

---

## 4. Color System (60/30/10 Rule & Semantic Risk Tokens)

Adhering strictly to the **60/30/10 rule** from `docs/skills.md`:
* **60% Neutral Base**: Pure white (`#FFFFFF`) and crisp slate-gray surfaces (`#F8FAFC`, `#F1F5F9`) provide high contrast and optical clarity outdoors.
* **30% Structural Elements**: Deep Slate Navy (`#0F172A`, `#1E293B`) for headings, primary typography, borders, and dark structural cards.
* **10% Semantic Accents**: Targeted clinical accent colors reserved strictly for functional indicators and primary CTAs.

### 4.1 Core Semantic Tokens

```dart
class PulseColors {
  // 60% - Neutral Base & Surfaces
  static const Color background = Color(0xFFF8FAFC);       // Slate 50
  static const Color surface = Color(0xFFFFFFFF);          // Pure White
  static const Color surfaceElevated = Color(0xFFFFFFFF);  // Elevated Cards
  static const Color surfaceDim = Color(0xFFF1F5F9);       // Slate 100 (subtle wells)
  
  // 30% - Typography & Structure
  static const Color textPrimary = Color(0xFF0F172A);      // Slate 900 (100% opacity)
  static const Color textSecondary = Color(0xFF475569);    // Slate 600 (80% opacity)
  static const Color textTertiary = Color(0xFF94A3B8);     // Slate 400 (60% opacity)
  static const Color divider = Color(0xFFE2E8F0);          // Slate 200
  static const Color borderSubtle = Color(0xFFCBD5E1);     // Slate 300
  
  // 10% - Brand & Primary Action
  static const Color primary = Color(0xFF0284C7);          // Sky 600 (Clinical Blue)
  static const Color primaryDark = Color(0xFF0369A1);      // Sky 700 (Pressed state)
  static const Color primaryLight = Color(0xFFE0F2FE);     // Sky 100 (5% - 10% tint)
  
  // Semantic Risk Levels (Strictly Aligned with RiskLevel Enum)
  static const Color riskNormal = Color(0xFF10B981);       // Emerald 500 (Calm / In-range)
  static const Color riskNormalBg = Color(0xFFECFDF5);     // Emerald 50
  static const Color riskMonitoring = Color(0xFF0EA5E9);   // Sky 500 (Monitoring / Active)
  static const Color riskMonitoringBg = Color(0xFFF0F9FF); // Sky 50
  static const Color riskElevated = Color(0xFFF59E0B);     // Amber 500 (Attention / Exercise recovery)
  static const Color riskElevatedBg = Color(0xFFFFFBEB);   // Amber 50
  static const Color riskHigh = Color(0xFFF97316);         // Orange 500 (Concerning multi-system deviation)
  static const Color riskHighBg = Color(0xFFFFF7ED);       // Orange 50
  static const Color riskCritical = Color(0xFFEF4444);     // Red 500 (Immediate action required)
  static const Color riskCriticalBg = Color(0xFFFEF2F2);   // Red 50
  
  // Emergency CTA Tone
  static const Color emergencyRed = Color(0xFFDC2626);     // Red 600
  static const Color emergencyRedPressed = Color(0xFFB91C1C); // Red 700
}
```

### 4.2 Shadow System
* **Soft Card Shadow**: `BoxShadow(color: Color(0x0A0F172A), blurRadius: 16, offset: Offset(0, 4))`
* **Elevated Modal Shadow**: `BoxShadow(color: Color(0x140F172A), blurRadius: 24, offset: Offset(0, 8))`
* **Emergency Pulse Shadow**: `BoxShadow(color: Color(0x33DC2626), blurRadius: 20, spreadRadius: 2)`

---

## 5. Typography System

* **Font Family**: Modern, accessible sans-serif system: `Inter` or `Roboto` with fallback to `SF Pro Text` / `Segoe UI`.
* **Metric Figures**: Monospace or tabular figures (`FontFeature.tabularFigures()`) for heart rate, HRV, SpO2, and respiratory rate to prevent layout jitter during 1 Hz stream updates.
* **Hierarchy Budget**: Maximum 4 sizes and 2 font weights (`FontWeight.w400` Regular and `FontWeight.w600` Semi-Bold) in main screens to ensure high legibility outdoors.

| Token | Size (sp) | Weight | Line Height | Tracking | Purpose |
|---|---|---|---|---|---|
| `displayMetric` | 44 | w600 (Semi-Bold) | 48 dp | -1.0 | Primary vitals value (e.g., `82`) with Tabular Figures |
| `displayUnit` | 16 | w400 (Regular) | 20 dp | 0.0 | Unit label next to metric (e.g., `BPM`, `ms`, `%`) |
| `headingLarge` | 24 | w600 (Semi-Bold) | 30 dp | -0.5 | Screen titles, Emergency headers, Modal titles |
| `headingMedium`| 18 | w600 (Semi-Bold) | 24 dp | -0.2 | Card section headers, Dialog headings |
| `bodyRegular`  | 15 | w400 (Regular) | 22 dp | 0.0 | Descriptive instructions, baseline explanations |
| `bodyMedium`   | 15 | w600 (Semi-Bold) | 22 dp | 0.0 | List highlights, key action copy |
| `caption`      | 12 | w400 (Regular) | 16 dp | +0.2 | Timestamps, signal quality badges, disclaimer text |
| `button`       | 16 | w600 (Semi-Bold) | 20 dp | +0.1 | Primary, secondary, and emergency button labels |

---

## 6. Spacing & Layout (8-Point Grid & Thumb Zone)

### 6.1 8-Point Grid Standard
All spatial relationships use the 8-point multiplier ($4, 8, 12, 16, 24, 32, 48, 64$ dp):
* Micro-spacing (icon to label): `8 dp`
* Inner-card item padding: `12 dp` to `16 dp`
* Outer-card padding: `20 dp` to `24 dp`
* Screen horizontal gutter: `20 dp` (standard) or `16 dp` (compact screens)
* Section separation: `24 dp` to `32 dp`
* Touch target minimum: `48 dp × 48 dp` (exceeds 44 pt requirement)

### 6.2 The Thumb Zone Law
Critical actions are situated strictly within the bottom third of the viewport:
* **Primary Spot Measurement FAB / CTA**: Docked at bottom with `SafeArea`.
* **Check-In Response Buttons**: Dual stacked/horizontal full-width buttons pinned at the bottom.
* **Emergency Dispatch Trigger**: Large full-width button at the screen base.

---

## 7. Reusable Component System

Every component is defined with strict typed properties and zero hardcoded magic numbers.

```
lib/
├── ui/
│   ├── theme/
│   │   ├── pulse_colors.dart
│   │   ├── pulse_typography.dart
│   │   └── pulse_theme.dart
│   ├── components/
│   │   ├── buttons/
│   │   │   ├── primary_button.dart
│   │   │   ├── secondary_button.dart
│   │   │   └── emergency_button.dart
│   │   ├── cards/
│   │   │   ├── metric_card.dart
│   │   │   ├── vital_metric_tile.dart
│   │   │   ├── status_card.dart
│   │   │   ├── information_card.dart
│   │   │   ├── warning_card.dart
│   │   │   └── emergency_contact_card.dart
│   │   ├── indicators/
│   │   │   ├── status_indicator.dart
│   │   │   ├── risk_badge.dart
│   │   │   ├── signal_quality_bar.dart
│   │   │   └── countdown_ring.dart
│   │   ├── feedback/
│   │   │   ├── live_waveform_painter.dart
│   │   │   ├── camera_instruction_widget.dart
│   │   │   └── check_in_sheet.dart
│   │   └── layout/
│   │       ├── pulse_app_bar.dart
│   │       └── pulse_bottom_nav.dart
```

### 7.1 Component Inventory & Contract Specifications

#### `PrimaryButton`
* **Purpose**: Single primary action on any standard screen (e.g., "Start Spot Measurement", "Save Contact").
* **Properties**: `label`, `icon`, `onPressed`, `isLoading`, `fullWidth: true`.
* **Aesthetics**: Height 52 dp, radius 16 dp, `PulseColors.primary` background, white text, subtle elevation.

#### `SecondaryButton`
* **Purpose**: Non-destructive auxiliary actions (e.g., "View Trends", "Calibrate Baseline").
* **Properties**: `label`, `icon`, `onPressed`, `outlined: true`.
* **Aesthetics**: Height 52 dp, radius 16 dp, white surface with `PulseColors.divider` border, `PulseColors.textPrimary` text.

#### `EmergencyButton`
* **Purpose**: High-urgency physical trigger on escalation screen ("Call Emergency Services", "I'm Not Feeling Well").
* **Properties**: `label`, `subtitle`, `icon`, `onPressed`, `isCritical: true`.
* **Aesthetics**: Height 64 dp, radius 18 dp, `PulseColors.emergencyRed` background, white high-contrast text, 20 dp icon, subtle glowing red drop shadow.

#### `MetricCard` & `VitalMetric`
* **Purpose**: Display live or median HR, HRV, SpO2, and RR.
* **Layout**:
  * Top: Metric Title (e.g., "HEART RATE") + Baseline Range Indicator badge ("Within range" / "+18 BPM above baseline").
  * Middle: Large tabular numeric value (`displayMetric`, e.g., `82`) + Unit (`BPM`).
  * Bottom: Quality Trust Indicator (e.g., Green dot for "Trusted", Dim amber for "Low signal - adjusting").
  * SpO2 Note: Displays an explicit `"Experimental"` badge per `ENGINE_API.md`.

#### `StatusIndicator` & `RiskBadge`
* **Purpose**: Triple-encoded visual display of current system risk (Icon + Text + Background Color).
* **States**:
  * `normal`: Checkmark icon, "Normal", Emerald Green.
  * `monitoring`: Activity pulse icon, "Monitoring", Sky Blue.
  * `elevated`: Info icon, "Elevated (Recovery)", Amber Orange.
  * `high`: Alert triangle icon, "Check Needed", Deep Orange.
  * `critical`: Warning shield icon, "Attention Required", Red.

#### `CameraInstructionWidget`
* **Purpose**: Native Flutter vector/asset animation orchestrating `phone.png` and `finger_2.png`.
* **Behavior**: Displays the finger moving from bottom into proper position over lens/flash, holding with subtle pulse glow, backed by step-by-step guidance.

#### `LiveWaveformPainter`
* **Purpose**: CustomPainter rendering real-time PPG waveform samples (~30 Hz) streaming from `PulseGuardEngine.waveform`.
* **Aesthetics**: Emerald green or Sky blue continuous bezier path over dark slate or subtle shaded background with gradient trailing fade.

#### `CheckInSheet` / `CheckInDialog`
* **Purpose**: Non-dismissible bottom modal triggered on `AlertEventKind.checkInOpened`.
* **Content**:
  * Title: "Are you feeling okay?"
  * Subtitle: "We noticed unusual changes across multiple vital signals compared to your normal baseline."
  * 30-second visual countdown circular progress bar.
  * Two prominent full-width action buttons: `[ YES, I'M OKAY ]` and `[ I'M NOT FEELING WELL ]`.

---

## 8. Component State Matrix

| Component | Default / Normal | Pressed / Active | Disabled | Warning / Alert | Loading / Transition |
|---|---|---|---|---|---|
| **PrimaryButton** | Blue 600, White text, 0 shadow | Blue 700, Scale 0.98 | Slate 200, Slate 400 text | Amber 500 (if cautionary) | Spinner replaces label |
| **EmergencyButton**| Red 600, White text, soft shadow | Red 700, Scale 0.98 | Slate 300, Slate 500 text | Red 600 pulsing shadow | Spinner on initiating call |
| **MetricCard** | White surface, Slate 200 border | Slight shadow elevation | Opacity 0.45, "—" placeholder| Orange 50 bg, Orange 500 badge | Skeleton shimmer on connect |
| **CheckInTimer** | Ring blue/amber, 30s | Counting down 1s ticks | N/A | Ring turns red at < 10s | Transitioning to Escalated |
| **SignalQuality** | 3 green bars ("Strong") | Live updating | 0 bars ("No finger") | 1 amber bar ("Low signal") | Shimmering sync |

---

## 9. Information Architecture & Navigation

The application uses a persistent **Material 3 Bottom Navigation Bar** for primary top-level tabs, combined with specialized modal overlays for scans and emergency states:

```
App Navigation Root
├── Tab 1: Home / Monitor (Primary Dashboard & Quick Scan)
├── Tab 2: Baseline (Resting & Exercise Profile, Calibration)
├── Tab 3: History (Trends, Past Spot Scans, Event Logs)
└── Tab 4: Settings (Profile, Contacts, Permissions, Disclaimers)
│
├── [Modal Route]: Camera Measurement Flow (Full Screen)
│     ├── Preparation & Finger Guide
│     ├── 20-Second Active PPG Scan & Waveform
│     └── Scan Result Summary View
│
└── [Full-Screen Overlay]: Emergency Orchestration
      ├── State 1: 30s Check-In Dialog
      ├── State 2: Escalation Screen (One-Tap 911 / Contact)
      └── State 3: Cooldown & Resolution Screen
```

---

## 10. Detailed Screen Specifications

### 10.1 Screen A: Initial Setup / Minimal Onboarding
* **Purpose**: Fast, friction-free onboarding to establish user safety profile without tedious carousels.
* **Steps (Single Progressive Flow)**:
  1. **Profile Setup**: Name / Nickname, Age / Year of Birth (used for baseline heuristics).
  2. **Emergency Contact**: Contact Name, Mobile Phone number (persisted into `EngineStore`).
  3. **Sensor Permissions**: Clear permission rationale cards for Camera (PPG vitals) and Motion/Sensors (activity state classification).
  4. **Initial Baseline Calibration Prompt**: Explanation that the app needs one 60-second resting calibration scan to understand what is normal for the user.
* **CTA**: `"Start 60-Second Calibration"` or `"Do This Later (Use Demo Baseline)"`.

### 10.2 Screen B: Home / Monitoring Screen
* **Purpose**: Primary anchor screen. Communicates status, latest vitals, and next action in under 2 seconds.
* **Layout Structure**:
  1. **Header**:
     * Time-of-day greeting (e.g., "Good afternoon, Alex").
     * Engine Phase / Status Pill: `"System Ready"` (Emerald) or `"Monitoring Normal"` (Sky).
  2. **Vitals Overview Grid (2×2 Responsive MetricCards)**:
     * **Heart Rate**: e.g., `72 BPM` • Baseline delta: `Normal (68-76)`
     * **HRV (RMSSD)**: e.g., `48 ms` • Baseline delta: `Stable`
     * **Respiration Rate**: e.g., `14 BrPM` • Baseline delta: `Resting`
     * **SpO₂ Estimate**: e.g., `98%` • Subtitle: `Stable • Experimental`
  3. **Current Activity Context Card**:
     * Shows current classified state from `ActivityState`: `"Resting"` or `"Exercising / Moving"`.
     * Explanatory badge: `"Vitals are compared against your resting baseline"`.
  4. **Prominent Thumb-Zone Action**:
     * Large floating or bottom-pinned PrimaryButton:  
       `[ 📸 Take Spot Measurement (20s) ]`
     * Quick secondary action link: `"Test Demo Scenario (Replay Trace)"` for exhibition/offline testing.

### 10.3 Screen C: Camera Measurement Screen & Native Animation
* **Purpose**: Guides user to place finger over camera lens and flash, holds for 15–20 seconds, streams live waveform.
* **Layout**:
  * **Top**: Close button (`X`), Title `"Spot Measurement"`.
  * **Center-Top**: **Instructional Animation Container**:
    * Clean vector phone asset (`assets/animations/phone.png`).
    * Finger asset (`assets/animations/finger_2.png`).
    * **Animation Script**:
      * Phase 1 (0.0s - 1.0s): Finger approaches from below the phone toward the rear camera module.
      * Phase 2 (1.0s - 3.0s): Finger settles snugly over lens and flash; subtle red photoplethysmography pulse glow emanates from under fingertip.
      * Phase 3 (Hold): Holds position during continuous measurement.
  * **Center-Bottom**: **Live Waveform & Feedback**:
    * Real-time `LiveWaveformPainter` rendering live blood volume pulse waves from `engine.waveform`.
    * Placement hint text (e.g., `"Hold still — measuring"`, `"Cover the camera lens completely"`).
  * **Bottom**: **Measurement Progress**:
    * Linear progress bar filling smoothly over 20 seconds.
    * Explicit countdown: `"Measuring vital signals... 14s remaining"`.
    * Subtext: `"Keep your finger steady and relax your hand"`.

### 10.4 Screen D: Measurement States & Signal Feedback
Driven directly by `EnginePhase` and `PlacementHint`:

1. **Preparing Camera (`EnginePhase.preparingCamera`)**:
   * Message: `"Starting camera sensor..."` • Activity spinner.
2. **Finger Not Detected (`PlacementHint.noFinger`)**:
   * Graphic: Finger animation highlights camera lens.
   * Message: `"Place your fingertip over the camera and flash"`.
3. **Pressing Too Hard (`PlacementHint.pressLighter`)**:
   * Message: `"Press more lightly — capillary blood flow restricted"`.
4. **Poor Signal / Motion (`PlacementHint.keepStill`)**:
   * Message: `"Signal quality is low. Try resting your hand on a flat surface"`.
5. **Measuring (`EnginePhase.scanning` & `PlacementHint.ok`)**:
   * Message: `"Good signal. Hold still"`. Live pulse waveform active.
6. **Scan Complete (`EnginePhase.finished`)**:
   * Haptic vibration feedback, transition to Results Screen.
7. **Scan Failure (`ScanEndReason.noSignal` / `ScanEndReason.error`)**:
   * Friendly error card: `"We couldn't get a steady reading"`. Action: `[ Try Again ]`.

### 10.5 Screen E: Results & Personal Baseline Comparison Screen
* **Purpose**: Transparent post-scan summary highlighting personal deviation rather than population norms.
* **Key Elements**:
  * **Status Header**:
    * If all normal: Green pill `"Within your usual range"`.
    * If recovering from exercise: Amber pill `"Consistent with exercise recovery"`.
    * If unusual: High-contrast alert badge `"Notable physiological shift"`.
  * **Median Summary Metrics**:
    * Median Heart Rate (with $\pm \Delta$ from resting baseline).
    * Median HRV (RMSSD).
    * Median Respiration Rate.
    * SpO₂ Estimate (with `"Experimental"` caption).
  * **Signal Quality & Reliability Badge**:
    * `"Signal reliability: 94% trusted samples"`.
  * **Next Steps Guidance**:
    * Normal: `"Next recommended check: Routine"`.
    * Elevated: `"Rest for 5 minutes and check again if feeling symptoms"`.
  * **Actions**: `[ Done / Back to Home ]` and `[ Log Note / Symptoms ]`.

### 10.6 Screen F: Early Warning & Check-In Dialog State
* **Trigger**: Multi-system deviation detected (`RiskLevel.high`) persisting beyond hysteresis threshold.
* **Visual Presentation**: High-priority modal bottom sheet with high-contrast amber/orange accents.
* **Wording (Non-Diagnostic)**:
  * Title: `"Something has changed"`
  * Body: `"We noticed significant changes in several of your vital signals compared to your usual baseline."`
  * Question: `"Are you feeling okay?"`
* **Countdown Watchdog**:
  * Radial or linear 30-second timer countdown.
  * Explicit text: `"If you don't respond in 24s, we will prepare emergency assistance."`
* **Actions**:
  * `[ ✓ YES, I'M OKAY ]` (Green/Neutral secondary button — cancels alert, logs recovery state).
  * `[ ✕ I'M NOT FEELING WELL ]` (Red/Orange EmergencyButton — immediately triggers Escalation Screen).

### 10.7 Screen G: Escalation Screen (Emergency State)
* **Trigger**: User taps `"I'M NOT FEELING WELL"`, or 30-second check-in timer expires without response.
* **Visual Tone**: Unmistakably serious, stark high-contrast emergency layout. No complex menus or distractions.
* **Key Sections**:
  1. **Primary Headline**:
     * `"Please get help immediately"`
     * `"Your readings show significant multi-system changes and you indicated feeling unwell."`
  2. **One-Tap Emergency Actions (Thumb Zone)**:
     * **Button 1 (Primary Full-Width Red)**:
       * `[ 📞 CALL EMERGENCY SERVICES (911 / 112) ]`
     * **Button 2 (Secondary Elevated)**:
       * `[ 💬 NOTIFY EMERGENCY CONTACT (Alex: +1-555-0199) ]`
       * Subtitle: `Sends simulated emergency payload with vitals & timestamp`
  3. **Prescribed Medication Guidance**:
     * Calm advisory card: `"Use your prescribed emergency medication (e.g. epinephrine auto-injector) if instructed by your healthcare professional."`
     * *(Zero personalized drug dosing instructions)*.
  4. **Emergency Summary for Paramedics**:
     * Compact vitals snapshot card showing exact HR, HRV, RR, and time of alert initiation.

### 10.8 Screen H: Unresponsive User Countdown State
* **Concept**: Modeled after fall-detection protocols (Apple Watch / Garmin incident detection).
* **Behavior**:
  * Screen illuminates at full brightness.
  * Audio pulse / haptic cadence escalates over 30 seconds.
  * Copy: `"Are you okay? We detected concerning physiological changes and received no response."`
  * Countdown: `"Contacting emergency contact in 12 seconds..."`
  * Action: Large bottom button `[ I AM OKAY — CANCEL ]` to prevent false dispatch.

### 10.9 Screen I: History & Trends Screen
* **Purpose**: Review past spot measurements and longitudinal vitals without overwhelming signal-processing jargon.
* **Layout**:
  * Segmented filter: `All | Deviations | Baseline Sessions`.
  * Clean timeline list with visual indicator cards:
    * Date, timestamp, duration.
    * Median HR, HRV, RR.
    * Anomaly tag: `"Normal"` (Green), `"Post-Exercise"` (Amber), `"Deviating"` (Orange).
  * Expandable session detail card showing signal quality and baseline comparison graph.

### 10.10 Screen J: Baseline & Calibration Screen
* **Purpose**: Demystifies personal physiological baselines and enables recalibration.
* **Educational Copy**:
  * `"We learn what is normal for your body during rest and exercise so unusual changes can be recognized reliably without false alarms."`
* **Current Baseline Status**:
  * Resting Heart Rate: `68 ± 4 BPM` (Learned from 5 sessions).
  * Resting HRV: `52 ± 8 ms`.
  * Resting Respiration: `14 ± 2 BrPM`.
* **Calibration Flow**:
  * Button: `[ Start 60s Calibration Scan ]`.
  * Real-time progress bar tracking valid trusted ticks ($HR, HRV, RR \ge 30$).
  * Success / Failure feedback with actionable retry advice.

### 10.11 Screen K: Emergency Contacts Screen
* **Features**:
  * View primary emergency contact (Name, Phone number, Relationship).
  * Edit & Save with instant input validation.
  * Test Alert Simulation: `"Send Test Alert"` — demonstrates simulated payload generation without sending actual SMS.

### 10.12 Screen L: Settings & Clinical Disclaimer Screen
* **Content Sections**:
  1. **User Profile**: Name, Age, Height, Weight.
  2. **Emergency Configuration**: Contact info, Escalation timeout duration (default 30s).
  3. **Sensor Permissions**: Camera permission toggle & status, Sensor/Activity permission status.
  4. **Demo & Simulation Tools**:
     * Trigger demo traces (`Normal Trace`, `Allergic Reaction Trace`, `Signal Loss Trace`).
     * Toggle Demo Baseline (`assets/demo/baseline.json`).
  5. **Clinical Disclaimer & Regulatory Notice**:
     * Formal medical disclaimer: *"PulseGuard is an early-warning research and monitoring application. It is not approved by the FDA or CE as a medical diagnostic device. Never ignore professional medical advice or delay seeking medical treatment because of readings in this app."*

### 10.13 Screen M: Wearable / Health Data Fallback Concept
* **Architectural Strategy**:
  * The application architecture relies on the abstract `VitalsSource` contract (`flutterApp/lib/engine/sources/vitals_source.dart`).
  * If a wearable stream or Apple Health / Health Connect data source is available, it streams into `VitalsReadingSource.watch`.
  * If no wearable is connected, the UI seamlessly routes spot-monitoring requests to `CameraVitalsSource`.
  * **Zero User Friction**: The user is never confronted with confusing "Select your device" modal dialogues.

---

## 11. User State & Context Transitions

```
[ User State Machine ]

                     ┌───────────────────────────────┐
                     │          State: IDLE          │
                     │  (Resting or Normal Activity) │
                     └───────────────┬───────────────┘
                                     │
                             User taps "Measure"
                                     ▼
                     ┌───────────────────────────────┐
                     │       State: MEASURING        │
                     │  (Camera PPG 15-20s / 1 Hz)   │
                     └───────────────┬───────────────┘
                                     │
                    ┌────────────────┴────────────────┐
                    │                                 │
             Vitals in range                 Multi-system deviation
                    │                                 │
                    ▼                                 ▼
      ┌───────────────────────────┐    ┌─────────────────────────────┐
      │       State: NORMAL       │    │      State: CHECK-IN        │
      │  (Summary / Back to Idle) │    │  ("Are you feeling okay?")  │
      └───────────────────────────┘    └──────────────┬──────────────┘
                                                      │
                       ┌──────────────────────────────┴──────────────────────────────┐
                       │                                                             │
               User taps "I'm Okay"                                       User taps "Not Okay"
                       │                                                    or 30s Timeout
                       ▼                                                             ▼
         ┌───────────────────────────┐                                 ┌───────────────────────────┐
         │     State: COOLDOWN       │                                 │     State: ESCALATION     │
         │ (180s monitoring cooldown)│                                 │ (Emergency 911 / Contact) │
         └───────────────────────────┘                                 └───────────────────────────┘
```

---

## 12. Empty, Loading, and Error State Specifications

1. **Empty States**:
   * **History Screen (No measurements yet)**:
     * Icon: Clean clipboard with heart pulse glyph.
     * Copy: `"No spot measurements recorded yet."`
     * Subtitle: `"Take your first 20-second measurement to start tracking your vital trends."`
     * CTA: `[ Take First Measurement ]`.
   * **Baseline Screen (No baseline established)**:
     * Card: Blue tint highlight.
     * Copy: `"Personal baseline not calibrated."`
     * Subtitle: `"A 60-second resting calibration allows PulseGuard to customize deviation thresholds specifically to your body."`
     * CTA: `[ Calibrate Baseline ]`.
2. **Loading States**:
   * Smooth shimmer skeleton widgets matching exact card dimensions (`MetricCard` skeleton).
   * Camera initialization shows clear textual indicator: `"Calibrating camera exposure and white balance..."`.
3. **Error States**:
   * **Camera Access Denied**:
     * Icon: Shield with camera slash.
     * Copy: `"Camera access is needed for vital signal detection."`
     * CTA: `[ Open Device Settings ]`.
   * **Low Ambient Light / Low Signal Quality**:
     * Contextual banner: `"Lighting conditions are low. The camera LED flash will be enabled automatically."`

---

## 13. Animation & Motion Guidelines

1. **Native Flutter Finger Animation (`CameraFingerInstruction`)**:
   * Implemented natively using Flutter `AnimationController` and `CurvedAnimation` (zero external Lottie runtime dependencies).
   * Uses `assets/animations/phone.png` and `assets/animations/finger_2.png`.
   * Responsive layout with `LayoutBuilder` ensuring 0 overflow across any screen size.
   * Motion timing breakdown:
     * $0.0 \to 0.25$ (1.0s): Finger approaches lens with cubic ease.
     * $0.25 \to 0.75$ (2.0s): Finger rests over lens with subtle sinusoidal photoplethysmography pulse glow (`holdGlow` $0.15$).
     * $0.75 \to 1.00$ (1.0s): Finger releases smoothly back to start position.
2. **Measurement Progress & Countdown**:
   * Smooth linear progress bar animated via `Tween<double>` over 15–20 seconds.
   * Explicit countdown clock ticks smoothly second-by-second (`"15s remaining"`, `"14s remaining"`).
3. **Live Waveform Rendering**:
   * Driven by the 30 Hz `engine.waveform` stream.
   * Bezier interpolation curve using `Path.quadraticBezierTo` for organic, smooth pulse wave appearance.
4. **Emergency Motion Restraint**:
   * Zero frivolous bouncing or decorative animations during Check-In and Escalation screens.
   * Emergency button features a subtle, rhythmic glow (`2.0s` easeInOut) that never blocks or delays user interaction.

---

## 14. Accessibility & Outdoor Readability Rules

1. **High Contrast for Outdoor Use**:
   * Background is pure slate/white (`#F8FAFC`); all primary text is deep navy slate (`#0F172A`), providing a contrast ratio exceeding **12:1** (far above WCAG AAA standard 7:1).
2. **Touch Targets**:
   * Every interactive button, toggle, and card has a minimum tap target of **48 × 48 dp**.
3. **Triple-Encoded Status Signals**:
   * Risk state is never conveyed by color alone. Every risk indicator combines:
     1. Semantic Color (e.g., Orange)
     2. Distinct Iconography (e.g., Alert Triangle)
     3. Explicit Plain-Text Copy (e.g., `"Notable Change Detected"`)
4. **Responsive Constraints**:
   * All screens wrapped with `SafeArea`.
   * Responsive height checking using `LayoutBuilder` and `SingleChildScrollView` to prevent pixel overflow on compact Android displays (e.g., 320–360 dp width).

---

## 15. Screen-by-Screen Implementation Checklist

### Phase 1: Design Tokens, Theme & Reusable Components
- [ ] Create `lib/ui/theme/pulse_colors.dart` with 60/30/10 semantic tokens and risk levels.
- [ ] Create `lib/ui/theme/pulse_typography.dart` with tabular figure font styles.
- [ ] Create `lib/ui/theme/pulse_theme.dart` configuring Material 3 `ThemeData`.
- [ ] Implement `PrimaryButton`, `SecondaryButton`, and `EmergencyButton`.
- [ ] Implement `MetricCard`, `VitalMetricTile`, and `RiskBadge`.
- [ ] Implement `LiveWaveformPainter` for 30 Hz PPG stream visualization.
- [ ] Update `CameraFingerInstruction` to use `finger_2.png` and accurate timing.

### Phase 2: Core Monitoring & Measurement Navigation
- [ ] Build `HomeScreen` with greeting, system status pill, 2×2 vitals grid, activity state, and scan CTA.
- [ ] Build `CameraMeasurementScreen` integrating live camera feed, finger animation, countdown, and waveform.
- [ ] Wire `PulseGuardEngine` stream subscriptions (`snapshot`, `vitals`, `waveform`, `placement`).
- [ ] Build `ResultsScreen` presenting personal baseline deltas, signal quality, and safe next steps.

### Phase 3: Early Warning, Check-In & Emergency Escalation
- [ ] Implement `CheckInSheet` modal triggered on `AlertEventKind.checkInOpened` with 30s countdown.
- [ ] Implement `EscalationScreen` with one-tap emergency call and simulated contact notification.
- [ ] Implement Unresponsive User watchdog state with auto-escalation timer.
- [ ] Implement Post-escalation Cooldown state handling.

### Phase 4: Baseline, History & Settings
- [ ] Build `BaselineScreen` explaining resting vs exercise baselines and calibration runner.
- [ ] Build `HistoryScreen` with timeline cards and spot measurement summaries.
- [ ] Build `EmergencyContactsScreen` with contact persistence via `EngineStore`.
- [ ] Build `SettingsScreen` with permissions status, demo trace triggers, and clinical disclaimer.
- [ ] Implement `PulseBottomNav` orchestrating tab navigation.
