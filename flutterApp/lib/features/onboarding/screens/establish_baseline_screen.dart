import 'package:flutter/material.dart';
import '../../../../camera_finger_instruction.dart';
import '../../../../core/theme/pulse_colors.dart';
import '../../../../core/theme/pulse_typography.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';

/// Screen 7 — Establish Baseline: Transition and demonstration screen
/// showing what the user should do before starting the physiological measurement.
class EstablishBaselineScreen extends StatelessWidget {
  final VoidCallback onStartMeasurement;

  const EstablishBaselineScreen({
    super.key,
    required this.onStartMeasurement,
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
              minHeight:
                  constraints.maxHeight > 50 ? constraints.maxHeight - 24 : 500,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // Heading
                    Text(
                      "Let's establish your baseline.",
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
                      "We'll take your first measurement to understand what's normal for you. "
                      "Place your fingertip over the rear camera and flash, and keep it still while we measure.",
                      style: PulseTypography.bodyRegular.copyWith(
                        fontSize: 14,
                        height: 1.5,
                        color: PulseColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Phone + Finger Animation Demonstration (Primary Visual Focus - enlarged)
                    const Center(
                      child: CameraFingerInstruction(
                        height: 280,
                        showText: false,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Instruction note
                    Center(
                      child: Text(
                        'Keep your finger still',
                        style: PulseTypography.bodyMedium.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: PulseColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // CTA Button: Start Measurement
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: PrimaryButton(
                    label: 'Start Measurement',
                    icon: Icons.favorite_rounded,
                    onPressed: onStartMeasurement,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
