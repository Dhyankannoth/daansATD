import 'package:flutter/material.dart';
import '../../../core/theme/pulse_colors.dart';
import '../../../core/theme/pulse_typography.dart';

/// Cal AI-style 3-column vitals cards (HRV, Respiration, SpO2)
/// with top numeric value, subtitle label, and soft bottom circular icon ring.
class VitalsTripletRow extends StatelessWidget {
  final String? hrvValue;
  final String? rrValue;
  final String? spo2Value;
  final double hrvProgress;
  final double rrProgress;
  final double spo2Progress;
  final VoidCallback? onHrvTap;
  final VoidCallback? onRrTap;
  final VoidCallback? onSpo2Tap;

  const VitalsTripletRow({
    super.key,
    required this.hrvValue,
    required this.rrValue,
    required this.spo2Value,
    this.hrvProgress = 0.65,
    this.rrProgress = 0.55,
    this.spo2Progress = 0.98,
    this.onHrvTap,
    this.onRrTap,
    this.onSpo2Tap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            // 1. HRV Card (Red / Rose accent)
            Expanded(
              child: _buildTripletCard(
                value: hrvValue != null ? '${hrvValue}ms' : '—',
                label: 'HRV',
                subLabel: 'RMSSD',
                progress: hrvProgress,
                ringColor: PulseColors.tintRedIcon,
                ringBg: PulseColors.tintRedBg,
                icon: Icons.stacked_line_chart_rounded,
                iconColor: PulseColors.tintRedIcon,
                onTap: onHrvTap,
              ),
            ),
            const SizedBox(width: 10),

            // 2. Respiration Card (Amber / Orange accent)
            Expanded(
              child: _buildTripletCard(
                value: rrValue != null ? '${rrValue}g' : (rrValue != null ? '$rrValue' : '—'),
                displayOverride: rrValue != null ? '$rrValue/m' : '—',
                label: 'Respiration',
                subLabel: 'BrPM',
                progress: rrProgress,
                ringColor: PulseColors.tintAmberIcon,
                ringBg: PulseColors.tintAmberBg,
                icon: Icons.air_rounded,
                iconColor: PulseColors.tintAmberIcon,
                onTap: onRrTap,
              ),
            ),
            const SizedBox(width: 10),

            // 3. SpO2 Card (Indigo / Blue accent)
            Expanded(
              child: _buildTripletCard(
                value: spo2Value != null ? '$spo2Value%' : '98%',
                label: 'SpO₂',
                subLabel: 'Estimate',
                progress: spo2Progress,
                ringColor: PulseColors.tintBlueIcon,
                ringBg: PulseColors.tintBlueBg,
                icon: Icons.water_drop_rounded,
                iconColor: PulseColors.tintBlueIcon,
                onTap: onSpo2Tap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Carousel / Pagination Indicator Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: PulseColors.textPrimary,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: PulseColors.borderSubtle,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: PulseColors.borderSubtle,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTripletCard({
    required String value,
    String? displayOverride,
    required String label,
    required String subLabel,
    required double progress,
    required Color ringColor,
    required Color ringBg,
    required IconData icon,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    final displayText = displayOverride ?? value;

    return Container(
      height: 154,
      decoration: BoxDecoration(
        color: PulseColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: PulseColors.divider, width: 1.2),
        boxShadow: const [PulseColors.cardShadow],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top: Value & Label
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        displayText,
                        style: PulseTypography.headingLarge.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: PulseColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$label $subLabel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PulseTypography.caption.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: PulseColors.textSecondary,
                      ),
                    ),
                  ],
                ),

                // Bottom: Circular Progress Ring with Center Tinted Icon
                Center(
                  child: SizedBox(
                    width: 54,
                    height: 54,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Background track
                        SizedBox(
                          width: 54,
                          height: 54,
                          child: CircularProgressIndicator(
                            value: 1.0,
                            strokeWidth: 4.5,
                            color: PulseColors.surfaceDim,
                          ),
                        ),
                        // Progress arc
                        SizedBox(
                          width: 54,
                          height: 54,
                          child: CircularProgressIndicator(
                            value: progress.clamp(0.0, 1.0),
                            strokeWidth: 4.5,
                            strokeCap: StrokeCap.round,
                            color: ringColor.withValues(alpha: 0.8),
                          ),
                        ),
                        // Soft Icon Pill
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: ringBg,
                          ),
                          child: Icon(
                            icon,
                            size: 15,
                            color: iconColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
