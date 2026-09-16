import 'package:flutter/material.dart';
import '../../../core/theme/pulse_colors.dart';
import '../../../core/theme/pulse_typography.dart';

/// Cal AI-inspired Hero Vital card presenting the primary vital (Heart Rate)
/// with a large circular gauge indicator on the right.
class HeroVitalCard extends StatelessWidget {
  final String title;
  final String? value;
  final String unit;
  final String? deltaText;
  final double progress; // 0.0 to 1.0
  final Color progressColor;
  final IconData centerIcon;
  final VoidCallback? onTap;

  const HeroVitalCard({
    super.key,
    this.title = 'Heart Rate',
    required this.value,
    this.unit = 'BPM',
    this.deltaText,
    this.progress = 0.72,
    this.progressColor = PulseColors.riskNormal,
    this.centerIcon = Icons.local_fire_department_rounded,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PulseColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: PulseColors.divider, width: 1.2),
        boxShadow: const [PulseColors.cardShadow],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 20.0),
            child: Row(
              children: [
                // Left Column: Big metric + Labels
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          value ?? '—',
                          style: PulseTypography.displayMetric.copyWith(
                            fontSize: 48,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.5,
                            color: value != null
                                ? PulseColors.textPrimary
                                : PulseColors.textTertiary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$title • $unit',
                        style: PulseTypography.bodyMedium.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: PulseColors.textSecondary,
                        ),
                      ),
                      if (deltaText != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          deltaText!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: PulseTypography.caption.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: PulseColors.textTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Right Column: Circular Progress Gauge with Center Icon
                SizedBox(
                  width: 92,
                  height: 92,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Gauge Background Ring
                      SizedBox(
                        width: 92,
                        height: 92,
                        child: CircularProgressIndicator(
                          value: 1.0,
                          strokeWidth: 9,
                          color: PulseColors.surfaceDim,
                        ),
                      ),
                      // Gauge Progress Ring
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: progress.clamp(0.0, 1.0)),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutCubic,
                        builder: (context, val, _) {
                          return SizedBox(
                            width: 92,
                            height: 92,
                            child: CircularProgressIndicator(
                              value: val,
                              strokeWidth: 9,
                              strokeCap: StrokeCap.round,
                              color: progressColor,
                            ),
                          );
                        },
                      ),
                      // Center Icon in a soft circular pill
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: PulseColors.surfaceDim,
                        ),
                        child: Icon(
                          centerIcon,
                          size: 22,
                          color: PulseColors.textPrimary,
                        ),
                      ),
                    ],
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
