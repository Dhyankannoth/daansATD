import 'package:flutter/material.dart';
import '../../../core/theme/pulse_colors.dart';
import '../../../core/theme/pulse_typography.dart';

/// Cal AI-style secondary pill button with subtle outline and overflow-safe layout.
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool fullWidth;
  final Color? borderColor;
  final Color? textColor;

  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.fullWidth = true,
    this.borderColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorder = borderColor ?? PulseColors.borderSubtle;
    final effectiveFg = textColor ?? PulseColors.textPrimary;

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: effectiveFg),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: PulseTypography.button.copyWith(
              color: effectiveFg,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );

    final button = SizedBox(
      height: 50,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: effectiveFg,
          side: BorderSide(color: effectiveBorder, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        onPressed: onPressed,
        child: content,
      ),
    );

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}
