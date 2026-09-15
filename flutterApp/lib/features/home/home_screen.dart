import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/pulse_constants.dart';
import '../../core/theme/pulse_colors.dart';
import '../../core/theme/pulse_typography.dart';
import '../../engine/api/engine_snapshot.dart';
import '../../engine/api/events.dart';
import '../../services/pulse_engine_scope.dart';
import '../../shared/widgets/buttons/primary_button.dart';
import '../../shared/widgets/buttons/secondary_button.dart';
import '../../shared/widgets/cards/activity_intensity_selector.dart';
import '../../shared/widgets/cards/hero_vital_card.dart';
import '../../shared/widgets/cards/vitals_triplet_row.dart';
import '../../shared/widgets/indicators/pulse_info_icon.dart';
import '../../shared/widgets/indicators/risk_badge.dart';
import '../../shared/widgets/mascot/bluey_companion.dart';
import '../../shared/widgets/navigation/week_strip.dart';
import '../measurement/camera_measurement_screen.dart';

/// Screen B: Home / Monitoring Screen.
///
/// Seamlessly integrates Bluey as a persistent product companion that communicates
/// monitoring status, guidance, and reassurance alongside vital metrics.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Activity context selector for upcoming scan: Resting vs Exercising
  bool _isPostExercise = false;
  DateTime _selectedDate = DateTime.now();
  String _userName = 'Alex';

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name');
    if (name != null && name.trim().isNotEmpty && mounted) {
      setState(() {
        _userName = name.trim();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final engine = PulseEngineScope.engineOf(context);

    return Scaffold(
      backgroundColor: PulseColors.background,
      body: SafeArea(
        child: ValueListenableBuilder<EngineSnapshot>(
          valueListenable: engine.snapshot,
          builder: (context, snapshot, _) {
            final vitals = snapshot.latestVitals;
            final baseline = snapshot.baseline;
            final riskLevel = snapshot.risk?.level ?? RiskLevel.normal;

            // Compute delta strings
            String? hrDelta;
            if (vitals?.hr != null && baseline != null) {
              final diff = vitals!.hr! - baseline.hr.mean;
              final sign = diff >= 0 ? '+' : '';
              hrDelta = '$sign${diff.toStringAsFixed(0)} BPM from baseline';
            } else if (baseline != null) {
              hrDelta = 'Baseline: ${baseline.hr.mean.toStringAsFixed(0)} BPM';
            }

            // Normalization for gauges
            final hrProgress = vitals?.hr != null
                ? ((vitals!.hr! - 40) / 140).clamp(0.1, 1.0)
                : 0.65;
            final hrvProgress = vitals?.hrv != null
                ? (vitals!.hrv! / 100).clamp(0.1, 1.0)
                : 0.55;
            final rrProgress = vitals?.rr != null
                ? (vitals!.rr! / 30).clamp(0.1, 1.0)
                : 0.50;
            final spo2Progress = vitals?.spo2 != null
                ? (vitals!.spo2! / 100).clamp(0.1, 1.0)
                : 0.98;

            // Determine Bluey companion status based on current application state
            final (
              BlueyPose companionPose,
              String statusTitle,
              String statusMessage,
              String infoExplanation,
            ) = switch (riskLevel) {
              RiskLevel.high || RiskLevel.critical => (
                  BlueyPose.attentive,
                  'Observation Attention',
                  'Something looks a little different from your usual pattern. Let\'s check how you\'re feeling.',
                  'Multi-system vital deviation detected across cardiovascular and respiratory signals.',
                ),
              RiskLevel.elevated => (
                  BlueyPose.attentive,
                  'Mild Signal Deviation',
                  'Readings shifted slightly from your baseline. Consider resting while I observe.',
                  'One or more signals are outside 2 standard deviations from your personal baseline.',
                ),
              RiskLevel.monitoring => (
                  BlueyPose.checking,
                  'Post-Exercise Recovery',
                  'Looks like you\'re active. I\'ll keep that in mind when looking at your signals.',
                  'Recovery mode adapts heart-rate thresholds to prevent exercise false alarms.',
                ),
              RiskLevel.normal => snapshot.alertState == AlertSnapshotState.cooldown
                  ? (
                      BlueyPose.checking,
                      'Monitoring Cooldown',
                      'I\'m continually observing your signals for any multi-system changes.',
                      'Observing post-check-in stabilization to prevent repeated prompts.',
                    )
                  : (
                      BlueyPose.calm,
                      'Monitoring Normally',
                      'Everything looks normal right now. Your signals are within your usual range.',
                      snapshot.hasBaseline
                          ? 'Personal baseline active with multi-system anomaly detection enabled.'
                          : 'Standard baseline active. Complete a 60s calibration to establish personalized thresholds.',
                    ),
            };

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 14.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Top Brand Header & Streak / Status Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Brand Logo + App Name
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: PulseColors.surfaceDark,
                            ),
                            child: const Icon(
                              Icons.favorite_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            PulseConstants.appTitle,
                            style: TextStyle(
                              fontFamily: PulseTypography.fontFamily,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6,
                              color: PulseColors.textPrimary,
                            ),
                          ),
                        ],
                      ),

                      // Streak pill badge & Risk badge
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (riskLevel != RiskLevel.normal) ...[
                            RiskBadge(level: riskLevel, compact: true),
                            const SizedBox(width: 8),
                          ],
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: PulseColors.borderSubtle,
                                width: 1.2,
                              ),
                              boxShadow: const [PulseColors.cardShadow],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  '🔥',
                                  style: TextStyle(fontSize: 14),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '0',
                                  style: PulseTypography.caption.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: PulseColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // 2. Week Calendar Strip
                  WeekStrip(
                    selectedDate: _selectedDate,
                    onDateSelected: (date) {
                      setState(() => _selectedDate = date);
                    },
                  ),

                  const SizedBox(height: 18),

                  // 3. Persistent Bluey Companion Greeting & Reassurance
                  BlueyCompanion.heroGreeting(
                    userName: _userName,
                    subtitle: "I'm keeping an eye on your vital signals.",
                    pose: BlueyPose.welcome,
                    mascotHeight: 90,
                  ),

                  const SizedBox(height: 16),

                  // Replay In-Progress Notice if active
                  if (snapshot.phase == EnginePhase.replaying) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: PulseColors.riskMonitoringBg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: PulseColors.riskMonitoring.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Replay in progress: ${snapshot.message}',
                              style: PulseTypography.caption.copyWith(
                                color: PulseColors.primaryDark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => engine.stopReplay(),
                            child: const Text('Stop'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // 4. Hero Vital Metric: Heart Rate
                  HeroVitalCard(
                    title: 'Heart Rate',
                    value: vitals?.hr != null
                        ? vitals!.hr!.toStringAsFixed(0)
                        : (baseline != null ? baseline.hr.mean.toStringAsFixed(0) : '72'),
                    unit: 'BPM',
                    deltaText: hrDelta ?? 'Learned resting baseline',
                    progress: hrProgress,
                    progressColor: PulseColors.tintEmeraldIcon,
                    centerIcon: Icons.local_fire_department_rounded,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const CameraMeasurementScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // 5. 3-Column Secondary Cards: HRV, Respiration, SpO2
                  VitalsTripletRow(
                    hrvValue: vitals?.hrv != null
                        ? vitals!.hrv!.toStringAsFixed(0)
                        : (baseline != null ? baseline.hrv.mean.toStringAsFixed(0) : '48'),
                    rrValue: vitals?.rr != null
                        ? vitals!.rr!.toStringAsFixed(0)
                        : (baseline != null ? baseline.rr.mean.toStringAsFixed(0) : '16'),
                    spo2Value: vitals?.spo2 != null
                        ? vitals!.spo2!.toStringAsFixed(0)
                        : '98',
                    hrvProgress: hrvProgress,
                    rrProgress: rrProgress,
                    spo2Progress: spo2Progress,
                    onHrvTap: () {},
                    onRrTap: () {},
                    onSpo2Tap: () {},
                  ),

                  const SizedBox(height: 20),

                  // 6. Observation Status Row with (i) info icon instead of heavy container
                  Row(
                    children: [
                      Text(
                        'OBSERVATION STATUS',
                        style: PulseTypography.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: PulseColors.textTertiary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      PulseInfoIcon(
                        message: snapshot.hasBaseline
                            ? 'Personal baseline active. Multi-system deviation monitoring enabled.'
                            : 'Default population baseline active. Record a 60s calibration for personalized limits.',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Dynamic Bluey Status Companion Card
                  BlueyCompanion.status(
                    statusTitle: statusTitle,
                    statusMessage: statusMessage,
                    pose: companionPose,
                    infoTooltip: infoExplanation,
                    mascotHeight: 72,
                  ),

                  const SizedBox(height: 20),

                  // 7. Activity Context Selector: Resting vs Post-Exercise
                  ActivityIntensitySelector(
                    isPostExercise: _isPostExercise,
                    onSelectionChanged: (val) {
                      setState(() => _isPostExercise = val);
                    },
                  ),

                  const SizedBox(height: 20),

                  // 8. Primary Action Button
                  PrimaryButton(
                    label: 'Take Spot Measurement (20s)',
                    icon: Icons.camera_alt_rounded,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => CameraMeasurementScreen(
                            timeSinceExercise: _isPostExercise
                                ? const Duration(minutes: 5)
                                : null,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // 9. Demonstration Traces Section
                  Row(
                    children: [
                      Text(
                        'DEMONSTRATION & TESTING',
                        style: PulseTypography.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: PulseColors.textTertiary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const PulseInfoIcon(
                        message:
                            'Pre-recorded PPG optical sensor traces demonstrating physiological reactions vs resting stability.',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: SecondaryButton(
                          label: 'Reaction Trace',
                          icon: Icons.science_outlined,
                          onPressed: () async {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const CameraMeasurementScreen(
                                  replayAssetPath: 'assets/traces/reaction.json',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SecondaryButton(
                          label: 'Normal Trace',
                          icon: Icons.favorite_outline_rounded,
                          onPressed: () async {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const CameraMeasurementScreen(
                                  replayAssetPath: 'assets/traces/normal.json',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
