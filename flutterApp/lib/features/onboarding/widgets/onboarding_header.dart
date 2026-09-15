import 'package:flutter/material.dart';
import '../../../core/theme/pulse_colors.dart';

/// Cal AI-style onboarding top bar with back navigation and a slim progress line.
class OnboardingHeader extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final VoidCallback? onBack;

  const OnboardingHeader({
    super.key,
    required this.currentStep,
    this.totalSteps = 8,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final progress = ((currentStep + 1) / totalSteps).clamp(0.0, 1.0);
    final canGoBack = currentStep > 0 && onBack != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          // Back navigation button
          SizedBox(
            width: 44,
            height: 44,
            child: canGoBack
                ? IconButton(
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: PulseColors.textPrimary,
                      size: 24,
                    ),
                    splashRadius: 22,
                    onPressed: onBack,
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),

          // Slim Cal AI progress indicator bar
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 4,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: progress),
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return LinearProgressIndicator(
                      value: value,
                      backgroundColor: PulseColors.borderSubtle.withValues(alpha: 0.6),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        PulseColors.surfaceDark,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 52), // Balance width of back button
        ],
      ),
    );
  }
}
