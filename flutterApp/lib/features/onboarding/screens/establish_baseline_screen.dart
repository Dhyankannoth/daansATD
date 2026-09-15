import 'package:flutter/material.dart';
import '../../../../camera_finger_instruction.dart';
import '../../../../core/theme/pulse_colors.dart';
import '../../../../core/theme/pulse_typography.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';

/// Screen 7 — Establish Baseline: Transition and demonstration screen
/// between the camera tutorial and the actual baseline physiological measurement.
///
/// Features:
/// - Prominent phone + finger animation demonstration (covering rear camera & flash)
/// - Clear distinction: Demonstration / Tutorial -> Actual Measurement
/// - Horizontal progress indicator communicating preparation & expected 15-20s duration
/// - Clean typography and primary CTA to proceed to measurement
class EstablishBaselineScreen extends StatefulWidget {
  final VoidCallback onStartMeasurement;

  const EstablishBaselineScreen({
    super.key,
    required this.onStartMeasurement,
  });

  @override
  State<EstablishBaselineScreen> createState() =>
      _EstablishBaselineScreenState();
}

class _EstablishBaselineScreenState extends State<EstablishBaselineScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progressCtrl;

  @override
  void initState() {
    super.initState();
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    super.dispose();
  }

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
                    const SizedBox(height: 4),

                    // Demonstration Pill Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10.0,
                        vertical: 4.0,
                      ),
                      decoration: BoxDecoration(
                        color: PulseColors.surfaceDim,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: PulseColors.divider,
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: PulseColors.tintEmeraldIcon,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Demonstration',
                            style: PulseTypography.caption.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: PulseColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

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

                    const SizedBox(height: 8),

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

                    const SizedBox(height: 16),

                    // Phone + Finger Animation Demonstration (Primary Visual Focus)
                    const Center(
                      child: CameraFingerInstruction(
                        height: 230,
                        showText: false,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Conceptual Layout:
                    // Keep your finger still
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

                    const SizedBox(height: 10),

                    // Horizontal Progress Indicator (Demonstration / Preparation Timer)
                    AnimatedBuilder(
                      animation: _progressCtrl,
                      builder: (context, _) {
                        return Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: SizedBox(
                                height: 6,
                                width: double.infinity,
                                child: LinearProgressIndicator(
                                  value: _progressCtrl.value,
                                  backgroundColor: PulseColors.borderSubtle
                                      .withValues(alpha: 0.6),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                    PulseColors.surfaceDark,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Establishing your baseline',
                                    style: PulseTypography.caption.copyWith(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: PulseColors.textTertiary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '15–20 sec',
                                  style: PulseTypography.caption.copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: PulseColors.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
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
                    onPressed: widget.onStartMeasurement,
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
