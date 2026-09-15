import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulseguard/core/theme/pulse_theme.dart';
import 'package:pulseguard/data/repositories/history_repository.dart';
import 'package:pulseguard/features/history/history_screen.dart';
import 'package:pulseguard/features/measurement/camera_measurement_screen.dart';
import 'package:pulseguard/features/onboarding/onboarding_flow_screen.dart';
import 'package:pulseguard/pulseguard_engine.dart';
import 'package:pulseguard/services/pulse_engine_scope.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> stepPump(WidgetTester tester, [int times = 6]) async {
    for (int i = 0; i < times; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> tapButton(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await stepPump(tester);
  }

  Finder findAssetImage(String assetName) {
    return find.byWidgetPredicate((widget) {
      if (widget is Image && widget.image is AssetImage) {
        return (widget.image as AssetImage).assetName == assetName;
      }
      return false;
    });
  }

  group('Mascot Integration Tests', () {
    late PulseGuardEngine engine;
    late HistoryRepository historyRepo;
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      historyRepo = HistoryRepository(prefs: prefs);
      engine = PulseGuardEngine();
      await engine.initialize();
    });

    tearDown(() async {
      await engine.dispose();
    });

    void setupMobileViewport(WidgetTester tester) {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.resetPhysicalSize);
    }

    testWidgets('Onboarding flow displays all respective mascot illustrations', (tester) async {
      setupMobileViewport(tester);

      await tester.pumpWidget(
        PulseEngineScope(
          engine: engine,
          historyRepository: historyRepo,
          child: MaterialApp(
            theme: PulseTheme.lightTheme,
            home: const OnboardingFlowScreen(),
          ),
        ),
      );
      await stepPump(tester);

      // Screen 1: Welcome mascot
      expect(findAssetImage('assets/mascot/bluey_welcome.png'), findsOneWidget);
      await tapButton(tester, find.text('Get Started'));

      // Screen 2: Monitoring Concept mascot
      expect(findAssetImage('assets/mascot/bluey_checking.png'), findsOneWidget);
      await tapButton(tester, find.text('Continue'));

      // Screen 3: Profile Setup mascot
      expect(findAssetImage('assets/mascot/bluey_thinking.png'), findsOneWidget);
      await tapButton(tester, find.text('Continue'));

      // Screen 4: Emergency Contact
      await tapButton(tester, find.text('Continue'));

      // Screen 5: Permissions mascot
      expect(findAssetImage('assets/mascot/bluey_permision.png'), findsOneWidget);
      await tapButton(tester, find.text('Allow & Continue'));

      // Screen 6: Camera Tutorial mascot
      expect(findAssetImage('assets/mascot/bluey_scanning.png'), findsOneWidget);
      await tapButton(tester, find.text('Try It'));

      // Screen 7: Initial Baseline (scanning mascot inside central gauge)
      expect(findAssetImage('assets/mascot/bluey_scanning.png'), findsOneWidget);
      await tapButton(tester, find.text('Skip Baseline for Now'));

      // Screen 8: Baseline Complete mascot
      expect(findAssetImage('assets/mascot/bluey_excited.png'), findsOneWidget);
    });

    testWidgets('History screen renders bluey_emptyState mascot when empty', (tester) async {
      setupMobileViewport(tester);

      await tester.pumpWidget(
        PulseEngineScope(
          engine: engine,
          historyRepository: historyRepo,
          child: MaterialApp(
            theme: PulseTheme.lightTheme,
            home: const HistoryScreen(),
          ),
        ),
      );
      await stepPump(tester);

      expect(findAssetImage('assets/mascot/bluey_emptyState.png'), findsOneWidget);
    });
  });
}
