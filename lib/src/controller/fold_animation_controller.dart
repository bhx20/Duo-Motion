import 'package:flutter/animation.dart';

import '../core/fold_state.dart';

/// Drives programmatic animations between [FoldState] targets without requiring sensors or touch.
///
/// Built on top of Flutter's native [AnimationController] and [TickerProvider] (VSync).
/// Automatically handles smooth interpolation of both the scalar tilt angle and the 2D unit
/// lift direction vector using [FoldState.lerp].
class FoldAnimationController {
  /// Creates a programmatic fold animator synchronized to display VSync via [vsync].
  FoldAnimationController({
    required TickerProvider vsync,
    this.duration = const Duration(milliseconds: 350),
    this.curve = Curves.easeOutCubic,
  }) {
    _animationController = AnimationController(
      vsync: vsync,
      duration: duration,
    )..addListener(_onTick);
  }

  /// Default animation transition duration.
  Duration duration;

  /// Default easing curve applied during state interpolation.
  Curve curve;

  late final AnimationController _animationController;

  FoldState _startState = FoldState.zero;
  FoldState _targetState = FoldState.zero;
  FoldState _currentState = FoldState.zero;

  final List<VoidCallback> _listeners = [];

  /// Current interpolated [FoldState] at this point in the animation.
  FoldState get currentState => _currentState;

  /// Target [FoldState] currently being animated toward.
  FoldState get targetState => _targetState;

  /// Whether an animation is currently actively ticking.
  bool get isAnimating => _animationController.isAnimating;

  /// Internal tick listener that transforms time and invokes registered callbacks.
  void _onTick() {
    final t = curve.transform(_animationController.value);
    _currentState = FoldState.lerp(_startState, _targetState, t);
    for (final listener in List<VoidCallback>.of(_listeners)) {
      listener();
    }
  }

  /// Programmatically animates smoothly from the current state to [target].
  ///
  /// Optional [duration] and [curve] parameters override controller defaults for this run.
  Future<void> animateTo(
    FoldState target, {
    Duration? duration,
    Curve? curve,
  }) {
    _startState = _currentState;
    _targetState = target;
    if (duration != null) _animationController.duration = duration;
    _animationController.reset();
    return _animationController.forward();
  }

  /// Shorthand animating the tilt angle while retaining the current lift direction vector.
  Future<void> animateTiltTo(
    double degrees, {
    Duration? duration,
    Curve? curve,
  }) {
    return animateTo(
      _currentState.withTilt(degrees),
      duration: duration,
      curve: curve,
    );
  }

  /// Immediately halts any currently running animation at its current frame.
  void stop() {
    _animationController.stop();
  }

  /// Registers a listener callback invoked on every animated frame tick.
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  /// Unregisters an existing animation listener callback.
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  /// Disposes internal Flutter animation ticker resources.
  void dispose() {
    _animationController.dispose();
    _listeners.clear();
  }
}
