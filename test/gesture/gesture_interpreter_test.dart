import 'dart:ui' as ui;

import 'package:duo_motion/src/core/fold_parameters.dart';
import 'package:duo_motion/src/core/fold_state.dart';
import 'package:duo_motion/src/gesture/gesture_interpreter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GestureInterpreter', () {
    test('initial state is zero tilt and default hinge-right lift direction', () {
      final interpreter = GestureInterpreter();
      expect(interpreter.currentTilt, 0.0);
      expect(interpreter.currentLiftDir, const ui.Offset(-1, 0));
    });

    test('onDragStart captures current state and non-rest lift direction', () {
      final interpreter = GestureInterpreter();
      const initial = FoldState(
        tiltDegrees: 15.0,
        liftDirX: 0.0,
        liftDirY: 1.0,
      );

      interpreter.onDragStart(initial);
      expect(interpreter.currentTilt, 15.0);
      expect(interpreter.currentLiftDir, const ui.Offset(0.0, 1.0));
    });

    test('onDragStart at rest keeps default lift direction', () {
      final interpreter = GestureInterpreter();
      interpreter.onDragStart(FoldState.zero);
      expect(interpreter.currentTilt, 0.0);
      expect(interpreter.currentLiftDir, const ui.Offset(-1, 0));
    });

    test('onDragUpdate ignores sub-threshold deltas', () {
      final interpreter = GestureInterpreter(sensitivity: 1.0);
      interpreter.onDragStart(const FoldState(tiltDegrees: 10, liftDirX: -1, liftDirY: 0));

      final state = interpreter.onDragUpdate(const ui.Offset(0.001, 0.001));
      expect(state.tiltDegrees, 10.0);
      expect(interpreter.currentTilt, 10.0);
    });

    test('onDragUpdate increases tilt when dragging in lift direction (positive projection)', () {
      final interpreter = GestureInterpreter(sensitivity: 0.5);
      interpreter.onDragStart(const FoldState(tiltDegrees: 10, liftDirX: -1, liftDirY: 0));

      // Dragging left (-10 px) matches lift direction (-1, 0)
      final state = interpreter.onDragUpdate(const ui.Offset(-10, 0));
      // projection = (-10)*(-1) + 0 = 10; delta = 10 * 0.5 = 5 degrees -> 15.0
      expect(state.tiltDegrees, closeTo(15.0, 1e-5));
      expect(interpreter.currentTilt, closeTo(15.0, 1e-5));
      expect(state.liftDirX, -1.0);
    });

    test('onDragUpdate decreases tilt when dragging opposite to lift direction', () {
      final interpreter = GestureInterpreter(sensitivity: 0.5);
      interpreter.onDragStart(const FoldState(tiltDegrees: 20, liftDirX: -1, liftDirY: 0));

      // Dragging right (+10 px) opposes lift direction (-1, 0)
      final state = interpreter.onDragUpdate(const ui.Offset(10, 0));
      // projection = 10 * (-1) = -10; delta = -10 * 0.5 = -5 -> 15.0
      expect(state.tiltDegrees, closeTo(15.0, 1e-5));
    });

    test('onDragUpdate clamps tilt to maxTiltDegrees', () {
      final interpreter = GestureInterpreter(sensitivity: 10.0);
      interpreter.onDragStart(const FoldState(tiltDegrees: 30, liftDirX: -1, liftDirY: 0));

      final state = interpreter.onDragUpdate(const ui.Offset(-50, 0));
      expect(state.tiltDegrees, FoldParameters.maxTiltDegrees);
    });

    test('onDragUpdate reverses direction when tilt < 1.0 and dragged opposing', () {
      final interpreter = GestureInterpreter(sensitivity: 0.5);
      interpreter.onDragStart(const FoldState(tiltDegrees: 0.5, liftDirX: -1, liftDirY: 0));

      // Drag right (+10 px), projection is negative, tilt < 1.0 -> reverses direction to (+1, 0)
      final state = interpreter.onDragUpdate(const ui.Offset(10, 0));
      expect(state.liftDirX, closeTo(1.0, 1e-5));
      expect(state.liftDirY, closeTo(0.0, 1e-5));
      expect(state.tiltDegrees, closeTo(5.0, 1e-5));
    });

    test('onDragEnd projects velocity onto lift direction and returns signedVelocity', () {
      final interpreter = GestureInterpreter(sensitivity: 0.25);
      interpreter.onDragStart(const FoldState(tiltDegrees: 15, liftDirX: -1, liftDirY: 0));

      // Fling left with velocity (-200, 0) px/s
      final res = interpreter.onDragEnd(const ui.Offset(-200, 0));
      // projected = (-200 * -1) * 0.25 = 50.0 deg/s
      expect(res.signedVelocity, closeTo(50.0, 1e-5));
      expect(res.state.tiltDegrees, 15.0);

      // Fling right with velocity (200, 0) px/s -> closing velocity
      final resClosing = interpreter.onDragEnd(const ui.Offset(200, 0));
      expect(resClosing.signedVelocity, closeTo(-50.0, 1e-5));
    });
  });
}
