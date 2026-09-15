import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulseguard/core/theme/pulse_theme.dart';
import 'package:pulseguard/engine/api/events.dart';
import 'package:pulseguard/shared/widgets/buttons/emergency_button.dart';
import 'package:pulseguard/shared/widgets/buttons/primary_button.dart';
import 'package:pulseguard/shared/widgets/buttons/secondary_button.dart';
import 'package:pulseguard/shared/widgets/cards/metric_card.dart';
import 'package:pulseguard/shared/widgets/cards/status_card.dart';
import 'package:pulseguard/shared/widgets/cards/vital_metric_tile.dart';
import 'package:pulseguard/shared/widgets/indicators/countdown_ring.dart';
import 'package:pulseguard/shared/widgets/indicators/risk_badge.dart';
import 'package:pulseguard/shared/widgets/indicators/signal_quality_bar.dart';

void main() {
  Widget wrapWidget(Widget child) {
    return MaterialApp(
      theme: PulseTheme.lightTheme,
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('Buttons Tests', () {
    testWidgets('PrimaryButton renders label and handles tap', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        wrapWidget(
          PrimaryButton(
            label: 'Start Scan',
            onPressed: () => tapped = true,
          ),
        ),
      );

      expect(find.text('Start Scan'), findsOneWidget);
      await tester.tap(find.text('Start Scan'));
      expect(tapped, isTrue);
    });

    testWidgets('PrimaryButton displays loading spinner when isLoading is true', (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          PrimaryButton(
            label: 'Submit',
            isLoading: true,
            onPressed: () {},
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('SecondaryButton renders with outlined style', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        wrapWidget(
          SecondaryButton(
            label: 'Cancel',
            onPressed: () => tapped = true,
          ),
        ),
      );

      expect(find.text('Cancel'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      expect(tapped, isTrue);
    });

    testWidgets('EmergencyButton renders with high contrast and urgent icon', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        wrapWidget(
          EmergencyButton(
            label: 'CALL EMERGENCY SERVICES',
            subtitle: 'Immediate 911 Trigger',
            icon: Icons.emergency_rounded,
            onPressed: () => tapped = true,
          ),
        ),
      );

      expect(find.text('CALL EMERGENCY SERVICES'), findsOneWidget);
      expect(find.text('Immediate 911 Trigger'), findsOneWidget);
      expect(find.byIcon(Icons.emergency_rounded), findsOneWidget);

      await tester.tap(find.text('CALL EMERGENCY SERVICES'));
      expect(tapped, isTrue);
    });
  });

  group('MetricCard Tests', () {
    testWidgets('MetricCard displays tabular values and baseline delta', (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          const MetricCard(
            label: 'Heart Rate',
            value: '76',
            unit: 'BPM',
            deltaText: '+4 BPM from baseline',
            isTrusted: true,
          ),
        ),
      );

      expect(find.text('HEART RATE'), findsOneWidget);
      expect(find.text('76'), findsOneWidget);
      expect(find.text('BPM'), findsOneWidget);
      expect(find.text('+4 BPM from baseline'), findsOneWidget);
    });

    testWidgets('MetricCard shows Experimental badge for SpO2', (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          const MetricCard(
            label: 'SpO₂ Estimate',
            value: '98',
            unit: '%',
            isExperimental: true,
          ),
        ),
      );

      expect(find.text('Experimental'), findsOneWidget);
      expect(find.text('98'), findsOneWidget);
    });

    testWidgets('MetricCard renders placeholder when value is null', (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          const MetricCard(
            label: 'HRV',
            value: null,
            unit: 'ms',
          ),
        ),
      );

      expect(find.text('—'), findsOneWidget);
    });
  });

  group('Indicators Tests', () {
    testWidgets('RiskBadge renders triple encoded indicators for each risk level', (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          const Column(
            children: [
              RiskBadge(level: RiskLevel.normal),
              RiskBadge(level: RiskLevel.monitoring),
              RiskBadge(level: RiskLevel.elevated),
              RiskBadge(level: RiskLevel.high),
              RiskBadge(level: RiskLevel.critical),
            ],
          ),
        ),
      );

      expect(find.text('Normal'), findsOneWidget);
      expect(find.text('Monitoring'), findsOneWidget);
      expect(find.text('Elevated'), findsOneWidget);
      expect(find.text('Check Needed'), findsOneWidget);
      expect(find.text('Attention Required'), findsOneWidget);
    });

    testWidgets('SignalQualityBar renders proper label based on quality score', (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          const Column(
            children: [
              SignalQualityBar(quality: 0.9, hasFinger: true),
              SignalQualityBar(quality: 0.5, hasFinger: true),
              SignalQualityBar(quality: 0.2, hasFinger: true),
              SignalQualityBar(quality: 0.0, hasFinger: false),
            ],
          ),
        ),
      );

      expect(find.text('Strong signal'), findsOneWidget);
      expect(find.text('Adjusting'), findsOneWidget);
      expect(find.text('Low signal'), findsOneWidget);
      expect(find.text('No finger'), findsOneWidget);
    });

    testWidgets('CountdownRing displays seconds remaining', (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          const CountdownRing(secondsRemaining: 24, totalSeconds: 30),
        ),
      );

      expect(find.text('24'), findsOneWidget);
      expect(find.text('sec'), findsOneWidget);
    });
  });

  group('StatusCard & VitalMetricTile Tests', () {
    testWidgets('StatusCard renders title and description', (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          const StatusCard(
            title: 'Activity: Resting',
            description: 'Vitals evaluated against resting baseline.',
            icon: Icons.nightlight_round,
          ),
        ),
      );

      expect(find.text('Activity: Resting'), findsOneWidget);
      expect(find.text('Vitals evaluated against resting baseline.'), findsOneWidget);
    });

    testWidgets('VitalMetricTile displays metric and unit', (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          const VitalMetricTile(
            icon: Icons.favorite_rounded,
            title: 'Heart Rate at Escalation',
            value: '132',
            unit: 'BPM',
            comparison: '+54 BPM above baseline',
          ),
        ),
      );

      expect(find.text('Heart Rate at Escalation'), findsOneWidget);
      expect(find.text('132'), findsOneWidget);
      expect(find.text('BPM'), findsOneWidget);
      expect(find.text('+54 BPM above baseline'), findsOneWidget);
    });
  });
}
