import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulseguard/core/constants/pulse_constants.dart';
import 'package:pulseguard/core/theme/pulse_theme.dart';
import 'package:pulseguard/data/repositories/history_repository.dart';
import 'package:pulseguard/features/app_shell/app_shell_screen.dart';
import 'package:pulseguard/pulseguard_engine.dart';
import 'package:pulseguard/services/pulse_engine_scope.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('AppShell tab navigation switches between all 4 core screens', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final historyRepo = HistoryRepository(prefs: prefs);
    final engine = PulseGuardEngine();
    await engine.initialize();

    await tester.pumpWidget(
      PulseEngineScope(
        engine: engine,
        historyRepository: historyRepo,
        child: MaterialApp(
          theme: PulseTheme.lightTheme,
          home: const AppShellScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Home Tab (Default)
    expect(find.text(PulseConstants.appTitle), findsOneWidget);
    expect(find.text('Take Spot Measurement (20s)'), findsOneWidget);
    expect(find.text('Heart Rate • BPM'), findsOneWidget);

    // 2. Switch to Baseline Tab
    await tester.tap(find.text('Baseline'));
    await tester.pumpAndSettle();

    expect(find.text('Personal Baseline'), findsOneWidget);
    expect(find.text('Why Personal Baselines Matter'), findsOneWidget);
    expect(find.text('Start 60-Second Calibration'), findsOneWidget);

    // 3. Switch to History Tab
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    expect(find.text('Measurement History'), findsOneWidget);
    expect(find.text('All (0)'), findsOneWidget);
    expect(find.text('Deviations'), findsOneWidget);

    // 4. Switch to Settings Tab
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Settings & Safety'), findsOneWidget);
    expect(find.text('Manage Emergency Contact'), findsOneWidget);
    expect(find.text('CLINICAL & REGULATORY NOTICE'), findsOneWidget);

    // 5. Switch back to Home Tab
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    expect(find.text('Take Spot Measurement (20s)'), findsOneWidget);
  });
}
