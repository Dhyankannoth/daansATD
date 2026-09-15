import 'package:flutter/material.dart';
import '../../../core/theme/pulse_colors.dart';
import '../../../core/theme/pulse_typography.dart';

/// Radial countdown progress indicator designed for the 30-second Check-In watchdog.
class CountdownRing extends StatelessWidget {
  final int secondsRemaining;
  final int totalSeconds;
  final double size;
  final double strokeWidth;

  const CountdownRing({
    super.key,
    required this.secondsRemaining,
    this.totalSeconds = 30,
    this.size = 80,
    this.strokeWidth = 6,
  });

  double get progress => (secondsRemaining / totalSeconds).clamp(0.0, 1.0);

  Color get ringColor {
    if (secondsRemaining <= 8) return PulseColors.riskCritical;
    if (secondsRemaining <= 16) return PulseColors.riskHigh;
    return PulseColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background track
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: strokeWidth,
              color: PulseColors.divider,
            ),
          ),
          // Animated progress ring
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: progress, end: progress),
            duration: const Duration(milliseconds: 300),
            builder: (context, value, _) {
              return SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: value,
                  strokeWidth: strokeWidth,
                  strokeCap: StrokeCap.round,
                  color: ringColor,
                ),
              );
            },
          ),
          // Center number
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$secondsRemaining',
                style: PulseTypography.headingLarge.copyWith(
                  color: ringColor,
                  fontWeight: FontWeight.w700,
                  height: 1.0,
                ),
              ),
              Text(
                'sec',
                style: PulseTypography.caption.copyWith(
                  color: PulseColors.textTertiary,
                  fontSize: 10,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
