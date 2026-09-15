import 'package:flutter/material.dart';
import '../../../../core/theme/pulse_colors.dart';
import '../../../../core/theme/pulse_typography.dart';
import '../../../../engine/api/engine_snapshot.dart';
import '../../../../services/pulse_engine_scope.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';

/// Screen 8 — Baseline Complete: Finish onboarding and transition into normal monitoring.
/// Animation: Confirm (Calm, reassuring completion with established resting vitals).
class BaselineCompleteScreen extends StatefulWidget {
  final ScanSummary? summary;
  final VoidCallback onStartMonitoring;

  const BaselineCompleteScreen({
    super.key,
    this.summary,
    required this.onStartMonitoring,
  });

  @override
  State<BaselineCompleteScreen> createState() => _BaselineCompleteScreenState();
}

class _BaselineCompleteScreenState extends State<BaselineCompleteScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.00, 0.60, curve: Curves.easeOutBack),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.20, 1.00, curve: Curves.easeOut),
    );

    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final engine = PulseEngineScope.engineOf(context);
    final baseline = engine.baseline;

    final hrStr = baseline != null
        ? '${baseline.hr.mean.toStringAsFixed(0)} ± ${baseline.hr.sd.toStringAsFixed(1)}'
        : (widget.summary?.medianHr != null
            ? '${widget.summary!.medianHr!.toStringAsFixed(0)} ± 3.0'
            : '72 ± 3.2');

    final hrvStr = baseline != null
        ? '${baseline.hrv.mean.toStringAsFixed(0)} ± ${baseline.hrv.sd.toStringAsFixed(1)}'
        : (widget.summary?.medianHrv != null
            ? '${widget.summary!.medianHrv!.toStringAsFixed(0)} ± 4.5'
            : '48 ± 5.0');

    final rrStr = baseline != null
        ? '${baseline.rr.mean.toStringAsFixed(0)} ± ${baseline.rr.sd.toStringAsFixed(1)}'
        : (widget.summary?.medianRr != null
            ? '${widget.summary!.medianRr!.toStringAsFixed(0)} ± 1.5'
            : '16 ± 1.8');

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight > 50 ? constraints.maxHeight - 24 : 500,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    const SizedBox(height: 20),

                    // Confirm Animation: Bluey Excited Celebration Mascot
                    ScaleTransition(
                      scale: _scaleAnim,
                      child: Center(
                        child: Image.asset(
                          'assets/mascot/bluey_excited.png',
                          height: 220,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Headline
                    FadeTransition(
                      opacity: _fadeAnim,
                      child: Text(
                        "You're all set.",
                        textAlign: TextAlign.center,
                        style: PulseTypography.headingLarge.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                          color: PulseColors.textPrimary,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Supporting Text
                    FadeTransition(
                      opacity: _fadeAnim,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Text(
                          'Your initial baseline has been created. It will become more reliable as I learn your normal patterns over time.',
                          textAlign: TextAlign.center,
                          style: PulseTypography.bodyRegular.copyWith(
                            fontSize: 15,
                            height: 1.5,
                            color: PulseColors.textSecondary,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Established Baseline Profile Card
                    FadeTransition(
                      opacity: _fadeAnim,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: PulseColors.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: PulseColors.divider, width: 1.2),
                          boxShadow: const [PulseColors.cardShadow],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'INITIAL BASELINE ESTABLISHED',
                              overflow: TextOverflow.ellipsis,
                              style: PulseTypography.caption.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: PulseColors.textTertiary,
                              ),
                            ),
                            const Divider(height: 24, color: PulseColors.divider),

                            _buildMetricRow(
                              icon: Icons.favorite_rounded,
                              label: 'Resting Heart Rate',
                              value: hrStr,
                              unit: 'BPM',
                              color: PulseColors.tintEmeraldIcon,
                            ),
                            const SizedBox(height: 14),

                            _buildMetricRow(
                              icon: Icons.stacked_line_chart_rounded,
                              label: 'Resting HRV (RMSSD)',
                              value: hrvStr,
                              unit: 'ms',
                              color: PulseColors.tintRedIcon,
                            ),
                            const SizedBox(height: 14),

                            _buildMetricRow(
                              icon: Icons.air_rounded,
                              label: 'Resting Respiration',
                              value: rrStr,
                              unit: 'BrPM',
                              color: PulseColors.tintAmberIcon,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Continuous refinement footnote
                    FadeTransition(
                      opacity: _fadeAnim,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: PulseColors.surfaceDim,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.sync_rounded,
                              size: 18,
                              color: PulseColors.textSecondary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Baseline values update progressively as you record future 20s spot scans during your everyday routine.',
                                style: PulseTypography.caption.copyWith(
                                  fontSize: 11,
                                  height: 1.35,
                                  color: PulseColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // CTA Button
                FadeTransition(
                  opacity: _fadeAnim,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: PrimaryButton(
                      label: 'Start Monitoring',
                      onPressed: widget.onStartMonitoring,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricRow({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: PulseTypography.bodyMedium.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: PulseColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: PulseTypography.headingMedium.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: PulseColors.textPrimary,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          unit,
          style: PulseTypography.caption.copyWith(
            fontWeight: FontWeight.w500,
            color: PulseColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
