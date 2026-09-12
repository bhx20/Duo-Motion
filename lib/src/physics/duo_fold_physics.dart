import 'dart:math' as math;

/// Physical spring configuration for gesture fling and spring-back fold animations.
class DuoFoldPhysics {
  /// Creates a spring configuration.
  const DuoFoldPhysics({
    this.stiffness = 180.0,
    this.dampingRatio = 0.85,
    this.mass = 1.0,
    this.restTolerance = 0.01,
  });

  /// Snappy default spring physics configuration.
  static const DuoFoldPhysics snappy = DuoFoldPhysics(
    stiffness: 300.0,
    dampingRatio: 0.75,
    mass: 1.0,
  );

  /// Smooth, gentle default spring physics configuration.
  static const DuoFoldPhysics gentle = DuoFoldPhysics(
    stiffness: 120.0,
    dampingRatio: 0.95,
    mass: 1.0,
  );

  /// Bouncy physics configuration.
  static const DuoFoldPhysics bouncy = DuoFoldPhysics(
    stiffness: 250.0,
    dampingRatio: 0.55,
    mass: 1.0,
  );

  /// Spring stiffness coefficient (k).
  final double stiffness;

  /// Damping ratio (zeta).
  ///
  /// - `< 1.0`: Under-damped (oscillates / bounces).
  /// - `= 1.0`: Critically damped (fastest return without oscillation).
  /// - `> 1.0`: Over-damped (slow return without oscillation).
  final double dampingRatio;

  /// System mass (m).
  final double mass;

  /// Distance threshold at which the spring is considered at rest.
  final double restTolerance;

  @override
  bool operator ==(Object other) {
    return other is DuoFoldPhysics &&
        other.stiffness == stiffness &&
        other.dampingRatio == dampingRatio &&
        other.mass == mass &&
        other.restTolerance == restTolerance;
  }

  @override
  int get hashCode => Object.hash(stiffness, dampingRatio, mass, restTolerance);

  @override
  String toString() =>
      'DuoFoldPhysics(k: $stiffness, dampingRatio: $dampingRatio, mass: $mass)';
}

/// Analytical spring simulation for 1D fold tilt animation.
class DuoFoldSpringSimulation {
  /// Creates a spring simulation starting from [startPosition] to [targetPosition]
  /// with an initial [startVelocity].
  DuoFoldSpringSimulation({
    required this.startPosition,
    required this.targetPosition,
    required this.startVelocity,
    this.physics = const DuoFoldPhysics(),
  }) {
    final k = physics.stiffness;
    final m = physics.mass;
    final zeta = physics.dampingRatio;

    _w0 = math.sqrt(k / m);
    _x0 = startPosition - targetPosition;
    _v0 = startVelocity;

    if (zeta < 1.0) {
      // Under-damped
      _wD = _w0 * math.sqrt(1.0 - zeta * zeta);
      _c1 = _x0;
      _c2 = (_v0 + zeta * _w0 * _x0) / _wD;
    } else {
      // Critically damped or over-damped
      _wD = 0.0;
      _c1 = _x0;
      _c2 = _v0 + _w0 * _x0;
    }
  }

  /// The initial position (tilt degrees) of the simulation.
  final double startPosition;

  /// The equilibrium target position of the simulation.
  final double targetPosition;

  /// The initial velocity of the simulation.
  final double startVelocity;

  /// The physics configuration parameters governing this simulation.
  final DuoFoldPhysics physics;

  late final double _w0;
  late final double _wD;
  late final double _x0;
  late final double _v0;
  late final double _c1;
  late final double _c2;

  /// Computes tilt position at time [tSeconds].
  double position(double tSeconds) {
    if (tSeconds <= 0) return startPosition;
    final zeta = physics.dampingRatio;

    double displacement;
    if (zeta < 1.0) {
      final decay = math.exp(-zeta * _w0 * tSeconds);
      displacement = decay * (_c1 * math.cos(_wD * tSeconds) + _c2 * math.sin(_wD * tSeconds));
    } else {
      final decay = math.exp(-_w0 * tSeconds);
      displacement = decay * (_c1 + _c2 * tSeconds);
    }
    return targetPosition + displacement;
  }

  /// Computes velocity at time [tSeconds].
  double velocity(double tSeconds) {
    if (tSeconds <= 0) return startVelocity;
    final zeta = physics.dampingRatio;

    if (zeta < 1.0) {
      final decay = math.exp(-zeta * _w0 * tSeconds);
      final cosVal = math.cos(_wD * tSeconds);
      final sinVal = math.sin(_wD * tSeconds);
      final dDecay = -zeta * _w0 * decay;
      final dTrig = _wD * (-_c1 * sinVal + _c2 * cosVal);
      return dDecay * (_c1 * cosVal + _c2 * sinVal) + decay * dTrig;
    } else {
      final decay = math.exp(-_w0 * tSeconds);
      return decay * (_c2 - _w0 * (_c1 + _c2 * tSeconds));
    }
  }

  /// Whether the simulation has settled close enough to rest.
  bool isDone(double tSeconds) {
    final dist = (position(tSeconds) - targetPosition).abs();
    final vel = velocity(tSeconds).abs();
    return dist < physics.restTolerance && vel < physics.restTolerance * 10;
  }
}
