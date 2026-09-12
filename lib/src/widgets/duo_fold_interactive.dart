import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../controller/fold_controller.dart';
import '../core/fold_effects.dart';
import '../core/fold_mode.dart';
import '../core/fold_parameters.dart';
import '../core/fold_state.dart';
import '../core/snap_config.dart';
import '../gesture/gesture_interpreter.dart';
import '../gesture/input_mixer.dart';
import '../haptics/haptic_policy.dart';
import '../haptics/haptic_service.dart';
import '../physics/spring_config.dart';
import '../physics/spring_simulation.dart';
import '../shader/adaptive_quality.dart';
import 'duo_fold_motion.dart';
import 'duo_fold_theme.dart';

/// Touch-interactive fold widget with signed drag projection, smooth sensor transitions,
/// analytical second-order spring physics, discrete snap detents, and haptic feedback.
///
/// Wrapping any widget inside [DuoFoldInteractive] transforms it into a tactile,
/// fold-responsive 3D surface:
/// - Users can touch and drag across the card to fold it along its hinge.
/// - Releasing a drag flings or springs the card back to rest (or locks into a configured [SnapConfig]).
/// - Device gyroscope motion can blend with touch gestures smoothly via [InputMixer].
class DuoFoldInteractive extends StatefulWidget {
  /// Creates an interactive gesture-driven fold widget.
  const DuoFoldInteractive({
    super.key,
    this.controller,
    this.physics,
    this.parameters,
    this.effects,
    this.mode,
    this.quality,
    this.enabled = true,
    this.sensitivity = 0.25,
    this.springBack = true,
    this.snapConfig,
    this.hapticPolicy,
    this.onFoldChanged,
    this.onFoldStart,
    this.onFoldEnd,
    this.onSnap,
    required this.child,
  });

  /// Optional external [FoldController]. If omitted, an internal controller is automatically maintained.
  final FoldController? controller;

  /// Spring physics configuration (stiffness, damping, mass). Falls back to theme or [SpringConfig.defaultConfig].
  final SpringConfig? physics;

  /// Physical perspective and optical viewing parameters.
  final FoldParameters? parameters;

  /// Optical enhancement effects (caustics, aberration, shadows).
  final FoldEffects? effects;

  /// Fold geometry mode (SingleHingeFold, BookFold, AccordionFold).
  final FoldMode? mode;

  /// Quality tier for shader taps.
  final QualityLevel? quality;

  /// Whether gesture interaction and fold effects are active.
  final bool enabled;

  /// Sensitivity factor: degrees of fold tilt added per pixel of projected drag.
  final double sensitivity;

  /// Whether the fold automatically springs back to flat (0°) on gesture release when no snap detent claims it.
  final bool springBack;

  /// Optional discrete angle snap points.
  final SnapConfig? snapConfig;

  /// Tactile vibration haptic feedback policy.
  final HapticPolicy? hapticPolicy;

  /// Callback invoked on every drag update and spring tick with the current [FoldState].
  final ValueChanged<FoldState>? onFoldChanged;

  /// Callback fired when the user touches down and begins a fold gesture.
  final VoidCallback? onFoldStart;

  /// Callback fired when the gesture and subsequent spring simulation settle to rest.
  final ValueChanged<double>? onFoldEnd;

  /// Callback fired when the fold locks into a discrete snap angle.
  final ValueChanged<double>? onSnap;

  /// The child widget displayed behind the glass fold.
  final Widget child;

  @override
  State<DuoFoldInteractive> createState() => _DuoFoldInteractiveState();
}

class _DuoFoldInteractiveState extends State<DuoFoldInteractive> with SingleTickerProviderStateMixin {
  late FoldController _controller;
  bool _ownsController = false;

  late final GestureInterpreter _gestureInterpreter;
  late final InputMixer _inputMixer;
  final HapticService _hapticService = const HapticService();

