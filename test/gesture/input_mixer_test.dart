import 'package:duo_motion/src/core/fold_state.dart';
import 'package:duo_motion/src/gesture/input_mixer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InputMixer', () {
    test('initial state is inactive with zero gesture start state', () {
      final mixer = InputMixer();
      expect(mixer.isInGestureMode, isFalse);
      expect(mixer.gestureStartState, FoldState.zero);
    });

    test('beginGesture captures sensor state and activates gesture mode', () {
      final mixer = InputMixer();
      const current = FoldState(
        tiltDegrees: 18.5,
        liftDirX: 0.0,
        liftDirY: -1.0,
      );

      mixer.beginGesture(current);

      expect(mixer.isInGestureMode, isTrue);
      expect(mixer.gestureStartState, current);
      expect(mixer.gestureStartState.tiltDegrees, 18.5);
      expect(mixer.gestureStartState.liftDirection.dy, -1.0);
    });

    test('endGesture deactivates gesture mode', () {
      final mixer = InputMixer();
      mixer.beginGesture(const FoldState(tiltDegrees: 10, liftDirX: -1, liftDirY: 0));
      expect(mixer.isInGestureMode, isTrue);

      mixer.endGesture();
      expect(mixer.isInGestureMode, isFalse);
    });
  });
}
