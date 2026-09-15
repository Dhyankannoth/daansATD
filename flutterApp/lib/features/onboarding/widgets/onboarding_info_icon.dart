import 'package:flutter/material.dart';
import '../../../core/theme/pulse_colors.dart';
import '../../../core/theme/pulse_typography.dart';

/// A compact "ⓘ" icon that reveals contextual information on tap (mobile)
/// or hover (desktop). Tapping elsewhere or hovering away dismisses it.
///
/// Used across onboarding screens to replace permanent informational containers
/// with on-demand contextual tooltips.
class OnboardingInfoIcon extends StatelessWidget {
  /// The informational text displayed in the tooltip.
  final String message;

  /// Size of the "ⓘ" trigger icon.
  final double iconSize;

  const OnboardingInfoIcon({
    super.key,
    required this.message,
    this.iconSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      triggerMode: TooltipTriggerMode.tap,
      waitDuration: Duration.zero,
      showDuration: const Duration(seconds: 5),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: PulseColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: PulseColors.borderSubtle,
          width: 1.0,
        ),
        boxShadow: const [PulseColors.elevatedModalShadow],
      ),
      textStyle: PulseTypography.caption.copyWith(
        fontSize: 12,
        height: 1.45,
        color: PulseColors.textSecondary,
        fontWeight: FontWeight.w500,
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Icon(
            Icons.info_outline_rounded,
            size: iconSize,
            color: PulseColors.textTertiary,
          ),
        ),
      ),
    );
  }
}
