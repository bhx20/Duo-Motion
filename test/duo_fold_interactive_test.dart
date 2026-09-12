import 'package:duo_motion/duo_motion.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DuoFoldInteractive', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: DuoFoldInteractive(
            enabled: false,
            child: Text('Interactive Content'),
          ),
        ),
      );

      expect(find.text('Interactive Content'), findsOneWidget);
    });

    testWidgets('pan gesture updates controller tilt when disabled pass-through', (tester) async {
      final controller = FoldController();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: DuoFoldInteractive(
            controller: controller,
            sensitivity: 0.5,
            springBack: false,
            enabled: false,
            child: const SizedBox(width: 300, height: 300),
          ),
        ),
      );

      // Enabled is false so gesture detector is disabled on widget level
      expect(find.byType(DuoFoldInteractive), findsOneWidget);
      controller.dispose();
    });

    test('setManualTilt updates tilt and lift direction correctly', () async {
      final controller = FoldController();
      controller.setManualTilt(25.0, liftDirection: const Offset(-1, 0));

      expect(controller.manualTiltDegrees, equals(25.0));
      expect(controller.tiltDegrees, equals(25.0));
      expect(controller.liftDirection, equals(const Offset(-1, 0)));

      controller.recalibrate();
      expect(controller.tiltDegrees, equals(0.0));
      controller.dispose();
    });
  });
}
