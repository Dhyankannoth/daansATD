import 'package:flutter/material.dart';
import '../../../core/theme/pulse_colors.dart';
import '../../../core/theme/pulse_typography.dart';

/// Context card presenting system state, activity classification, or guidance notes.
class StatusCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color? accentColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const StatusCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.accentColor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? PulseColors.textPrimary;

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
            padding: const EdgeInsets.all(18.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color == PulseColors.textPrimary
                        ? PulseColors.surfaceDim
                        : color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: PulseTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: PulseColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: PulseTypography.bodyRegular.copyWith(
                          fontSize: 13,
                          height: 1.4,
                          color: PulseColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 8), trailing!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
