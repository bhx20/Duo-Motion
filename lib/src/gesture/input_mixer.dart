import '../core/fold_state.dart';

/// Orchestrates zero-glitch state handoffs between hardware sensors and touch gestures.
///
/// ### Problem Solved
/// In dual-mode motion apps (where device gyroscope tilt AND manual touch drags are supported),
/// switching from sensor tracking to a touch drag can cause an abrupt visual snap if the
/// controller resets to manual zero.
///
/// [InputMixer] guarantees smooth continuity:
/// 1. Immediately prior to overriding sensor control, the exact unconstrained [FoldState]
///    produced by the gyroscope is captured.
/// 2. The controller sets its manual baseline to this captured state.
/// 3. The gesture interpreter begins tracking from this captured pose.
/// 4. Result: Touch drags seamlessly "catch" the moving card mid-air without any jarring jump.
class InputMixer {
  FoldState _capturedSensorState = FoldState.zero;
  bool _inGestureMode = false;

  /// Captures the active sensor-derived fold state before switching the controller to manual mode.
  ///
  /// Must be invoked inside `onPanStart` or `onScaleStart` before disabling sensor streams.
  void beginGesture(FoldState currentSensorState) {
    _capturedSensorState = currentSensorState;
    _inGestureMode = true;
  }

  /// The snapshot of [FoldState] that was active at the instant touch interaction began.
  FoldState get gestureStartState => _capturedSensorState;

  /// Whether a user touch gesture is currently actively overriding sensor input.
  bool get isInGestureMode => _inGestureMode;

  /// Invoked when touch interaction finishes (e.g. after spring settle) to re-arm sensor mode.
  void endGesture() {
    _inGestureMode = false;
  }
}
