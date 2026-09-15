import 'package:flutter/material.dart';
import '../../../core/theme/pulse_colors.dart';
import '../../../core/theme/pulse_typography.dart';

/// Clean, high-contrast vitals card for the 2x2 grid on Home and Results screens.
class MetricCard extends StatelessWidget {
  final String label;
  final String? value;
  final String unit;
  final String? deltaText;
  final Color? deltaColor;
  final IconData? icon;
  final bool isTrusted;
  final bool isExperimental;
  final VoidCallback? onTap;

  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    this.deltaText,
    this.deltaColor,
    this.icon,
    this.isTrusted = true,
    this.isExperimental = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PulseColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PulseColors.divider, width: 1),
        boxShadow: const [PulseColors.cardShadow],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(
                            icon,
                            size: 16,
                            color: PulseColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          label.toUpperCase(),
                          style: PulseTypography.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            color: PulseColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    if (isExperimental)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: PulseColors.riskMonitoringBg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: PulseColors.riskMonitoring.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        child: Text(
                          'Experimental',
                          style: PulseTypography.caption.copyWith(
                            fontSize: 10,
                            color: PulseColors.riskMonitoring,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isTrusted
                              ? PulseColors.riskNormal
                              : PulseColors.riskElevated,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                // Value and Unit Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value ?? '—',
                      style: PulseTypography.displayMetric.copyWith(
                        color: value != null
                            ? PulseColors.textPrimary
                            : PulseColors.textTertiary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(unit, style: PulseTypography.displayUnit),
                  ],
                ),

                const SizedBox(height: 8),

                // Baseline Delta or Range subtitle
                if (deltaText != null)
                  Text(
                    deltaText!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PulseTypography.caption.copyWith(
                      color: deltaColor ?? PulseColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else
                  Text(
                    'No baseline delta',
                    style: PulseTypography.caption.copyWith(
                      color: PulseColors.textTertiary,
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
