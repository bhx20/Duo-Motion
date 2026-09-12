import 'dart:math' as math;

/// Pure mathematical formulations replicating the optical ray-caster on CPU.
///
/// Contains zero dependencies on `dart:ui`, Flutter widgets, or GPU context.
/// The Impeller fragment shader performs identical ray-plane intersection and
/// photometric attenuation calculations per pixel; this class provides CPU-side
/// parity for unit testing, previews, and analytical validation.
abstract final class Optics {
  /// Calculates the physical vertical separation gap between the angled glass pane
  /// and the content plane at a distance [d] from the hinge anchor line.
  ///
  /// Geometry: `gap = d * sin(tilt)`
  static double gap(double d, double tiltRadians) => d * math.sin(tiltRadians);

  /// Calculates the apparent 2D foreshortening displacement of a glass surface point
  /// when projected vertically onto the underlying content plane.
  ///
  /// As the pane tilts by angle `theta`, a point at distance `d` moves inward toward
  /// the hinge line by: `displacement = d * (1.0 - cos(theta))`
  static double glassDisplacement(double d, double tiltRadians) =>
      d * (1.0 - math.cos(tiltRadians));

  /// Computes the effective optical blur radius in pixels.
  ///
  /// Blends the variable separation frost ([gap] * [blurSpread]) with the
  /// baseline surface frosted glass texture ([baseBlurPx]):
  /// `radius = blurSpread * gap + baseBlurPx`
  static double blurRadius(double gap, double blurSpread, double baseBlurPx) =>
      blurSpread * gap + baseBlurPx;

  /// Calculates the photometric light transmittance through the frosted glass.
  ///
  /// As the diffusion blur increases, scattered light rays dissipate into ambient haze,
  /// reducing the direct light transmission:
  /// `attenuation = max(1.0 - darkening * radius, 0.0)`
  ///
  /// Returns a fractional transmittance value clamped between `0.0` (fully scattered)
  /// and `1.0` (crystal clear).
  static double attenuation(double radius, double darkening) =>
      math.max(1.0 - darkening * radius, 0.0);

  /// Computes where an eye-through-glass viewing ray intersects the content plane (`Z = 0`).
  ///
  /// Parameters:
  /// - `(glassX, glassY)`: 2D coordinates on the glass surface.
  /// - `gap`: 3D vertical separation between glass and content plane.
  /// - `(eyeX, eyeY)`: Center of perspective projection (viewer's eye position).
  /// - `eyeDistance`: Distance of viewer from the screen.
  ///
  /// Returns `null` if the glass position is behind or collinear with the viewer's eye.
  static ({double x, double y})? rayHit({
    required double glassX,
    required double glassY,
    required double gap,
    required double eyeX,
    required double eyeY,
    required double eyeDistance,
  }) {
    final depth = eyeDistance - gap;
    if (depth <= 1e-3) return null;
    final t = eyeDistance / depth;
    return (
      x: eyeX + (glassX - eyeX) * t,
      y: eyeY + (glassY - eyeY) * t,
    );
  }
}
