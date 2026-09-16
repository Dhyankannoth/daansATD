import 'package:flutter/material.dart';
import '../../../core/theme/pulse_colors.dart';
import '../../../core/theme/pulse_typography.dart';

/// Horizontal vitals row used in summary cards, history lists, and emergency paramedic snapshot.
class VitalMetricTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String unit;
  final String? comparison;
  final Color? comparisonColor;
  final bool isTrusted;

  const VitalMetricTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.unit,
    this.comparison,
    this.comparisonColor,
    this.isTrusted = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: PulseColors.surfaceDim,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: PulseColors.divider),
            ),
            child: Icon(icon, size: 18, color: PulseColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: PulseTypography.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: PulseColors.textSecondary,
                  ),
                ),
                if (comparison != null)
                  Text(
                    comparison!,
                    style: PulseTypography.caption.copyWith(
                      color: comparisonColor ?? PulseColors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: PulseTypography.headingMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isTrusted
                      ? PulseColors.textPrimary
                      : PulseColors.textTertiary,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: PulseTypography.caption.copyWith(
                  color: PulseColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
