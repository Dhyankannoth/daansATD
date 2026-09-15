import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulseguard/core/theme/pulse_theme.dart';
import 'package:pulseguard/data/models/measurement_record.dart';
import 'package:pulseguard/data/repositories/history_repository.dart';
import 'package:pulseguard/features/measurement/measurement_results_screen.dart';
import 'package:pulseguard/pulseguard_engine.dart';
import 'package:pulseguard/services/pulse_engine_scope.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Measurement Flow & Results Tests', () {
    testWidgets(
      'MeasurementResultsScreen displays median summary metrics and baseline comparisons',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final historyRepo = HistoryRepository(prefs: prefs);
        final engine = PulseGuardEngine();
        await engine.loadDemoBaseline();

        const summary = ScanSummary(
          endReason: ScanEndReason.user,
          duration: Duration(seconds: 20),
          medianHr: 72,
          medianHrv: 54,
          medianRr: 14,
          maxLevel: RiskLevel.normal,
          alertOutcome: AlertOutcome.none,
          trustedFraction: 0.95,
        );

        final record = MeasurementRecord.fromScanSummary(
          summary: summary,
          activityState: ActivityStateKind.resting,
        );

        await tester.pumpWidget(
          PulseEngineScope(
            engine: engine,
            historyRepository: historyRepo,
            child: MaterialApp(
              theme: PulseTheme.lightTheme,
              home: MeasurementResultsScreen(summary: summary, record: record),
            ),
          ),
        );

        // Verify Header Status
        expect(find.text('Within your usual range'), findsOneWidget);
        expect(find.text('Measurement Summary'), findsOneWidget);

        // Verify Vitals
        expect(find.text('Heart Rate'), findsOneWidget);
        expect(find.text('72'), findsOneWidget);
        expect(find.text('HRV (RMSSD)'), findsOneWidget);
        expect(find.text('54'), findsOneWidget);
        expect(find.text('Respiration Rate'), findsOneWidget);
        expect(find.text('14'), findsOneWidget);

        // Verify Signal Quality
        expect(
          find.text('Signal Reliability: 95% trusted samples'),
          findsOneWidget,
        );

        // Verify Buttons
        expect(find.text('Done — Return to Home'), findsOneWidget);
        expect(find.text('Log Sensation / Note'), findsOneWidget);
      },
    );

    testWidgets(
      'Results screen shows abnormal notification when maxLevel is high',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final historyRepo = HistoryRepository(prefs: prefs);
        final engine = PulseGuardEngine();

        const summary = ScanSummary(
          endReason: ScanEndReason.timeout,
          duration: Duration(seconds: 20),
          medianHr: 128,
          medianHrv: 18,
          medianRr: 26,
          maxLevel: RiskLevel.high,
          alertOutcome: AlertOutcome.escalated,
          trustedFraction: 0.90,
        );

        final record = MeasurementRecord.fromScanSummary(
          summary: summary,
          activityState: ActivityStateKind.resting,
        );

        await tester.pumpWidget(
          PulseEngineScope(
            engine: engine,
            historyRepository: historyRepo,
            child: MaterialApp(
              theme: PulseTheme.lightTheme,
              home: MeasurementResultsScreen(summary: summary, record: record),
            ),
          ),
        );

        // Verify Non-diagnostic Abnormal Warning
        expect(find.text('Significant multi-system changes'), findsOneWidget);
        expect(find.text('Check Needed'), findsOneWidget);
      },
    );
  });
}
