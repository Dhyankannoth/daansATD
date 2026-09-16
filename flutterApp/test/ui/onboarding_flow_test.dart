import 'dart:convert';
import 'package:flutter/material.dart' hide Baseline;
import 'package:flutter_test/flutter_test.dart';
import 'package:pulseguard/camera_finger_instruction.dart';
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

    testWidgets('Screen 1 (Welcome) renders mascot and navigates to Screen 2', (tester) async {
      setupMobileViewport(tester);
      await tester.pumpWidget(createTestApp());
      await stepPump(tester);

      // Verify Screen 1 content
      expect(find.text("Hi, I'm Bluey!"), findsOneWidget);
      expect(
        find.text("I'm here to help you understand your vital signals and notice when something changes."),
        findsOneWidget,
      );
      expect(find.text('Get Started'), findsOneWidget);

      // Tap CTA to advance to Screen 2
      await tapButton(tester, find.text('Get Started'));

      // Verify Screen 2 content
      expect(find.text("I learn what's normal for you."), findsOneWidget);
      expect(
        find.text("Everyone's body is different. I build a personal baseline so changes can be compared against your usual patterns."),
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
      expect(find.text("I learn what's normal for you."), findsOneWidget);

      // Tap back button
      await tapButton(tester, find.byIcon(Icons.arrow_back_rounded));

      // Back at Screen 1
      expect(find.text("Hi, I'm Bluey!"), findsOneWidget);
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
      expect(find.text('A few basic details help me personalize your monitoring experience.'), findsOneWidget);

      // Tap Continue (fields default to prefilled valid user name & age)
      await tapButton(tester, find.text('Continue'));

      // Verify Screen 4 (Emergency Contact)
      expect(find.text('Who should I contact if you need help?'), findsOneWidget);
    });

    testWidgets('Screen 4 (Emergency Contact) saves contact and advances to Screen 5 (Permissions)', (tester) async {
      setupMobileViewport(tester);
      await tester.pumpWidget(createTestApp());
      await stepPump(tester);

      // Navigate to Screen 4
      await tapButton(tester, find.text('Get Started'));
      await tapButton(tester, find.text('Continue'));
      await tapButton(tester, find.text('Continue'));

      expect(find.text('Who should I contact if you need help?'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);

      await tapButton(tester, find.text('Continue'));

      // Verify Screen 5 (Permissions)
      expect(find.text('A few permissions are needed.'), findsOneWidget);
      expect(find.text('Camera'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Health Data'), findsOneWidget);
      expect(find.text('Allow & Continue'), findsOneWidget);
    });

    testWidgets('Screen 4 (Emergency Contact) relationship dropdown and number verification work', (tester) async {
      setupMobileViewport(tester);
      await tester.pumpWidget(createTestApp());
      await stepPump(tester);

      // Navigate to Screen 4
      await tapButton(tester, find.text('Get Started'));
      await tapButton(tester, find.text('Continue'));
      await tapButton(tester, find.text('Continue'));

      expect(find.text('Who should I contact if you need help?'), findsOneWidget);
      expect(find.text('Partner'), findsOneWidget);

      // Open Relationship Dropdown and select 'Parent'
      await tester.tap(find.text('Partner'));
      await tester.pumpAndSettle();
      expect(find.text('Parent').last, findsOneWidget);
      await tester.tap(find.text('Parent').last);
      await tester.pumpAndSettle();

      // Open Phone Number Verification Sheet
      expect(find.text('Verify Number'), findsOneWidget);
      await tester.tap(find.text('Verify Number'));
      await tester.pumpAndSettle();

      expect(find.text('Verify Contact Number'), findsOneWidget);
      expect(find.text('Send Verification Code'), findsOneWidget);

      // Send Verification Code
      await tester.tap(find.text('Send Verification Code'));
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      // Auto-fill Test Code
      expect(find.text('Auto-fill Test Code (4826)'), findsOneWidget);
      await tester.tap(find.text('Auto-fill Test Code (4826)'));
      await tester.pumpAndSettle();

      // Confirm & Verify
      await tester.tap(find.text('Confirm & Verify'));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // Verified badge should now be visible
      expect(find.text('Verified'), findsOneWidget);

      ScaffoldMessenger.of(tester.element(find.text('Verified'))).hideCurrentSnackBar();
      await tester.pumpAndSettle();

      // Tap Continue to advance to Screen 5
      await tapButton(tester, find.text('Continue'));
      expect(find.text('A few permissions are needed.'), findsOneWidget);
    });

    testWidgets('Screen 6 (Camera Tutorial) "Measure" button navigates to Screen 7 (Establish Baseline)', (tester) async {
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
      expect(find.text('Measure'), findsOneWidget);

      // First time: tapping "Measure" navigates to Screen 7: "Let's establish your baseline."
      await tapButton(tester, find.text('Measure'));

      // Verify Screen 7 (Establish Baseline Tutorial)
      expect(find.text("Let's establish your baseline."), findsOneWidget);
      expect(
        find.textContaining("We'll take your first measurement"),
        findsOneWidget,
      );
      // Prominent phone animation is displayed
      expect(find.byType(CameraFingerInstruction), findsOneWidget);
      expect(find.text('Keep your finger still'), findsOneWidget);
      expect(find.text('Start Measurement'), findsOneWidget);
    });

    testWidgets('Full 9-screen flow completes baseline and sets onboarding flag', (tester) async {
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

      // Screen 6 (Camera Tutorial): tap Measure
      expect(find.text('Measure'), findsOneWidget);
      await tapButton(tester, find.text('Measure'));

      // Screen 7 (Establish Baseline): tap Start Measurement
      expect(find.text("Let's establish your baseline."), findsOneWidget);
      expect(find.byType(CameraFingerInstruction), findsOneWidget);
      expect(find.text('Start Measurement'), findsOneWidget);
      await tapButton(tester, find.text('Start Measurement'));

      // Screen 8 (Initial Baseline Measurement)
      expect(find.text('Measuring your baseline.'), findsOneWidget);
      final skipBtn = find.text('Skip Baseline for Now');
      expect(skipBtn, findsOneWidget);
      await tapButton(tester, skipBtn);

      // Screen 9 (Baseline Complete)
      expect(find.text("You're all set."), findsOneWidget);
      expect(
        find.textContaining('Your initial baseline has been created'),
        findsOneWidget,
      );
      expect(find.text('Start Monitoring'), findsOneWidget);

      // Tap Start Monitoring
      await tapButton(tester, find.text('Start Monitoring'));

      expect(completed, isTrue);
      expect(prefs.getBool('has_completed_onboarding'), isTrue);
    });

    testWidgets('Subsequent measurement skips Establish Baseline tutorial when baseline already exists', (tester) async {
      setupMobileViewport(tester);

      // Pre-seed a baseline in engine store
      const metric = MetricBaseline(
        mean: 72.0,
        sd: 4.0,
        variance: 16.0,
        sdFloorApplied: false,
        sessionCount: 1,
        updatedAt: 1000,
      );
      const baseline = Baseline(
        hr: metric,
        hrv: metric,
        rr: metric,
        isDemo: false,
      );
      await prefs.setString('pulseguard.baseline', jsonEncode(baseline.toJson()));
      await engine.setBaselineForTesting(baseline);

      await tester.pumpWidget(createTestApp());
      await stepPump(tester);

      // Advance through Screens 1 to 5
      await tapButton(tester, find.text('Get Started'));
      await tapButton(tester, find.text('Continue'));
      await tapButton(tester, find.text('Continue'));
      await tapButton(tester, find.text('Continue'));
      await tapButton(tester, find.text('Allow & Continue'));

      // Screen 6 (Camera Tutorial): tap Measure
      expect(find.text('Measure'), findsOneWidget);
      await tapButton(tester, find.text('Measure'));

      // When baseline exists, it skips the Establish Baseline demo and goes directly to Screen 8 (InitialBaselineScreen)
      expect(find.text('Skip Baseline for Now'), findsOneWidget);
    });
  });
}
