import 'package:duo_motion/src/controller/fold_controller.dart';
import 'package:duo_motion/src/core/fold_state.dart';
import 'package:duo_motion/src/motion/motion_source.dart';
import 'package:duo_motion/src/widgets/duo_fold.dart';
import 'package:duo_motion/src/widgets/duo_fold_animated.dart';
import 'package:duo_motion/src/widgets/duo_fold_interactive.dart';
import 'package:duo_motion/src/widgets/duo_fold_motion.dart';
import 'package:duo_motion/src/widgets/duo_fold_theme.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DuoFold widget pass-through', () {
    testWidgets('renders child directly when disabled', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: DuoFold(
            state: FoldState(tiltDegrees: 20, liftDirX: -1, liftDirY: 0),
            enabled: false,
            child: Text('Hidden Fold Child'),
          ),
        ),
      );

      expect(find.text('Hidden Fold Child'), findsOneWidget);
    });

    testWidgets('renders child directly when at rest (tilt 0)', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: DuoFold(
            state: FoldState.zero,
            child: Text('Rest Fold Child'),
          ),
        ),
      );

      expect(find.text('Rest Fold Child'), findsOneWidget);
    });
  });

  group('DuoFoldTheme', () {
    testWidgets('descendant widgets access inherited theme data', (tester) async {
      late DuoFoldThemeData themeData;

      await tester.pumpWidget(
        DuoFoldTheme(
          data: const DuoFoldThemeData(),
          child: Builder(
            builder: (context) {
              themeData = DuoFoldTheme.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(themeData, isNotNull);
      expect(themeData.parameters.eyeDistanceMillimeters, 450.0);
    });
  });

  group('DuoFoldMotion', () {
    testWidgets('renders child through controller listener', (tester) async {
      final controller = FoldController(source: FakeMotionSource());

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: DuoFoldMotion(
            controller: controller,
            child: const Text('Motion Child'),
          ),
        ),
      );

      expect(find.text('Motion Child'), findsOneWidget);
      controller.dispose();
    });
  });

  group('DuoFoldAnimated', () {
    testWidgets('animates state and preserves child', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: DuoFoldAnimated(
            targetState: FoldState(tiltDegrees: 15, liftDirX: -1, liftDirY: 0),
            duration: Duration(milliseconds: 200),
            child: Text('Animated Child'),
          ),
        ),
      );

      expect(find.text('Animated Child'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('Animated Child'), findsOneWidget);
    });
  });

  group('DuoFoldInteractive', () {
    testWidgets('handles pan gestures cleanly', (tester) async {
      var foldChanged = false;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: DuoFoldInteractive(
            onFoldChanged: (_) => foldChanged = true,
            child: const SizedBox(width: 300, height: 300),
          ),
        ),
      );

      await tester.drag(find.byType(DuoFoldInteractive), const Offset(-50, 0));
      await tester.pump();

      expect(foldChanged, isTrue);
    });
  });
}
