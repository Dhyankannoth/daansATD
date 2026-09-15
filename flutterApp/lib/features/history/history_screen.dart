import 'package:flutter/material.dart';
import '../../core/theme/pulse_colors.dart';
import '../../core/theme/pulse_typography.dart';
import '../../data/models/measurement_record.dart';
import '../../engine/api/events.dart';
import '../../services/pulse_engine_scope.dart';
import '../../shared/widgets/buttons/primary_button.dart';
import '../../shared/widgets/buttons/secondary_button.dart';
import '../../shared/widgets/cards/vital_metric_tile.dart';
import '../../shared/widgets/indicators/risk_badge.dart';
import '../measurement/camera_measurement_screen.dart';

enum HistoryFilter { all, deviations, normal }

/// Screen I: History & Trends Screen.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  HistoryFilter _filter = HistoryFilter.all;

  @override
  Widget build(BuildContext context) {
    final repo = PulseEngineScope.historyOf(context);
    final allRecords = repo.loadRecords();

    final filteredRecords = allRecords.where((r) {
      if (_filter == HistoryFilter.deviations) {
        return r.maxRiskLevel == RiskLevel.high ||
            r.maxRiskLevel == RiskLevel.critical ||
            r.maxRiskLevel == RiskLevel.elevated;
      }
      if (_filter == HistoryFilter.normal) {
        return r.maxRiskLevel == RiskLevel.normal ||
            r.maxRiskLevel == RiskLevel.monitoring;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: PulseColors.background,
      appBar: AppBar(
        backgroundColor: PulseColors.surface,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Measurement History',
          style: PulseTypography.headingMedium,
        ),
        actions: [
          if (allRecords.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              tooltip: 'Clear History',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear Measurement History?'),
                    content: const Text(
                      'This will delete all stored spot measurement records.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await repo.clearRecords();
                  setState(() {});
                }
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 12.0,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildFilterChip(
                      'All (${allRecords.length})',
                      HistoryFilter.all,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip('Deviations', HistoryFilter.deviations),
                    const SizedBox(width: 8),
                    _buildFilterChip('In Range', HistoryFilter.normal),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),

            // Content List or Empty State
            Expanded(
              child: filteredRecords.isEmpty
                  ? _buildEmptyState(context, allRecords.isEmpty)
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 16.0,
                      ),
                      itemCount: filteredRecords.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final record = filteredRecords[index];
                        return _buildRecordCard(record);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, HistoryFilter filter) {
    final selected = _filter == filter;
    return GestureDetector(
      onTap: () => setState(() => _filter = filter),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? PulseColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected ? PulseColors.surfaceDark : PulseColors.borderSubtle,
            width: 1.2,
          ),
          boxShadow: selected ? const [PulseColors.cardShadow] : null,
        ),
        child: Text(
          label,
          style: PulseTypography.caption.copyWith(
            color: selected ? Colors.white : PulseColors.textSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildRecordCard(MeasurementRecord record) {
    final dt = DateTime.fromMillisecondsSinceEpoch(record.timestamp);
    final dateStr =
        '${dt.month}/${dt.day}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    final trustedPct = (record.trustedFraction * 100).toInt();

    return Container(
      decoration: BoxDecoration(
        color: PulseColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PulseColors.divider),
        boxShadow: const [PulseColors.cardShadow],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showDetailSheet(record),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dateStr,
                      style: PulseTypography.caption.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    RiskBadge(level: record.maxRiskLevel, compact: true),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMetricSnippet(
                      'HR',
                      record.medianHr?.toStringAsFixed(0) ?? '—',
                      'BPM',
                    ),
                    _buildMetricSnippet(
                      'HRV',
                      record.medianHrv?.toStringAsFixed(0) ?? '—',
                      'ms',
                    ),
                    _buildMetricSnippet(
                      'RR',
                      record.medianRr?.toStringAsFixed(0) ?? '—',
                      'BrPM',
                    ),
                    _buildMetricSnippet(
                      'SpO₂',
                      record.spo2?.toStringAsFixed(0) ?? '98',
                      '%',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Duration: ${record.durationSeconds}s • Signal reliability: $trustedPct%',
                  style: PulseTypography.caption.copyWith(
                    color: PulseColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricSnippet(String label, String value, String unit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: PulseTypography.caption.copyWith(fontSize: 11)),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: PulseTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: PulseColors.textPrimary,
              ),
            ),
            const SizedBox(width: 2),
            Text(unit, style: PulseTypography.caption.copyWith(fontSize: 10)),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, bool hasNoHistory) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/mascot/bluey_emptyState.png',
              height: 180,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            Text(
              hasNoHistory
                  ? 'No Measurements Recorded Yet'
                  : 'No Matching Measurements',
              style: PulseTypography.headingMedium,
            ),
            const SizedBox(height: 8),
            Text(
              hasNoHistory
                  ? 'Take your first 20-second spot measurement to start tracking your vital trends.'
                  : 'Try selecting another filter chip above to view past spot scans.',
              textAlign: TextAlign.center,
              style: PulseTypography.bodyRegular.copyWith(
                color: PulseColors.textSecondary,
              ),
            ),
            if (hasNoHistory) ...[
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Take First Measurement',
                icon: Icons.camera_alt_rounded,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const CameraMeasurementScreen(),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDetailSheet(MeasurementRecord record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: PulseColors.surface,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Session Details',
                  style: PulseTypography.headingMedium,
                ),
                RiskBadge(level: record.maxRiskLevel),
              ],
            ),
            const SizedBox(height: 16),
            VitalMetricTile(
              icon: Icons.favorite_rounded,
              title: 'Heart Rate',
              value: record.medianHr?.toStringAsFixed(0) ?? '—',
              unit: 'BPM',
            ),
            const SizedBox(height: 8),
            VitalMetricTile(
              icon: Icons.stacked_line_chart_rounded,
              title: 'HRV (RMSSD)',
              value: record.medianHrv?.toStringAsFixed(0) ?? '—',
              unit: 'ms',
            ),
            const SizedBox(height: 8),
            VitalMetricTile(
              icon: Icons.air_rounded,
              title: 'Respiration Rate',
              value: record.medianRr?.toStringAsFixed(0) ?? '—',
              unit: 'BrPM',
            ),
            if (record.notes != null && record.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'USER NOTES',
                style: PulseTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(record.notes!, style: PulseTypography.bodyRegular),
            ],
            const SizedBox(height: 24),
            SecondaryButton(
              label: 'Close',
              onPressed: () => Navigator.of(sheetContext).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
