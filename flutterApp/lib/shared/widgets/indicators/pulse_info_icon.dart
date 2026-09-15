import 'package:flutter/material.dart';
import '../../../core/theme/pulse_colors.dart';
import '../../../core/theme/pulse_typography.dart';

/// Interactive "ⓘ" icon that reveals contextual and informational copy on hover
/// (desktop/web) or tap (mobile).
///
/// Replaces permanent informational text containers with sleek, on-demand tooltips.
class PulseInfoIcon extends StatelessWidget {
  /// The contextual or regulatory message displayed in the tooltip overlay.
  final String message;

  /// Optional header title displayed above the message in the tooltip.
  final String? title;

  /// Size of the info icon.
  final double size;

  /// Tint color for the icon. Defaults to textTertiary.
  final Color? color;

  const PulseInfoIcon({
    super.key,
    required this.message,
    this.title,
    this.size = 18,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      richMessage: TextSpan(
        children: [
          if (title != null && title!.isNotEmpty) ...[
            TextSpan(
              text: '$title\n',
              style: PulseTypography.caption.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: PulseColors.textPrimary,
                height: 1.4,
              ),
            ),
          ],
          TextSpan(
            text: message,
            style: PulseTypography.caption.copyWith(
              fontSize: 12,
              height: 1.45,
              color: PulseColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      triggerMode: TooltipTriggerMode.tap,
      waitDuration: Duration.zero,
      showDuration: const Duration(seconds: 6),
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
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Icon(
            Icons.info_outline_rounded,
            size: size,
            color: color ?? PulseColors.textTertiary,
          ),
        ),
      ),
    );
  }
}
