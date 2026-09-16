import 'package:flutter/material.dart';
import '../../../shared/widgets/indicators/pulse_info_icon.dart';

/// Legacy alias for [PulseInfoIcon] preserved for backwards compatibility with onboarding screens.
class OnboardingInfoIcon extends StatelessWidget {
  final String message;
  final double iconSize;

  const OnboardingInfoIcon({
    super.key,
    required this.message,
    this.iconSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    return PulseInfoIcon(
      message: message,
      size: iconSize,
    );
  }
}
