import 'package:flutter/material.dart';
import '../../../core/constants/pulse_constants.dart';
import '../../../core/theme/pulse_colors.dart';
import '../../../core/theme/pulse_typography.dart';
import '../indicators/pulse_info_icon.dart';

/// Redesigned Emergency Alert & Early Warning Card.
///
/// Formatted according to medical-tech safety principles:
/// - Clear, calm urgency without sensationalism or diagnostic claims.
/// - Unambiguous, large-target YES/NO user check-in choices.
/// - Integrated supportive Bluey companion guidance.
/// - High-contrast visual hierarchy with real-time countdown.
class EmergencyAlertCard extends StatelessWidget {
  final int? secondsRemaining;
  final VoidCallback onSelectOk;
  final VoidCallback onSelectNeedHelp;
  final String? customSubtitle;

  const EmergencyAlertCard({
    super.key,
    this.secondsRemaining,
    required this.onSelectOk,
    required this.onSelectNeedHelp,
    this.customSubtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: PulseColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: PulseColors.emergencyRed.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: PulseColors.emergencyRed.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          PulseColors.cardShadow,
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Urgency Accent Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: PulseColors.riskCriticalBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              border: Border(
                bottom: BorderSide(
                  color: PulseColors.emergencyRed.withValues(alpha: 0.15),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: PulseColors.emergencyRed.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.sensors_rounded,
                    size: 16,
                    color: PulseColors.emergencyRed,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'EARLY-WARNING ALERT',
                    style: PulseTypography.caption.copyWith(
                      fontWeight: FontWeight.w800,
                      color: PulseColors.emergencyRed,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                if (secondsRemaining != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: PulseColors.emergencyRed.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: PulseColors.emergencyRed,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${secondsRemaining}s',
                          style: PulseTypography.caption.copyWith(
                            fontWeight: FontWeight.w700,
                            color: PulseColors.emergencyRed,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Supportive Bluey Mascot (Attentive & concerned, never panicked)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/mascot/bluey_error.png',
                      height: 56,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: PulseColors.surfaceDim,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: PulseColors.borderSubtle),
                        ),
                        child: Text(
                          "Something looks different from your usual pattern. How are you feeling?",
                          style: PulseTypography.caption.copyWith(
                            color: PulseColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Primary Headline
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      PulseConstants.checkInPromptTitle, // "Something has changed"
                      style: PulseTypography.headingLarge.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: PulseColors.emergencyRed,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(width: 6),
                    const PulseInfoIcon(
                      message:
                          "I noticed changes across multiple vital signals. Please take a moment to confirm how you are feeling.",
                      color: PulseColors.emergencyRed,
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Supporting Text (Non-diagnostic)
                Text(
                  customSubtitle ??
                      "We noticed changes in several of your vital signals compared to your personal baseline. Please check how you're feeling.",
                  style: PulseTypography.bodyRegular.copyWith(
                    fontSize: 14,
                    color: PulseColors.textSecondary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

                // Check-in Question
                Text(
                  PulseConstants.checkInQuestion, // "Are you feeling okay?"
                  style: PulseTypography.headingMedium.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: PulseColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 18),

                // Dual Action Confirmation Controls (Unambiguous YES / NO)
                Row(
                  children: [
                    // Action 1: YES, I'M OKAY
                    Expanded(
                      child: _buildChoiceButton(
                        label: "YES, I'M OKAY",
                        subtitle: "Signals are manageable",
                        icon: Icons.check_circle_rounded,
                        isPrimary: false,
                        accentColor: PulseColors.riskNormal,
                        onTap: onSelectOk,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Action 2: NO, I NEED HELP
                    Expanded(
                      child: _buildChoiceButton(
                        label: "NO, I NEED HELP",
                        subtitle: "I'M NOT FEELING WELL",
                        icon: Icons.emergency_rounded,
                        isPrimary: true,
                        accentColor: PulseColors.emergencyRed,
                        onTap: onSelectNeedHelp,
                      ),
                    ),
                  ],
                ),

                if (secondsRemaining != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    "If you don't respond within $secondsRemaining seconds, emergency assistance will be prepared automatically.",
                    style: PulseTypography.caption.copyWith(
                      fontSize: 11.5,
                      color: PulseColors.textTertiary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceButton({
    required String label,
    required String subtitle,
    required IconData icon,
    required bool isPrimary,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isPrimary ? accentColor : PulseColors.surface,
      borderRadius: BorderRadius.circular(16),
      elevation: isPrimary ? 2 : 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 88),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPrimary
                  ? accentColor
                  : accentColor.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 22,
                color: isPrimary ? Colors.white : accentColor,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: isPrimary ? Colors.white : accentColor,
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: isPrimary
                      ? Colors.white.withValues(alpha: 0.9)
                      : PulseColors.textSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
