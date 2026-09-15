// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:pulseguard/main.dart';
import 'package:pulseguard/camera_finger_instruction.dart';

void main() {
  testWidgets('CameraFingerInstruction smoke test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const PulseGuardApp());

    // Verify instructional texts are rendered
    expect(find.text('Cover the camera with your finger'), findsOneWidget);
    expect(
      find.text('Keep your finger in place for a few seconds'),
      findsOneWidget,
    );
    expect(find.byType(CameraFingerInstruction), findsOneWidget);
  });
}
