import 'package:flutter/material.dart';
import '../../../core/theme/pulse_colors.dart';
import '../../../core/theme/pulse_typography.dart';
import '../../../engine/api/events.dart';

/// Triple-encoded visual display of current system risk (Icon + Text + Background Color).
class RiskBadge extends StatelessWidget {
  final RiskLevel level;
  final String? customLabel;
  final bool compact;

  const RiskBadge({
    super.key,
    required this.level,
    this.customLabel,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = PulseColors.forRisk(level);
    final bg = PulseColors.backgroundForRisk(level);

    final (IconData icon, String label) = switch (level) {
      RiskLevel.normal => (Icons.check_circle_rounded, 'Normal'),
      RiskLevel.monitoring => (Icons.monitor_heart_rounded, 'Monitoring'),
      RiskLevel.elevated => (Icons.info_rounded, 'Elevated'),
      RiskLevel.high => (Icons.warning_amber_rounded, 'Check Needed'),
      RiskLevel.critical => (Icons.shield_rounded, 'Attention Required'),
    };

    final text = customLabel ?? label;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 14 : 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: PulseTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: compact ? 11 : 12,
            ),
          ),
        ],
      ),
    );
  }
}
