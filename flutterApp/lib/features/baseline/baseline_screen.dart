import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/pulse_constants.dart';
import '../../core/theme/pulse_colors.dart';
import '../../core/theme/pulse_typography.dart';
import '../../engine/api/engine_snapshot.dart';
import '../../services/pulse_engine_scope.dart';
import '../../shared/widgets/buttons/primary_button.dart';
import '../../shared/widgets/buttons/secondary_button.dart';
import '../../shared/widgets/cards/vital_metric_tile.dart';
import '../../shared/widgets/indicators/pulse_info_icon.dart';
import '../../shared/widgets/mascot/bluey_companion.dart';

/// Screen J: Baseline & Calibration Screen.
class BaselineScreen extends StatefulWidget {
  const BaselineScreen({super.key});

  @override
  State<BaselineScreen> createState() => _BaselineScreenState();
}

class _BaselineScreenState extends State<BaselineScreen> {
  StreamSubscription<CalibrationProgress>? _calSub;
  CalibrationProgress? _progress;
  bool _isCalibrating = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_calSub == null) {
      final engine = PulseEngineScope.engineOf(context);
      _calSub = engine.calibration.listen((prog) {
        if (!mounted) return;
        setState(() {
          _progress = prog;
          if (prog.done) {
            _isCalibrating = false;
            if (prog.success == true) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: PulseColors.riskNormal,
                  content: Text(
                    'Calibration successfully saved to your baseline!',
                  ),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: PulseColors.riskCritical,
                  content: Text(
                    prog.failureReason ?? 'Calibration failed. Please try again.',
                  ),
                ),
              );
            }
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _calSub?.cancel();
    super.dispose();
  }

  Future<void> _startCalibration() async {
    final engine = PulseEngineScope.engineOf(context);
    setState(() {
      _isCalibrating = true;
      _progress = null;
    });
    try {
      await engine.startCalibration();
    } catch (e) {
      setState(() => _isCalibrating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting calibration: $e')),
        );
      }
    }
  }

  Future<void> _cancelCalibration() async {
    final engine = PulseEngineScope.engineOf(context);
    await engine.cancelCalibration();
    setState(() {
      _isCalibrating = false;
      _progress = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final engine = PulseEngineScope.engineOf(context);

    return Scaffold(
      backgroundColor: PulseColors.background,
      appBar: AppBar(
        backgroundColor: PulseColors.surface,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Personal Baseline',
          style: PulseTypography.headingMedium,
        ),
      ),
      body: SafeArea(
        child: ValueListenableBuilder<EngineSnapshot>(
          valueListenable: engine.snapshot,
          builder: (context, snapshot, _) {
            final baseline = snapshot.baseline;
            final hasBaseline = snapshot.hasBaseline;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 20.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Companion Explainer with interactive (i) info icon
                  const BlueyCompanion(
                    pose: BlueyPose.checking,
                    layoutMode: BlueyLayoutMode.speechCard,
                    title: 'Why Personal Baselines Matter',
                    message:
                        "Everyone is a little different. I'm learning what's normal for your body so I can catch genuine changes accurately.",
                    infoTooltip:
                        'A fixed heart-rate threshold triggers dangerous false alarms during exercise. PulseGuard learns what is normal for YOUR body during rest and physical activity (mean ± 2 SD), so significant multi-system shifts are recognized accurately.',
                    mascotHeight: 76,
                  ),

                  const SizedBox(height: 24),

                  // Active In-Flight Calibration Box
                  if (_isCalibrating) ...[
                    _buildCalibrationProgressCard(),
                    const SizedBox(height: 24),
                  ],

                  // Current Baseline Values Card
                  Text(
                    'CURRENT LEARNED BASELINE',
                    style: PulseTypography.caption.copyWith(
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (hasBaseline && baseline != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: PulseColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: PulseColors.divider),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: PulseColors.riskNormal,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    baseline.isDemo
                                        ? 'Demo Baseline Active'
                                        : 'Calibrated Profile',
                                    style: PulseTypography.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: PulseColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${baseline.hr.sessionCount} session(s)',
                                style: PulseTypography.caption.copyWith(
                                  color: PulseColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),

                          VitalMetricTile(
                            icon: Icons.favorite_rounded,
                            title: 'Resting Heart Rate',
                            value:
                                '${baseline.hr.mean.toStringAsFixed(0)} ± ${baseline.hr.sd.toStringAsFixed(1)}',
                            unit: 'BPM',
                            comparison: 'Learned normal distribution',
                          ),
                          const SizedBox(height: 8),

                          VitalMetricTile(
                            icon: Icons.stacked_line_chart_rounded,
                            title: 'Resting HRV (RMSSD)',
                            value:
                                '${baseline.hrv.mean.toStringAsFixed(0)} ± ${baseline.hrv.sd.toStringAsFixed(1)}',
                            unit: 'ms',
                            comparison: 'Autonomic nervous system baseline',
                          ),
                          const SizedBox(height: 8),

                          VitalMetricTile(
                            icon: Icons.air_rounded,
                            title: 'Resting Respiration',
                            value:
                                '${baseline.rr.mean.toStringAsFixed(0)} ± ${baseline.rr.sd.toStringAsFixed(1)}',
                            unit: 'BrPM',
                            comparison: 'Cardiorespiratory coupling',
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Column(
                          children: [
                            Image.asset(
                              'assets/mascot/bluey_emptyState.png',
                              height: 140,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'No Baseline Established',
                                  style: PulseTypography.headingMedium,
                                ),
                                const SizedBox(width: 6),
                                const PulseInfoIcon(
                                  message:
                                      'Record a 60-second resting calibration scan or load the demo baseline to enable tailored anomaly detection.',
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Let's take your first calibration so I can learn your baseline.",
                              textAlign: TextAlign.center,
                              style: PulseTypography.bodyRegular.copyWith(
                                fontSize: 13,
                                color: PulseColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  // Actions: Start 60s Calibration Scan
                  if (!_isCalibrating)
                    PrimaryButton(
                      label: 'Start 2.5-Minute Calibration',
                      icon: Icons.play_arrow_rounded,
                      onPressed: _startCalibration,
                    ),

                  const SizedBox(height: 12),

                  // Secondary: Demo Baseline
                  SecondaryButton(
                    label: 'Load Demo Baseline (For Testing)',
                    icon: Icons.science_outlined,
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      await engine.loadDemoBaseline();
                      if (mounted) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Demo baseline loaded successfully.'),
                          ),
                        );
                      }
                    },
                  ),

                  if (hasBaseline) ...[
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          await engine.clearBaseline();
                          if (mounted) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Personal baseline cleared.'),
                              ),
                            );
                          }
                        },
                        child: Text(
                          'Clear Stored Baseline',
                          style: PulseTypography.caption.copyWith(
                            color: PulseColors.riskCritical,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCalibrationProgressCard() {
    final prog = _progress;
    final elapsedSec = prog?.elapsed.inSeconds ?? 0;
    final totalSec = prog?.total.inSeconds ?? PulseConstants.calibrationDurationSeconds;
    final pct = totalSec > 0 ? (elapsedSec / totalSec).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PulseColors.primaryLight.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PulseColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Calibration Scan in Progress',
                style: PulseTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: PulseColors.primaryDark,
                ),
              ),
              Text(
                '${(totalSec - elapsedSec).clamp(0, totalSec)}s left',
                style: PulseTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: PulseColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: Colors.white,
              valueColor: const AlwaysStoppedAnimation<Color>(
                PulseColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Image.asset(
                'assets/mascot/bluey_scanning.png',
                height: 44,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Keep your finger steady while I learn your baseline signals.',
                  style: PulseTypography.caption.copyWith(
                    color: PulseColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              PulseInfoIcon(
                message:
                    'Trusted ticks: HR ${prog?.trustedTicksHr ?? 0}/30 • HRV ${prog?.trustedTicksHrv ?? 0}/30 • RR ${prog?.trustedTicksRr ?? 0}/30',
              ),
            ],
          ),
          const SizedBox(height: 16),
          SecondaryButton(
            label: 'Cancel Calibration',
            icon: Icons.close_rounded,
            onPressed: _cancelCalibration,
          ),
        ],
      ),
    );
  }
}
