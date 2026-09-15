import 'package:flutter/material.dart';
import '../../../core/theme/pulse_colors.dart';
import '../../../core/theme/pulse_typography.dart';

/// Cal AI-style activity and intensity context selector with sleek pill chips.
class ActivityIntensitySelector extends StatelessWidget {
  final bool isPostExercise;
  final ValueChanged<bool> onSelectionChanged;

  const ActivityIntensitySelector({
    super.key,
    required this.isPostExercise,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: PulseColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: PulseColors.divider, width: 1.2),
        boxShadow: const [PulseColors.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                size: 18,
                color: PulseColors.textPrimary,
              ),
              const SizedBox(width: 8),
              Text(
                'Activity Context',
                style: PulseTypography.headingMedium.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: PulseColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Pill Selector Row
          Row(
            children: [
              // Resting State Pill
              Expanded(
                child: _buildPill(
                  label: 'Resting',
                  icon: Icons.nightlight_round,
                  isSelected: !isPostExercise,
                  onTap: () => onSelectionChanged(false),
                ),
              ),
              const SizedBox(width: 10),
              // Post-Exercise Pill
              Expanded(
                child: _buildPill(
                  label: 'Post-Exercise',
                  icon: Icons.directions_run_rounded,
                  isSelected: isPostExercise,
                  onTap: () => onSelectionChanged(true),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Informative Context Box
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: PulseColors.surfaceDim,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isPostExercise
                      ? Icons.info_outline_rounded
                      : Icons.verified_user_outlined,
                  size: 16,
                  color: isPostExercise
                      ? PulseColors.riskElevated
                      : PulseColors.riskNormal,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isPostExercise
                        ? 'Recovery hysteresis active — elevated heart rate with falling slope is recognized as normal post-workout cooldown.'
                        : 'Resting state — vitals are strictly evaluated against your learned normal baseline distribution (mean ± 2 SD).',
                    style: PulseTypography.caption.copyWith(
                      fontSize: 12,
                      color: PulseColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPill({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        decoration: BoxDecoration(
          color: isSelected ? PulseColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected
                ? PulseColors.surfaceDark
                : PulseColors.borderSubtle,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : PulseColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: PulseTypography.caption.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                  color: isSelected ? Colors.white : PulseColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
