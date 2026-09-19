import 'package:duo_motion/duo_motion.dart';
import 'package:duo_motion_example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SoloTiltShowcaseApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SoloTiltShowcaseApp());
    expect(find.byType(SoloTiltHomeScreen), findsOneWidget);
    expect(find.byType(DuoFoldMotion), findsOneWidget);
    expect(find.text('NOW PLAYING'), findsOneWidget);
  });
}
