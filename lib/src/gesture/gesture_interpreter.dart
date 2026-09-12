import 'dart:ui' as ui;

import '../core/fold_parameters.dart';
import '../core/fold_state.dart';

/// Interprets raw 2D screen gestures (drags, pans, flings) into signed 1D fold state changes.
///
/// Converts continuous touch screen coordinates into physical fold angles.
///
/// ### Core Mechanics
/// 1. **Signed Projection**: When dragging across the screen, the 2D pan delta vector
///    `(delta.dx, delta.dy)` is projected via dot product onto the active unit lift vector
///    `(liftDirX, liftDirY)`:
///    $$\text{projection} = \Delta x \cdot \text{liftDirX} + \Delta y \cdot \text{liftDirY}$$
///    - Positive projection moves *with* the lift direction, opening the fold further.
///    - Negative projection moves *against* the lift direction, closing the fold toward flat.
///
/// 2. **Bidirectional Inversion**: When the user drags past zero (closing the fold fully),
///    subsequent drag in the opposite direction dynamically flips the lift direction,
///    opening the card from the opposite edge.
///
/// 3. **Signed Velocity Projection**: Fling velocity in pixels/second is projected onto
///    the lift axis, yielding a signed velocity that accurately seeds the [SpringSimulation].
class GestureInterpreter {
  /// Creates an interpreter with the given drag [sensitivity] (degrees per pixel)
  /// and optional [maxTiltDegrees] clamp ceiling.
  GestureInterpreter({
    this.sensitivity = 0.25,
    this.maxTiltDegrees = FoldParameters.maxTiltDegrees,
  });

  /// Scaling factor converting screen drag pixels along the lift axis into degrees of fold tilt.
  final double sensitivity;

  /// Maximum allowed tilt angle in degrees before clamping.
  final double maxTiltDegrees;

  ui.Offset _currentLiftDir = const ui.Offset(-1, 0);
  double _currentTilt = 0.0;

  /// The current fold tilt angle being tracked, in degrees.
  double get currentTilt => _currentTilt;

  /// The current unit lift direction vector being tracked.
  ui.Offset get currentLiftDir => _currentLiftDir;

  /// Invoked at the start of a touch pan gesture.
  ///
  /// Captures the initial fold pose so the user's gesture picks up smoothly
  /// from the card's current position without jumping back to zero.
  void onDragStart(FoldState currentState) {
    _currentTilt = currentState.tiltDegrees;
    if (!currentState.isAtRest) {
      _currentLiftDir = currentState.liftDirection;
    }
  }

  /// Invoked on every touch drag update event.
  ///
  /// Projects [delta] onto the active lift axis, applies sensitivity scaling,
  /// updates [currentTilt], handles reverse edge flips, and returns the updated [FoldState].
  FoldState onDragUpdate(ui.Offset delta) {
    if (delta.distanceSquared < 1e-4) {
      return FoldState(
        tiltDegrees: _currentTilt,
        liftDirX: _currentLiftDir.dx,
        liftDirY: _currentLiftDir.dy,
      );
    }

    // Dot product projection of drag delta onto the current lift direction
    final projection =
        delta.dx * _currentLiftDir.dx + delta.dy * _currentLiftDir.dy;

    // If fold reached flat (0°) and drag continues in opposite direction, invert hinge
    if (_currentTilt < 1.0 && projection < 0) {
      final len = delta.distance;
      if (len > 1e-6) {
        _currentLiftDir = ui.Offset(delta.dx / len, delta.dy / len);
      }
      _currentTilt = (len * sensitivity)
          .clamp(0.0, maxTiltDegrees);
    } else {
      // Normal drag along or against the fold axis
      final tiltDelta = projection * sensitivity;
      _currentTilt = (_currentTilt + tiltDelta)
          .clamp(0.0, maxTiltDegrees);
    }

    return FoldState(
      tiltDegrees: _currentTilt,
      liftDirX: _currentLiftDir.dx,
      liftDirY: _currentLiftDir.dy,
    );
  }

  /// Invoked when the user lifts their finger or releases a fling gesture.
  ///
  /// Computes the signed velocity along the fold axis, providing the initial
  /// conditions needed by the spring physics simulation.
  ({FoldState state, double signedVelocity}) onDragEnd(
    ui.Offset velocityPixelsPerSecond,
  ) {
    // Project velocity vector onto the fold lift direction
    final projectedVelocity = (velocityPixelsPerSecond.dx * _currentLiftDir.dx +
            velocityPixelsPerSecond.dy * _currentLiftDir.dy) *
        sensitivity;

    return (
      state: FoldState(
        tiltDegrees: _currentTilt,
        liftDirX: _currentLiftDir.dx,
        liftDirY: _currentLiftDir.dy,
      ),
      signedVelocity: projectedVelocity,
    );
  }
}
