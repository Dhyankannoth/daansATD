import 'package:flutter/material.dart';
import '../../../../core/theme/pulse_colors.dart';
import '../../../../core/theme/pulse_typography.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';

/// Screen 2 — How Monitoring Works: Explain personal baseline monitoring.
class MonitoringConceptScreen extends StatelessWidget {
  final VoidCallback onContinue;

  const MonitoringConceptScreen({
    super.key,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight > 50 ? constraints.maxHeight - 24 : 500,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),

                    // Mascot: Bluey Checking
                    Center(
                      child: Image.asset(
                        'assets/mascot/bluey_checking.png',
                        height: 180,
                        fit: BoxFit.contain,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Headline
                    Text(
                      "I learn what's normal for you.",
                      style: PulseTypography.headingLarge.copyWith(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                        height: 1.25,
                        color: PulseColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Supporting Text
                    Text(
                      "Everyone's body is different. I build a personal baseline so changes can be compared against your usual patterns.",
                      style: PulseTypography.bodyRegular.copyWith(
                        fontSize: 14,
                        height: 1.5,
                        color: PulseColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 3 Concise Explanatory Feature Rows (clean, frameless presentation)
                    _buildConceptRow(
                      icon: Icons.auto_awesome_rounded,
                      iconBg: PulseColors.tintEmeraldBg,
                      iconColor: PulseColors.tintEmeraldIcon,
                      title: 'Tailored to Your Biology',
                      description:
                          'A static threshold causes false alerts. Your baseline is derived specifically from your physiological signals.',
                    ),
                    const SizedBox(height: 12),

                    _buildConceptRow(
                      icon: Icons.directions_run_rounded,
                      iconBg: PulseColors.tintAmberBg,
                      iconColor: PulseColors.tintAmberIcon,
                      title: 'Smart Activity Awareness',
                      description:
                          'Elevated heart rate during exercise is expected. Recovery hysteresis prevents unnecessary alarms during cooldown.',
                    ),
                    const SizedBox(height: 12),

                    _buildConceptRow(
                      icon: Icons.health_and_safety_outlined,
                      iconBg: PulseColors.tintBlueBg,
                      iconColor: PulseColors.tintBlueIcon,
                      title: 'Gentle Check-In First',
                      description:
                          'If multi-system deviations are observed, the app prompts you to check how you feel before escalating.',
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // CTA Button
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: PrimaryButton(
                    label: 'Continue',
                    onPressed: onContinue,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildConceptRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Icon(icon, size: 22, color: iconColor),
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
                    fontSize: 14,
                    color: PulseColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: PulseTypography.caption.copyWith(
                    fontSize: 12,
                    height: 1.4,
                    color: PulseColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
