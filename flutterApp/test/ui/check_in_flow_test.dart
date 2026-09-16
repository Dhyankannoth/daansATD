import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulseguard/core/constants/pulse_constants.dart';
import 'package:pulseguard/core/theme/pulse_theme.dart';
import 'package:pulseguard/features/emergency/escalation_screen.dart';
import 'package:pulseguard/pulseguard_engine.dart';
import 'package:pulseguard/data/repositories/history_repository.dart';
import 'package:pulseguard/services/pulse_engine_scope.dart';
import 'package:pulseguard/shared/widgets/dialogs/check_in_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Check-In Flow Tests', () {
    testWidgets('CheckInSheet renders non-diagnostic warning copy and handles responses', (tester) async {
      bool okTapped = false;
      bool notOkTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: PulseTheme.lightTheme,
          home: Scaffold(
            body: CheckInSheet(
              secondsRemaining: 26,
              onUserOk: () => okTapped = true,
              onUserNotOk: () => notOkTapped = true,
            ),
          ),
        ),
      );

      // Verify Non-Diagnostic Wording Constraints
      expect(find.text(PulseConstants.checkInPromptTitle), findsOneWidget);
      expect(find.text(PulseConstants.checkInPromptSubtitle), findsOneWidget);
      expect(find.text(PulseConstants.checkInQuestion), findsOneWidget);
      expect(find.text('26'), findsOneWidget);

      // Verify Action Buttons
      expect(find.text("YES, I'M OKAY"), findsOneWidget);
      expect(find.text("I'M NOT FEELING WELL"), findsOneWidget);

      // Test "YES, I'M OKAY" tap
      await tester.tap(find.text("YES, I'M OKAY"));
      expect(okTapped, isTrue);

      // Test "I'M NOT FEELING WELL" tap
      await tester.tap(find.text("I'M NOT FEELING WELL"));
      expect(notOkTapped, isTrue);
    });
  });

  group('Escalation Screen Tests', () {
    testWidgets('EscalationScreen prioritizes emergency call, contact, and paramedic snapshot', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final historyRepo = HistoryRepository(prefs: prefs);
      final engine = PulseGuardEngine();

      final payload = EscalationPayload(
        triggeredAt: DateTime.now().millisecondsSinceEpoch,
        triggerType: EscalationTriggerType.multiSystem,
        systems: const [BodySystem.cardiovascular, BodySystem.respiratory],
        reasons: const ['Persistent elevated heart rate and tachypnea'],
        vitalsSnapshot: const VitalsReading(
          timestamp: 1000000,
          hr: 134,
          hrv: 16,
          rr: 28,
          spo2: null,
          oxTrend: null,
          quality: 1.0,
          rrQuality: 1.0,
          fingerPresent: true,
          source: VitalsReadingSource.camera,
        ),
        contact: const EmergencyContact(name: 'Sarah Jenkins', phone: '+1-555-0199'),
        status: EscalationStatus.escalated,
      );

      await tester.pumpWidget(
        PulseEngineScope(
          engine: engine,
          historyRepository: historyRepo,
          child: MaterialApp(
            theme: PulseTheme.lightTheme,
            home: EscalationScreen(payload: payload),
          ),
        ),
      );

      // Verify Emergency Headline and Subtitle
      expect(find.text(PulseConstants.escalationHeadline), findsOneWidget);
      expect(find.text(PulseConstants.escalationSubtitle), findsOneWidget);

      // Verify Prescribed Medication Guidance Card
      expect(find.text(PulseConstants.escalationMedicationNotice), findsOneWidget);

      // Verify Direct Emergency Call Trigger
      expect(find.text('CALL EMERGENCY (911 / 112)'), findsOneWidget);

      // Verify Emergency Contact Dispatch Action
      expect(find.text('NOTIFY SARAH JENKINS'), findsOneWidget);

      // Verify Paramedic Vitals Snapshot
      expect(find.text('VITALS SNAPSHOT FOR PARAMEDICS'), findsOneWidget);
      expect(find.text('134'), findsOneWidget);
      expect(find.text('16'), findsOneWidget);
      expect(find.text('28'), findsOneWidget);

      // Verify Cancel / Safe button
      expect(find.text('I Am Safe — Cancel Alert'), findsOneWidget);
    });

    testWidgets('EscalationScreen in alert state transitions to State 2 (User Okay) on YES tap', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final historyRepo = HistoryRepository(prefs: prefs);
      final engine = PulseGuardEngine();

      final payload = EscalationPayload(
        triggeredAt: DateTime.now().millisecondsSinceEpoch,
        triggerType: EscalationTriggerType.multiSystem,
        systems: const [BodySystem.cardiovascular, BodySystem.respiratory],
        reasons: const ['Persistent elevated heart rate and tachypnea'],
        vitalsSnapshot: const VitalsReading(
          timestamp: 1000000,
          hr: 134,
          hrv: 16,
          rr: 28,
          spo2: null,
          oxTrend: null,
          quality: 1.0,
          rrQuality: 1.0,
          fingerPresent: true,
          source: VitalsReadingSource.camera,
        ),
        contact: const EmergencyContact(name: 'Sarah Jenkins', phone: '+1-555-0199'),
        status: EscalationStatus.pending,
      );

      await tester.pumpWidget(
        PulseEngineScope(
          engine: engine,
          historyRepository: historyRepo,
          child: MaterialApp(
            theme: PulseTheme.lightTheme,
            home: EscalationScreen(
              payload: payload,
              initialState: EmergencyVisualState.alert,
            ),
          ),
        ),
      );

      // State 1: Alert
      expect(find.text(PulseConstants.checkInPromptTitle), findsOneWidget); // "Something has changed"
      expect(find.text(PulseConstants.checkInQuestion), findsOneWidget); // "Are you feeling okay?"
      expect(find.text("YES, I'M OKAY"), findsOneWidget);
      expect(find.text("NO, I NEED HELP"), findsOneWidget);

      // Tap "YES, I'M OKAY" -> transitions to State 2 (User Okay)
      await tester.tap(find.text("YES, I'M OKAY"));
      await tester.pumpAndSettle();

      expect(find.text('Thanks for checking in.'), findsOneWidget);
      expect(find.text('WHAT WE NOTICED'), findsOneWidget);
      expect(find.text('What this means'), findsOneWidget);
      expect(find.text('What should I do?'), findsOneWidget);
      expect(find.text('Return to Monitoring'), findsOneWidget);
    });

    testWidgets('EscalationScreen in alert state transitions to State 3 (Need Help) on NO tap', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final historyRepo = HistoryRepository(prefs: prefs);
      final engine = PulseGuardEngine();

      final payload = EscalationPayload(
        triggeredAt: DateTime.now().millisecondsSinceEpoch,
        triggerType: EscalationTriggerType.multiSystem,
        systems: const [BodySystem.cardiovascular, BodySystem.respiratory],
        reasons: const ['Persistent elevated heart rate and tachypnea'],
        vitalsSnapshot: const VitalsReading(
          timestamp: 1000000,
          hr: 134,
          hrv: 16,
          rr: 28,
          spo2: null,
          oxTrend: null,
          quality: 1.0,
          rrQuality: 1.0,
          fingerPresent: true,
          source: VitalsReadingSource.camera,
        ),
        contact: const EmergencyContact(name: 'Sarah Jenkins', phone: '+1-555-0199'),
        status: EscalationStatus.pending,
      );

      await tester.pumpWidget(
        PulseEngineScope(
          engine: engine,
          historyRepository: historyRepo,
          child: MaterialApp(
            theme: PulseTheme.lightTheme,
            home: EscalationScreen(
              payload: payload,
              initialState: EmergencyVisualState.alert,
            ),
          ),
        ),
      );

      // Tap "NO, I NEED HELP" -> transitions to State 3 (Need Help)
      await tester.tap(find.text("NO, I NEED HELP"));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text(PulseConstants.escalationHeadline), findsOneWidget);
      expect(find.text('CALL EMERGENCY (911 / 112)'), findsOneWidget);
      expect(find.text('NOTIFY SARAH JENKINS'), findsOneWidget);
    });

    testWidgets('EscalationScreen renders State 4 (Unresponsive) when timeout occurs', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final historyRepo = HistoryRepository(prefs: prefs);
      final engine = PulseGuardEngine();

      await tester.pumpWidget(
        PulseEngineScope(
          engine: engine,
          historyRepository: historyRepo,
          child: const MaterialApp(
            home: EscalationScreen(
              initialState: EmergencyVisualState.unresponsive,
            ),
          ),
        ),
      );

      expect(find.text("Please check how you're feeling."), findsOneWidget);
      expect(find.text('CALL EMERGENCY (911 / 112)'), findsOneWidget);
      expect(find.text("YES, I'M OKAY"), findsOneWidget);
    });
  });
}
