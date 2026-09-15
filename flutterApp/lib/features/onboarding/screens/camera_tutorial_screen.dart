import 'package:flutter/material.dart';
import '../../../../camera_finger_instruction.dart';
import '../../../../core/theme/pulse_colors.dart';
import '../../../../core/theme/pulse_typography.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';

/// Screen 6 — Camera Measurement Tutorial: Teach camera-based physiological measurement.
/// Animation: Guide (Realistic hand placing fingertip over the rear camera and holding).
class CameraTutorialScreen extends StatelessWidget {
  final VoidCallback onTryIt;

  const CameraTutorialScreen({
    super.key,
    required this.onTryIt,
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

                    // Mascot: Bluey Scanning
                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  PulseColors.tintEmeraldBg.withValues(alpha: 0.8),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                          Image.asset(
                            'assets/mascot/bluey_scanning.png',
                            height: 115,
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Headline
                    Text(
                      'Measure your vitals with your camera.',
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
                      'Place your fingertip over the rear camera and flash. Keep it still while we measure.',
                      style: PulseTypography.bodyRegular.copyWith(
                        fontSize: 14,
                        height: 1.5,
                        color: PulseColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Guide Animation: Phone + Finger Placement
                    Container(
                      height: 270,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: PulseColors.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: PulseColors.divider, width: 1.2),
                        boxShadow: const [PulseColors.cardShadow],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: const CameraFingerInstruction(
                        height: 260,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Two Guidance Bullet Cards
                    _buildGuideTip(
                      icon: Icons.touch_app_rounded,
                      title: 'Use light, gentle pressure',
                      description:
                          'Pressing too hard blanches the capillaries and blocks blood flow pulsation.',
                    ),
                    const SizedBox(height: 10),

                    _buildGuideTip(
                      icon: Icons.flash_on_rounded,
                      title: 'Cover both camera lens and flash',
                      description:
                          'The flash illuminates microvascular blood pulsing through your fingertip.',
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // CTA Button
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: PrimaryButton(
                    label: 'Try It',
                    icon: Icons.camera_alt_rounded,
                    onPressed: onTryIt,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGuideTip({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: PulseColors.surfaceDim.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PulseColors.divider, width: 1.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: PulseColors.textPrimary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: PulseTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: PulseColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: PulseTypography.caption.copyWith(
                    fontSize: 11,
                    height: 1.35,
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
