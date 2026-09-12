import 'dart:math' as math;
import 'dart:ui' as ui;

/// Immutable canonical snapshot representing the state of a fold.
///
/// In physical terms, this describes how far the frosted-glass pane has lifted
/// away from the content ([tiltDegrees]), and the 2D direction on the screen
/// plane along which the pane rises ([liftDirX], [liftDirY]).
///
/// ### Coordinate System
/// The lift direction coordinates use fragment/screen space:
/// - `X` points from left to right:
///   - `+1.0` means the fold lifts toward screen-right (hinged on the left).
///   - `-1.0` means the fold lifts toward screen-left (hinged on the right).
/// - `Y` points from top to bottom (y-down standard):
///   - `+1.0` means the fold lifts toward screen-bottom (hinged on top).
///   - `-1.0` means the fold lifts toward screen-top (hinged on bottom).
///
/// The vector `(liftDirX, liftDirY)` is always normalized to unit length `1.0`.
class FoldState {
  /// Creates a [FoldState] with specified tilt in degrees and unit lift direction vector.
  const FoldState({
    required this.tiltDegrees,
    required this.liftDirX,
    required this.liftDirY,
  });

  /// Default rest state with 0 tilt.
  ///
  /// Anchored to hinge on the right edge (lifting leftward: `(-1, 0)`).
  static const FoldState zero = FoldState(
    tiltDegrees: 0,
    liftDirX: -1,
    liftDirY: 0,
  );

  /// Threshold angle below which the fold animation is considered at rest.
  ///
  /// Any tilt below this value triggers the zero-overhead rendering fast-path,
  /// bypassing shader texture allocation and drawing child widgets directly.
  static const double restEpsilon = 0.05;

  /// Tilt magnitude in degrees, always non-negative, clamped to 0..45.
  ///
  /// Represents the physical dihedral angle between the screen surface and the
  /// lifting glass pane.
  final double tiltDegrees;

  /// X component of the unit lift direction in fragment coordinates (y down).
  final double liftDirX;

  /// Y component of the unit lift direction in fragment coordinates (y down).
  final double liftDirY;

  /// Whether the current tilt degree is close enough to zero to be considered at rest.
  ///
  /// Used by widgets to determine whether expensive shader passes can be safely skipped.
  bool get isAtRest => tiltDegrees.abs() < restEpsilon;

  /// The lift direction vector represented as a standard Flutter 2D [ui.Offset].
  ui.Offset get liftDirection => ui.Offset(liftDirX, liftDirY);

  /// Returns a new [FoldState] with updated tilt degrees while preserving the lift vector.
  FoldState withTilt(double degrees) => FoldState(
    tiltDegrees: degrees,
    liftDirX: liftDirX,
    liftDirY: liftDirY,
  );

  /// Returns a new [FoldState] with updated lift direction coordinates while preserving tilt.
  FoldState withDirection(double x, double y) => FoldState(
    tiltDegrees: tiltDegrees,
    liftDirX: x,
    liftDirY: y,
  );

  /// Linearly interpolates between two [FoldState] instances.
  ///
  /// - Interpolates the scalar [tiltDegrees] linearly using factor [t].
  /// - Blends the 2D lift direction vectors and renormalizes the result to
  ///   guarantee unit length, preventing distortion during diagonal transitions.
  static FoldState lerp(FoldState a, FoldState b, double t) {
    // Linear interpolation of the tilt angle magnitude
    final tilt = a.tiltDegrees + (b.tiltDegrees - a.tiltDegrees) * t;

    // Vector lerp of the lift direction components
    final ax = a.liftDirX;
    final ay = a.liftDirY;
    final bx = b.liftDirX;
    final by = b.liftDirY;

    var dx = ax + (bx - ax) * t;
    var dy = ay + (by - ay) * t;

    // Renormalize the interpolated vector to maintain unit length
    final len = math.sqrt(dx * dx + dy * dy);
    if (len > 1e-9) {
      dx /= len;
      dy /= len;
    } else {
      // Fallback if vectors cancel out (opposite directions at t = 0.5)
      dx = FoldState.zero.liftDirX;
      dy = FoldState.zero.liftDirY;
    }

    return FoldState(tiltDegrees: tilt, liftDirX: dx, liftDirY: dy);
  }

  @override
  bool operator ==(Object other) =>
      other is FoldState &&
      other.tiltDegrees == tiltDegrees &&
      other.liftDirX == liftDirX &&
      other.liftDirY == liftDirY;

  @override
  int get hashCode => Object.hash(tiltDegrees, liftDirX, liftDirY);

  @override
  String toString() =>
      'FoldState(${tiltDegrees.toStringAsFixed(2)}deg, '
      'lift: (${liftDirX.toStringAsFixed(2)}, ${liftDirY.toStringAsFixed(2)}))';
}
