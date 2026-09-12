/// Physical tuning parameters governing second-order harmonic spring oscillations.
///
/// Models a classic damped mass-spring system:
/// $$m \frac{d^2x}{dt^2} + c \frac{dx}{dt} + k x = 0$$
///
/// Where:
/// - $m$ is the [mass].
/// - $k$ is the [stiffness] (spring constant).
/// - $\zeta$ (zeta) is the [dampingRatio], which dictates whether the spring oscillates:
///   - $\zeta < 1.0$: **Under-damped** (bounces back and forth past equilibrium before stopping).
///   - $\zeta = 1.0$: **Critically damped** (fastest possible return to rest without any overshoot).
///   - $\zeta > 1.0$: **Over-damped** (sluggish, heavily cushioned return without overshoot).
class SpringConfig {
  /// Creates a spring configuration.
  const SpringConfig({
    this.stiffness = 180.0,
    this.dampingRatio = 0.85,
    this.mass = 1.0,
    this.restTolerance = 0.01,
  });

  /// Snappy preset: rapid response with subtle organic bounce.
  ///
  /// Ideal for interactive gesture releases and swift card snaps.
  static const SpringConfig snappy = SpringConfig(
    stiffness: 300.0,
    dampingRatio: 0.75,
    mass: 1.0,
  );

  /// Gentle preset: smooth, cushioned settling with almost no oscillation.
  ///
  /// Ideal for subtle atmospheric animations and larger screen fold transitions.
  static const SpringConfig gentle = SpringConfig(
    stiffness: 120.0,
    dampingRatio: 0.95,
    mass: 1.0,
  );

  /// Bouncy preset: playful, pronounced spring oscillation.
  ///
  /// Features prominent overshoot and several rebound cycles before settling.
  static const SpringConfig bouncy = SpringConfig(
    stiffness: 250.0,
    dampingRatio: 0.55,
    mass: 1.0,
  );

  /// Stiff preset: taut, high-tension return with instantaneous settling.
  static const SpringConfig stiff = SpringConfig(
    stiffness: 400.0,
    dampingRatio: 0.90,
    mass: 1.0,
  );

  /// Default balanced general-purpose spring configuration.
  static const SpringConfig defaultConfig = SpringConfig();

  /// Spring stiffness coefficient ($k$).
  ///
  /// Higher values increase the restoring pull force, accelerating the spring toward target.
  final double stiffness;

  /// Dimensionless damping ratio ($\zeta$).
  ///
  /// Governs the decay rate of the oscillation.
  final double dampingRatio;

  /// Effective inertial mass ($m$) attached to the spring.
  final double mass;

  /// Distance threshold below which motion is declared finished and simulation stops.
  final double restTolerance;

  @override
  bool operator ==(Object other) =>
      other is SpringConfig &&
      other.stiffness == stiffness &&
      other.dampingRatio == dampingRatio &&
      other.mass == mass &&
      other.restTolerance == restTolerance;

  @override
  int get hashCode => Object.hash(stiffness, dampingRatio, mass, restTolerance);

  @override
  String toString() =>
      'SpringConfig(k: $stiffness, zeta: $dampingRatio, m: $mass)';
}
