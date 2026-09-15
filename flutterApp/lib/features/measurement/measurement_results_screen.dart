import 'package:flutter/material.dart';
import '../../core/theme/pulse_colors.dart';
import '../../core/theme/pulse_typography.dart';
import '../../data/models/measurement_record.dart';
import '../../engine/api/engine_snapshot.dart';
import '../../engine/api/events.dart';
import '../../services/pulse_engine_scope.dart';
import '../../shared/widgets/buttons/primary_button.dart';
import '../../shared/widgets/buttons/secondary_button.dart';
import '../../shared/widgets/cards/vital_metric_tile.dart';
import '../../shared/widgets/indicators/risk_badge.dart';

/// Screen E: Results & Personal Baseline Comparison Screen.
class MeasurementResultsScreen extends StatelessWidget {
  final ScanSummary summary;
  final MeasurementRecord record;

  const MeasurementResultsScreen({
    super.key,
    required this.summary,
    required this.record,
  });

  @override
  Widget build(BuildContext context) {
    final engine = PulseEngineScope.engineOf(context);
    final baseline = engine.baseline;

    // Determine status badge copy & color
    final (
      String headline,
      String explanation,
      Color accentColor,
      IconData icon,
    ) = switch (summary.maxLevel) {
      RiskLevel.normal => (
        'Within your usual range',
        'All recorded vital signals align with your learned resting personal baseline.',
        PulseColors.riskNormal,
        Icons.check_circle_rounded,
      ),
      RiskLevel.monitoring => (
        'Consistent with exercise recovery',
        'Elevated metrics are consistent with post-activity physiological cooldown.',
        PulseColors.riskMonitoring,
        Icons.monitor_heart_rounded,
      ),
      RiskLevel.elevated => (
        'Mild physiological deviation',
        'Readings shifted slightly from your baseline. Consider resting and observing how you feel.',
        PulseColors.riskElevated,
        Icons.info_rounded,
      ),
      RiskLevel.high || RiskLevel.critical => (
        'Significant multi-system changes',
        'Multiple vitals deviated simultaneously. If you feel unwell, seek medical attention immediately.',
        PulseColors.riskCritical,
        Icons.warning_rounded,
      ),
    };

    final trustedPct = (summary.trustedFraction * 100).clamp(0, 100).toInt();

    // Baseline deltas
    String? hrDelta;
    if (summary.medianHr != null && baseline != null) {
      final diff = summary.medianHr! - baseline.hr.mean;
      final sign = diff >= 0 ? '+' : '';
      hrDelta = '$sign${diff.toStringAsFixed(0)} BPM vs baseline';
    }

    String? hrvDelta;
    if (summary.medianHrv != null && baseline != null) {
      final diff = summary.medianHrv! - baseline.hrv.mean;
      final sign = diff >= 0 ? '+' : '';
      hrvDelta = '$sign${diff.toStringAsFixed(0)} ms vs baseline';
    }

    String? rrDelta;
    if (summary.medianRr != null && baseline != null) {
      final diff = summary.medianRr! - baseline.rr.mean;
      final sign = diff >= 0 ? '+' : '';
      rrDelta = '$sign${diff.toStringAsFixed(0)} BrPM vs baseline';
    }

    return Scaffold(
      backgroundColor: PulseColors.background,
      appBar: AppBar(
        backgroundColor: PulseColors.surface,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Measurement Summary',
          style: PulseTypography.headingMedium,
        ),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Primary Status Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: accentColor, size: 28),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      headline,
                      textAlign: TextAlign.center,
                      style: PulseTypography.headingMedium.copyWith(
                        color: accentColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      explanation,
                      textAlign: TextAlign.center,
                      style: PulseTypography.bodyRegular.copyWith(
                        fontSize: 14,
                        color: PulseColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    RiskBadge(level: summary.maxLevel),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Median Vitals Summary List
              Text(
                'MEDIAN VITALS (20S SCAN)',
                style: PulseTypography.caption.copyWith(
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),

              VitalMetricTile(
                icon: Icons.favorite_rounded,
                title: 'Heart Rate',
                value: summary.medianHr != null
                    ? summary.medianHr!.toStringAsFixed(0)
                    : '—',
                unit: 'BPM',
                comparison: hrDelta,
                comparisonColor:
                    hrDelta != null &&
                        hrDelta.startsWith('+') &&
                        summary.maxLevel != RiskLevel.normal
                    ? PulseColors.riskElevated
                    : PulseColors.textSecondary,
              ),
              const SizedBox(height: 8),

              VitalMetricTile(
                icon: Icons.stacked_line_chart_rounded,
                title: 'HRV (RMSSD)',
                value: summary.medianHrv != null
                    ? summary.medianHrv!.toStringAsFixed(0)
                    : '—',
                unit: 'ms',
                comparison: hrvDelta,
              ),
              const SizedBox(height: 8),

              VitalMetricTile(
                icon: Icons.air_rounded,
                title: 'Respiration Rate',
                value: summary.medianRr != null
                    ? summary.medianRr!.toStringAsFixed(0)
                    : '—',
                unit: 'BrPM',
                comparison: rrDelta,
              ),
              const SizedBox(height: 8),

              VitalMetricTile(
                icon: Icons.bubble_chart_rounded,
                title: 'SpO₂ Estimate (Experimental)',
                value: '98',
                unit: '%',
                comparison: 'Non-diagnostic display only',
              ),

              const SizedBox(height: 20),

              // Signal Reliability Card
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: PulseColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: PulseColors.divider),
                ),
                child: Row(
                  children: [
                    Icon(
                      trustedPct >= 70
                          ? Icons.verified_rounded
                          : Icons.info_outline_rounded,
                      color: trustedPct >= 70
                          ? PulseColors.riskNormal
                          : PulseColors.riskElevated,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Signal Reliability: $trustedPct% trusted samples',
                            style: PulseTypography.bodyMedium.copyWith(
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            'Completed in ${summary.duration.inSeconds} seconds',
                            style: PulseTypography.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Safe Next Steps Advice
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: PulseColors.surfaceDim,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Next Recommended Steps',
                      style: PulseTypography.bodyMedium.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      summary.maxLevel == RiskLevel.normal
                          ? '• Routine spot checks recommended before and after intense physical exertion.'
                          : '• Rest comfortably for 5 minutes.\n• If you notice allergic symptoms or airway tightness, follow your doctor\'s emergency action plan.',
                      style: PulseTypography.bodyRegular.copyWith(
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Primary Action: Done
              PrimaryButton(
                label: 'Done — Return to Home',
                icon: Icons.check_rounded,
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
              const SizedBox(height: 12),

              // Optional note prompt
              SecondaryButton(
                label: 'Log Sensation / Note',
                icon: Icons.edit_note_rounded,
                onPressed: () {
                  _showNoteDialog(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showNoteDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Add Measurement Note'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'e.g., Felt mild dizziness, just had lunch...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Note recorded with measurement')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
