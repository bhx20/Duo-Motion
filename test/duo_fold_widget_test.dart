import 'package:duo_motion/duo_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// The effect is a no-op below this tilt, so these cases must not build an
  /// ImageFiltered at all. That matters twice over: it keeps a level device off
  /// the shader path entirely, and it is the only part of the widget that is
  /// testable off Impeller, since flutter_test rasterizes with Skia.
  group('pass-through', () {
    testWidgets('renders the child directly when disabled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DuoFold(
            state: FoldState(tiltDegrees: 30, liftDirX: -1, liftDirY: 0),
            enabled: false,
            child: Text('content', textDirection: TextDirection.ltr),
          ),
        ),
      );

      expect(find.text('content'), findsOneWidget);
      expect(find.byType(ImageFiltered), findsNothing);
    });

    testWidgets('renders the child directly at rest', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DuoFold(
            state: FoldState.zero,
            child: Text('content', textDirection: TextDirection.ltr),
          ),
        ),
      );

      expect(find.text('content'), findsOneWidget);
      expect(find.byType(ImageFiltered), findsNothing);
    });

    testWidgets('treats sub-epsilon tilt as rest', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DuoFold(
            state: const FoldState(
              tiltDegrees: FoldState.restEpsilon / 2,
              liftDirX: -1,
              liftDirY: 0,
            ),
            child: const Text('content', textDirection: TextDirection.ltr),
          ),
        ),
      );

      expect(find.byType(ImageFiltered), findsNothing);
    });
  });

  group('liftDirection and state', () {
    testWidgets('passes FoldState correctly to rendering widget', (tester) async {
      const widget = DuoFold(
        state: FoldState(tiltDegrees: 30, liftDirX: -1, liftDirY: 0),
        enabled: false,
        child: Text('content', textDirection: TextDirection.ltr),
      );

      expect(widget.state.liftDirection, const Offset(-1, 0));
      expect(widget.state.tiltDegrees, 30);

      await tester.pumpWidget(const MaterialApp(home: widget));
      expect(find.text('content'), findsOneWidget);
    });

    testWidgets('an explicit lift direction is preserved in FoldState', (tester) async {
      const widget = DuoFold(
        state: FoldState(tiltDegrees: 25, liftDirX: 0, liftDirY: 1),
        enabled: false,
        child: Text('content', textDirection: TextDirection.ltr),
      );

      expect(widget.state.liftDirection, const Offset(0, 1));
      expect(widget.state.tiltDegrees, 25);

      await tester.pumpWidget(const MaterialApp(home: widget));
      expect(find.text('content'), findsOneWidget);
    });

    testWidgets('zero tilt state accepted at rest without throwing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DuoFold(
            state: FoldState.zero,
            child: SizedBox(),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
