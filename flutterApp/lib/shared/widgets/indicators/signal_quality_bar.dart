import 'package:flutter/material.dart';
import '../../../core/theme/pulse_colors.dart';
import '../../../core/theme/pulse_typography.dart';

/// Signal quality meter displaying 3 segmented bars with an accompanying status label.
class SignalQualityBar extends StatelessWidget {
  final double quality; // 0.0 to 1.0
  final bool hasFinger;
  final bool showLabel;

  const SignalQualityBar({
    super.key,
    required this.quality,
    this.hasFinger = true,
    this.showLabel = true,
  });

  // Tier boundaries match assets/config/thresholds.json's quality thresholds
  // (display_min=0.4, trusted=0.6) so "Strong signal" on screen means the
  // same thing as "this tick counts as trusted" in the engine — keep these
  // in sync if thresholds.json's quality values ever change.
  int get level {
    if (!hasFinger || quality <= 0.0) return 0;
    if (quality < 0.4) return 1;
    if (quality < 0.6) return 2;
    return 3;
  }

  String get label {
    if (!hasFinger) return 'No finger';
    if (quality <= 0.0) return 'Searching';
    if (quality < 0.4) return 'Low signal';
    if (quality < 0.6) return 'Adjusting';
    return 'Strong signal';
  }

  Color get barColor {
    if (level == 0) return PulseColors.borderSubtle;
    if (level == 1) return PulseColors.riskElevated;
    if (level == 2) return PulseColors.riskMonitoring;
    return PulseColors.riskNormal;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildBar(height: 8, active: level >= 1),
            const SizedBox(width: 3),
            _buildBar(height: 12, active: level >= 2),
            const SizedBox(width: 3),
            _buildBar(height: 16, active: level >= 3),
          ],
        ),
        if (showLabel) ...[
          const SizedBox(width: 8),
          Text(
            label,
            style: PulseTypography.caption.copyWith(
              color: barColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBar({required double height, required bool active}) {
    return Container(
      width: 4,
      height: height,
      decoration: BoxDecoration(
        color: active ? barColor : PulseColors.borderSubtle,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
