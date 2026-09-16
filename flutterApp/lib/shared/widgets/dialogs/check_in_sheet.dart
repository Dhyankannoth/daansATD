import 'package:flutter/material.dart';
import '../../../core/constants/pulse_constants.dart';
import '../../../core/theme/pulse_colors.dart';
import '../../../core/theme/pulse_typography.dart';
import '../../../services/emergency_alarm_service.dart';
import '../buttons/emergency_button.dart';
import '../buttons/secondary_button.dart';
import '../indicators/countdown_ring.dart';
import '../indicators/pulse_info_icon.dart';

/// Modal bottom sheet presented when multi-system deviation is detected.
///
/// Features:
/// - Audio alarm triggered on open, safely stopped on response or dismiss.
/// - Prompts the human-in-the-loop with the mandatory non-diagnostic language:
///   "Something has changed. We noticed changes across multiple vital signals. Are you feeling okay?"
/// - Unambiguous YES / NO choice controls.
class CheckInSheet extends StatefulWidget {
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
  State<CheckInSheet> createState() => _CheckInSheetState();
}

class _CheckInSheetState extends State<CheckInSheet> {
  @override
  void initState() {
    super.initState();
    // Start loud audio alarm on check-in open
    EmergencyAlarmService.instance.startAlarm();
  }

  @override
  void dispose() {
    // Guarantee alarm stops immediately when sheet closes
    EmergencyAlarmService.instance.stopAlarm();
    super.dispose();
  }

  void _handleOk() {
    EmergencyAlarmService.instance.stopAlarm();
    widget.onUserOk();
  }

  void _handleNotOk() {
    EmergencyAlarmService.instance.stopAlarm();
    widget.onUserNotOk();
  }

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
          const SizedBox(height: 14),

          // Bluey Thinking Companion (Attentive & supportive, not panicked)
          Image.asset(
            'assets/mascot/bluey_thinking.png',
            height: 64,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 12),

          // Countdown Watchdog Ring
          CountdownRing(
            secondsRemaining: widget.secondsRemaining,
            totalSeconds: PulseConstants.checkInTimeoutSeconds,
            size: 80,
          ),
          const SizedBox(height: 16),

          // Non-diagnostic Title & Body
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  PulseConstants.checkInPromptTitle,
                  textAlign: TextAlign.center,
                  style: PulseTypography.headingLarge.copyWith(
                    color: PulseColors.riskHigh,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const PulseInfoIcon(
                message:
                    'I noticed changes across multiple vital signals. Please take a moment to confirm how you are feeling.',
              ),
            ],
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
            'If you don\'t respond within ${widget.secondsRemaining} seconds, emergency assistance will be prepared automatically.',
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
            onPressed: _handleNotOk,
            isCritical: true,
          ),
          const SizedBox(height: 12),

          // Action 2: "YES, I'M OKAY" (Calm)
          SecondaryButton(
            label: "YES, I'M OKAY",
            icon: Icons.check_circle_outline_rounded,
            onPressed: _handleOk,
            textColor: PulseColors.riskNormal,
            borderColor: PulseColors.riskNormal.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }
}
