import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulseguard/core/theme/pulse_theme.dart';
import 'package:pulseguard/data/repositories/history_repository.dart';
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

  group('Onboarding Flow Full Navigation Tests', () {
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

    Widget createTestApp({VoidCallback? onComplete}) {
      return PulseEngineScope(
        engine: engine,
        historyRepository: historyRepo,
        child: MaterialApp(
          theme: PulseTheme.lightTheme,
          home: OnboardingFlowScreen(onComplete: onComplete),
        ),
      );
    }

    void setupMobileViewport(WidgetTester tester) {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.resetPhysicalSize);
    }

    testWidgets('Screen 1 (Welcome) renders trust elements and navigates to Screen 2', (tester) async {
      setupMobileViewport(tester);
      await tester.pumpWidget(createTestApp());
      await stepPump(tester);

      // Verify Screen 1 content
      expect(find.text('Know when something changes.'), findsOneWidget);
      expect(
        find.text('Monitor changes in your vital signals and get an early warning when something looks unusual.'),
        findsOneWidget,
      );
      expect(find.text('Get Started'), findsOneWidget);
      expect(find.text('Your privacy and security matter to us.'), findsOneWidget);

      // Tap CTA to advance to Screen 2
      await tapButton(tester, find.text('Get Started'));

      // Verify Screen 2 content
      expect(find.text("We learn what's normal for you."), findsOneWidget);
      expect(
        find.text("Everyone's body is different. We build a personal baseline so changes can be compared against your usual patterns."),
        findsOneWidget,
      );
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('Screen 2 back button retreats to Screen 1', (tester) async {
      setupMobileViewport(tester);
      await tester.pumpWidget(createTestApp());
      await stepPump(tester);

      // Go to Screen 2
      await tapButton(tester, find.text('Get Started'));
      expect(find.text("We learn what's normal for you."), findsOneWidget);

      // Tap back button
      await tapButton(tester, find.byIcon(Icons.arrow_back_rounded));

      // Back at Screen 1
      expect(find.text('Know when something changes.'), findsOneWidget);
    });

    testWidgets('Screen 3 (Profile) validates input and advances to Screen 4', (tester) async {
      setupMobileViewport(tester);
      await tester.pumpWidget(createTestApp());
      await stepPump(tester);

      // Navigate to Screen 2 -> Screen 3
      await tapButton(tester, find.text('Get Started'));
      await tapButton(tester, find.text('Continue'));

      // Verify Screen 3 content
      expect(find.text("Let's get to know you."), findsOneWidget);
      expect(find.text('A few basic details help us personalize your monitoring experience.'), findsOneWidget);

      // Tap Continue (fields default to prefilled valid user name & age)
      await tapButton(tester, find.text('Continue'));

      // Verify Screen 4 (Emergency Contact)
      expect(find.text('Who should we contact if you need help?'), findsOneWidget);
    });

    testWidgets('Screen 4 (Emergency Contact) saves contact and advances to Screen 5 (Permissions)', (tester) async {
      setupMobileViewport(tester);
      await tester.pumpWidget(createTestApp());
      await stepPump(tester);

      // Navigate to Screen 4
      await tapButton(tester, find.text('Get Started'));
      await tapButton(tester, find.text('Continue'));
      await tapButton(tester, find.text('Continue'));

      expect(find.text('Who should we contact if you need help?'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);

      await tapButton(tester, find.text('Continue'));

      // Verify Screen 5 (Permissions)
      expect(find.text('A few permissions are needed.'), findsOneWidget);
      expect(find.text('Camera'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Health Data'), findsOneWidget);
      expect(find.text('Allow & Continue'), findsOneWidget);
    });

    testWidgets('Screen 5 (Permissions) advances to Screen 6 (Camera Tutorial)', (tester) async {
      setupMobileViewport(tester);
      await tester.pumpWidget(createTestApp());
      await stepPump(tester);

      // Navigate to Screen 5
      await tapButton(tester, find.text('Get Started'));
      await tapButton(tester, find.text('Continue'));
      await tapButton(tester, find.text('Continue'));
      await tapButton(tester, find.text('Continue'));

      expect(find.text('A few permissions are needed.'), findsOneWidget);
      await tapButton(tester, find.text('Allow & Continue'));

      // Verify Screen 6 (Camera Tutorial)
      expect(find.text('Measure your vitals with your camera.'), findsOneWidget);
      expect(find.text('Cover both camera lens and flash'), findsOneWidget);
      expect(find.text('Try It'), findsOneWidget);
    });

    testWidgets('Screen 8 (Baseline Complete) sets has_completed_onboarding and triggers completion', (tester) async {
      setupMobileViewport(tester);
      bool completed = false;

      await tester.pumpWidget(createTestApp(
        onComplete: () => completed = true,
      ));
      await stepPump(tester);

      // Advance through Screens 1 to 5
      await tapButton(tester, find.text('Get Started'));
      await tapButton(tester, find.text('Continue'));
      await tapButton(tester, find.text('Continue'));
      await tapButton(tester, find.text('Continue'));
      await tapButton(tester, find.text('Allow & Continue'));

      // At Screen 6 (Tutorial), tap Try It
      expect(find.text('Try It'), findsOneWidget);
      await tapButton(tester, find.text('Try It'));

      // At Screen 7 (Initial Baseline)
      expect(find.text("Let's establish your baseline."), findsOneWidget);
      final skipBtn = find.text('Skip Baseline for Now');
      expect(skipBtn, findsOneWidget);
      await tapButton(tester, skipBtn);

      // At Screen 8 (Baseline Complete)
      expect(find.text("You're all set."), findsOneWidget);
      expect(
        find.text('Your initial baseline has been created. It will become more reliable as we learn your normal patterns over time.'),
        findsOneWidget,
      );
      expect(find.text('Start Monitoring'), findsOneWidget);

      // Tap Start Monitoring
      await tapButton(tester, find.text('Start Monitoring'));

      expect(completed, isTrue);
      expect(prefs.getBool('has_completed_onboarding'), isTrue);
    });
  });
}
