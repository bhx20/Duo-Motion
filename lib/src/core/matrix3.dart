import 'dart:math' as math;

/// Minimal high-performance 3x3 matrix math utilities for device orientation filtering.
///
/// Designed with zero allocations where possible, operating directly on flat `List<double>`
/// in row-major order:
/// ```
/// [ m00, m01, m02,
///   m10, m11, m12,
///   m20, m21, m22 ]
/// ```
///
/// ### Screen Axis Representation
/// The three column vectors define the orthogonal coordinate system of the mobile display:
/// - Column 0 (`m00, m10, m20`): **Screen-Right** axis (`+X`).
/// - Column 1 (`m01, m11, m21`): **Screen-Up** axis (`+Y`).
/// - Column 2 (`m02, m12, m22`): **Screen-Normal** axis (`+Z`, pointing directly out of the screen toward the user).
abstract final class Matrix3 {
  /// The standard 3x3 identity matrix pose (no rotation).
  static const List<double> identity = <double>[1, 0, 0, 0, 1, 0, 0, 0, 1];

  /// Returns the transpose of matrix [m].
  ///
  /// For any valid orthogonal 3D rotation matrix, the transpose is mathematically
  /// identical to its matrix inverse (`R^T = R^(-1)`).
  static List<double> transpose(List<double> m) {
    assert(m.length == 9, 'expected a 3x3 matrix, got ${m.length} values');
    return <double>[m[0], m[3], m[6], m[1], m[4], m[7], m[2], m[5], m[8]];
  }

  /// Multiplies two 3x3 matrices: computes `a * b`.
  ///
  /// Composes rotation `b` followed by rotation `a`.
  static List<double> multiply(List<double> a, List<double> b) {
    assert(a.length == 9 && b.length == 9, 'both operands must be 3x3');
    final out = List<double>.filled(9, 0);
    for (var row = 0; row < 3; row++) {
      for (var col = 0; col < 3; col++) {
        out[row * 3 + col] =
            a[row * 3] * b[col] +
            a[row * 3 + 1] * b[3 + col] +
            a[row * 3 + 2] * b[6 + col];
      }
    }
    return out;
  }

  /// Generates an elemental 3D rotation matrix of [radians] about the screen-space Y (vertical) axis.
  ///
  /// ### Sign Convention
  /// Positive rotation angles swing the screen normal vector toward screen-right.
  /// In the context of `duo_motion`, this corresponds to the right edge of the card
  /// moving backwards away from the viewer.
  static List<double> rotationAboutY(double radians) {
    final c = math.cos(radians);
    final s = math.sin(radians);
    return <double>[c, 0, s, 0, 1, 0, -s, 0, c];
  }

  /// Extracts the horizontal tilt excursion angle of the screen normal vector, in radians.
  ///
  /// [relative] is the current orientation matrix expressed relative to the calibrated reference frame:
  /// `R_relative = transpose(R_reference) * R_current`.
  ///
  /// Inspecting the screen-normal column (index 2 for X and index 8 for Z) via `atan2`
  /// directly yields the horizontal tilt angle without Euler-angle gimbal lock.
  static double screenNormalTilt(List<double> relative) {
    assert(relative.length == 9, 'expected a 3x3 matrix');
    return math.atan2(relative[2], relative[8]);
  }

  /// Wraps an angle in radians into the principal circle range `[-pi, +pi]`.
  ///
  /// Uses Euclidean modulo arithmetic to guarantee stable convergence when device
  /// rotation crosses the boundary discontinuity.
  static double wrapAngle(double radians) {
    var x = radians % (2 * math.pi);
    if (x > math.pi) {
      x -= 2 * math.pi;
    }
    return x;
  }
}