  Ticker? _springTicker;
  SpringSimulation? _springSim;
  Duration _springStartTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _gestureInterpreter = GestureInterpreter(sensitivity: widget.sensitivity);
    _inputMixer = InputMixer();
    _initController();
  }

  void _initController() {
    if (widget.controller != null) {
      _controller = widget.controller!;
      _ownsController = false;
    } else {
      _controller = FoldController();
      _ownsController = true;
      _controller.start();
    }
  }

  @override
  void didUpdateWidget(DuoFoldInteractive oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      if (_ownsController) _controller.dispose();
      _initController();
    }
  }

  @override
  void dispose() {
    _springTicker?.dispose();
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  /// Touch down: initiates gesture tracking.
  void _onPanStart(DragStartDetails details) {
    if (!widget.enabled) return;
    _stopSpring();

    // Capture sensor state BEFORE switching off sensor to prevent visual jumping
    final sensorSnapshot = _controller.sensorState;
    _inputMixer.beginGesture(sensorSnapshot);
    _controller.useSensor = false;

    // Seed gesture interpreter with the active fold state
    _gestureInterpreter.onDragStart(_controller.state);
    widget.onFoldStart?.call();
  }

  /// Touch move: updates fold angle according to projected drag distance.
  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.enabled) return;

    // Project drag delta vector onto the active lift axis
    final newState = _gestureInterpreter.onDragUpdate(details.delta);
    _controller.setManualState(newState);
    widget.onFoldChanged?.call(newState);

    // Trigger haptic bump if the fold hits maximum physical limit (45°)
    final haptic = widget.hapticPolicy ?? DuoFoldTheme.of(context).hapticPolicy;
    if (haptic.onLimit && newState.tiltDegrees >= FoldParameters.maxTiltDegrees) {
      _hapticService.trigger(haptic.limitIntensity);
    }
  }

  /// Touch release: launches second-order spring physics simulation.
  void _onPanEnd(DragEndDetails details) {
    if (!widget.enabled) return;

    // Extract final state and signed velocity along the fold axis
    final result = _gestureInterpreter.onDragEnd(details.velocity.pixelsPerSecond);
    _inputMixer.endGesture();

    final theme = DuoFoldTheme.of(context);
    final snap = widget.snapConfig ?? theme.snapConfig;
    final physics = widget.physics ?? theme.physics;
    final haptic = widget.hapticPolicy ?? theme.hapticPolicy;

    // Determine target settling angle (snap point, 0° flat, or current position)
    double targetAngle;
    if (snap != null && snap.angles.isNotEmpty) {
      targetAngle = snap.flingTarget(result.state.tiltDegrees, result.signedVelocity);
      if (haptic.onSnap) {
        _hapticService.trigger(haptic.snapIntensity);
      }
      widget.onSnap?.call(targetAngle);
    } else if (widget.springBack) {
      targetAngle = 0.0;
    } else {
      targetAngle = result.state.tiltDegrees;
    }

    if (haptic.onFlingRelease && result.signedVelocity.abs() > 30.0) {
      _hapticService.trigger(HapticIntensity.light);
    }

    // Launch closed-form analytical ODE spring simulation
    _startSpring(
      startPos: result.state.tiltDegrees,
      targetPos: targetAngle,
      startVelocity: result.signedVelocity,
      liftDir: result.state.liftDirection,
      config: physics,
    );
  }

  /// Creates and starts the analytical spring simulation ticker.
  void _startSpring({
    required double startPos,
    required double targetPos,
    required double startVelocity,
    required ui.Offset liftDir,
    required SpringConfig config,
  }) {
    _stopSpring();

    _springSim = SpringSimulation(
      startPosition: startPos,
      targetPosition: targetPos,
      startVelocity: startVelocity,
      config: config,
    );

    _springTicker ??= createTicker(_onSpringTick);
    _springStartTime = Duration.zero;
    _springTicker!.start();
  }

  /// VSync frame tick evaluating the spring's exact position at continuous time t.
  void _onSpringTick(Duration elapsed) {
    if (_springStartTime == Duration.zero) {
      _springStartTime = elapsed;
    }
    final t = (elapsed - _springStartTime).inMicroseconds / 1e6;

    // If settled within tolerance, finish simulation cleanly
    if (_springSim == null || _springSim!.isDone(t)) {
      final finalPos = _springSim?.targetPosition ?? 0.0;
      _controller.setManualTilt(finalPos, liftDirection: _controller.liftDirection);
      _stopSpring();
      widget.onFoldEnd?.call(finalPos);
      return;
    }

    // Evaluate exact position from analytical solution at time t
    final pos = _springSim!.position(t);
    _controller.setManualTilt(pos, liftDirection: _controller.liftDirection);
    widget.onFoldChanged?.call(_controller.state);
  }

  /// Terminates running spring ticker.
  void _stopSpring() {
    _springTicker?.stop();
    _springSim = null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = DuoFoldTheme.of(context);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: widget.enabled ? _onPanStart : null,
      onPanUpdate: widget.enabled ? _onPanUpdate : null,
      onPanEnd: widget.enabled ? _onPanEnd : null,
      child: DuoFoldMotion(
        controller: _controller,
        mode: widget.mode ?? theme.mode,
        parameters: widget.parameters ?? theme.parameters,
        effects: widget.effects ?? theme.effects,
        quality: widget.quality ?? theme.quality,
        enabled: widget.enabled,
        child: widget.child,
      ),
    );
  }
}
