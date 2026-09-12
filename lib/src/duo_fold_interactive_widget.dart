import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'duo_fold_controller.dart';
import 'duo_fold_motion_widget.dart';
import 'duo_fold_parameters.dart';
import 'physics/duo_fold_physics.dart';

/// A touch-interactive [DuoFold] that responds to drag and swipe gestures with
/// realistic spring physics and inertia.
class DuoFoldInteractive extends StatefulWidget {
  /// Creates an interactive gesture-driven fold widget.
  const DuoFoldInteractive({
    super.key,
    this.controller,
    this.physics = const DuoFoldPhysics(),
    this.parameters = const DuoFoldParameters(),
    this.enabled = true,
    this.sensitivity = 0.25,
    this.springBack = true,
    this.onFoldStart,
    this.onFoldEnd,
    required this.child,
  });

  /// Optional controller. If not provided, an internal controller is managed.
  final DuoFoldController? controller;

  /// Physics configuration driving spring-back and fling release animations.
  final DuoFoldPhysics physics;

  /// Physical tuning for the fold shader.
  final DuoFoldParameters parameters;

  /// Whether gesture interaction and fold effect are enabled.
  final bool enabled;

  /// Sensitivity factor: degrees of tilt added per pixel of drag.
  final double sensitivity;

  /// Whether the fold springs back to rest (0 degrees) when drag ends.
  final bool springBack;

  /// Callback fired when touch interaction begins.
  final VoidCallback? onFoldStart;

  /// Callback fired when touch interaction and spring animation finish.
  final void Function(double finalTiltDegrees)? onFoldEnd;

  /// The child widget displayed behind the glass fold.
  final Widget child;

  @override
  State<DuoFoldInteractive> createState() => _DuoFoldInteractiveState();
}

class _DuoFoldInteractiveState extends State<DuoFoldInteractive>
    with SingleTickerProviderStateMixin {
  late DuoFoldController _controller;
  bool _ownsController = false;

  Ticker? _ticker;
  DuoFoldSpringSimulation? _simulation;
  Duration _simulationStartTime = Duration.zero;
  double _currentGestureTilt = 0;
  ui.Offset _currentLiftDir = const ui.Offset(-1, 0);

  @override
  void initState() {
    super.initState();
    _initController();
    _ticker = createTicker(_onTick);
  }

  void _initController() {
    if (widget.controller != null) {
      _controller = widget.controller!;
      _ownsController = false;
    } else {
      _controller = DuoFoldController();
      _ownsController = true;
      _controller.start();
    }
  }

  @override
  void didUpdateWidget(DuoFoldInteractive oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      if (_ownsController) {
        _controller.dispose();
      }
      _initController();
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _stopSpringAnimation() {
    _ticker?.stop();
    _simulation = null;
  }

  void _onPanStart(DragStartDetails details) {
    if (!widget.enabled) return;
    _stopSpringAnimation();
    _controller.useSensor = false;
    _currentGestureTilt = _controller.tiltDegrees;
    if (_controller.liftDirection.distance > 0) {
      _currentLiftDir = _controller.liftDirection;
    }
    widget.onFoldStart?.call();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.enabled) return;
    final delta = details.delta;
    if (delta.distanceSquared < 1e-4) return;

    final dragDistance = delta.distance;
    final dragAngleDegrees = dragDistance * widget.sensitivity;

    // Lift direction points from hinge line toward edge rising to viewer.
    // E.g., dragging left (-X) pulls the right edge leftward (liftDir = -1, 0).
    final dirX = delta.dx == 0 ? 0.0 : (delta.dx < 0 ? -1.0 : 1.0);
    final dirY = delta.dy == 0 ? 0.0 : (delta.dy < 0 ? -1.0 : 1.0);

    // Pick dominant drag axis or vector norm for lift direction
    double normX = delta.dx;
    double normY = delta.dy;
    final normLen = math.sqrt(normX * normX + normY * normY);
    if (normLen > 0) {
      normX /= normLen;
      normY /= normLen;
      _currentLiftDir = ui.Offset(normX, normY);
    } else {
      _currentLiftDir = ui.Offset(dirX, dirY);
    }

    _currentGestureTilt = (_currentGestureTilt + dragAngleDegrees)
        .clamp(0.0, DuoFoldParameters.maxTiltDegrees);

    _controller.setManualTilt(
      _currentGestureTilt,
      liftDirection: _currentLiftDir,
    );
  }

  void _onPanEnd(DragEndDetails details) {
    if (!widget.enabled) return;
    final velocity = details.velocity.pixelsPerSecond;
    final speed = velocity.distance * widget.sensitivity;

    final targetTilt = widget.springBack ? 0.0 : _currentGestureTilt;

    _simulation = DuoFoldSpringSimulation(
      startPosition: _controller.tiltDegrees,
      targetPosition: targetTilt,
      startVelocity: speed,
      physics: widget.physics,
    );

    _simulationStartTime = Duration.zero;
    _ticker?.start();
  }

  void _onTick(Duration elapsed) {
    final sim = _simulation;
    if (sim == null) return;

    if (_simulationStartTime == Duration.zero) {
      _simulationStartTime = elapsed;
    }

    final tSeconds =
        (elapsed - _simulationStartTime).inMicroseconds / 1000000.0;

    final currentTilt = sim.position(tSeconds);
    _controller.setManualTilt(
      currentTilt,
      liftDirection: _currentLiftDir,
    );

    if (sim.isDone(tSeconds)) {
      _stopSpringAnimation();
      _controller.setManualTilt(
        sim.targetPosition,
        liftDirection: _currentLiftDir,
      );
      widget.onFoldEnd?.call(sim.targetPosition);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: widget.enabled ? _onPanStart : null,
      onPanUpdate: widget.enabled ? _onPanUpdate : null,
      onPanEnd: widget.enabled ? _onPanEnd : null,
      behavior: HitTestBehavior.opaque,
      child: DuoFoldMotion(
        controller: _controller,
        parameters: widget.parameters,
        enabled: widget.enabled,
        child: widget.child,
      ),
    );
  }
}
