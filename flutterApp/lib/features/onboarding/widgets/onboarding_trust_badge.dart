import 'package:flutter/material.dart';
import '../../../core/theme/pulse_colors.dart';
import '../../../core/theme/pulse_typography.dart';

/// Cal AI-style privacy and trust assurance card.
class OnboardingTrustBadge extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const OnboardingTrustBadge({
    super.key,
    this.title = 'Your privacy and security matter to us.',
    this.message =
        'We promise to always keep your personal information private, encrypted, and stored safely on your device.',
    this.icon = Icons.lock_outline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: PulseColors.surfaceDim.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PulseColors.divider, width: 1.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: PulseColors.textPrimary),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: PulseTypography.bodyMedium.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: PulseColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: PulseTypography.caption.copyWith(
              fontSize: 11,
              height: 1.4,
              color: PulseColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
