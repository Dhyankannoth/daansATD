import 'package:flutter_test/flutter_test.dart';
import 'package:app/main.dart';
import 'package:app/camera_finger_instruction.dart';

void main() {
  testWidgets('CameraFingerInstruction smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const VMedithonApp());

    // Verify instructional texts are rendered
    expect(find.text('Cover the camera with your finger'), findsOneWidget);
    expect(find.text('Keep your finger in place for a few seconds'), findsOneWidget);
    expect(find.byType(CameraFingerInstruction), findsOneWidget);
  });
}
