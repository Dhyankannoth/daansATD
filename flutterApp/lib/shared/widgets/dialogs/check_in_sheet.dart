import 'package:flutter/material.dart';
import '../../../core/constants/pulse_constants.dart';
import '../../../core/theme/pulse_colors.dart';
import '../../../core/theme/pulse_typography.dart';
import '../buttons/emergency_button.dart';
import '../buttons/secondary_button.dart';
import '../indicators/countdown_ring.dart';

/// Modal bottom sheet presented when multi-system deviation is detected.
///
/// Prompts the human-in-the-loop with the mandatory non-diagnostic language:
/// "Something has changed. We noticed changes across multiple vital signals. Are you feeling okay?"
class CheckInSheet extends StatelessWidget {
  final int secondsRemaining;
  final VoidCallback onUserOk;
  final VoidCallback onUserNotOk;

  const CheckInSheet({
    super.key,
    required this.secondsRemaining,
    required this.onUserOk,
    required this.onUserNotOk,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(
        color: PulseColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: PulseColors.borderSubtle,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Countdown Watchdog Ring
          CountdownRing(
            secondsRemaining: secondsRemaining,
            totalSeconds: PulseConstants.checkInTimeoutSeconds,
            size: 88,
          ),
          const SizedBox(height: 18),

          // Non-diagnostic Title & Body
          Text(
            PulseConstants.checkInPromptTitle,
            textAlign: TextAlign.center,
            style: PulseTypography.headingLarge.copyWith(
              color: PulseColors.riskHigh,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            PulseConstants.checkInPromptSubtitle,
            textAlign: TextAlign.center,
            style: PulseTypography.bodyRegular.copyWith(
              color: PulseColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            PulseConstants.checkInQuestion,
            textAlign: TextAlign.center,
            style: PulseTypography.headingMedium.copyWith(
              color: PulseColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            'If you don\'t respond within $secondsRemaining seconds, emergency assistance will be prepared automatically.',
            textAlign: TextAlign.center,
            style: PulseTypography.caption.copyWith(
              color: PulseColors.textTertiary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 24),

          // Action 1: "I'M NOT FEELING WELL" (Urgent)
          EmergencyButton(
            label: "I'M NOT FEELING WELL",
            subtitle: "Proceeds directly to emergency assistance",
            icon: Icons.emergency_rounded,
            onPressed: onUserNotOk,
            isCritical: true,
          ),
          const SizedBox(height: 12),

          // Action 2: "YES, I'M OKAY" (Calm)
          SecondaryButton(
            label: "YES, I'M OKAY",
            icon: Icons.check_circle_outline_rounded,
            onPressed: onUserOk,
            textColor: PulseColors.riskNormal,
            borderColor: PulseColors.riskNormal.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }
}
