import 'dart:math' as math;

import 'spring_config.dart';

/// Internal enum classifying the 3 damping regimes of ordinary differential equations.
enum _SpringRegime { underDamped, criticallyDamped, overDamped }

/// Exact analytical ordinary differential equation (ODE) solver for 1D spring physics.
///
/// Unlike Euler numerical integration (which suffers from cumulative floating-point drift,
/// frame-rate sensitivity, and explosive instability under variable frame budgets),
/// [SpringSimulation] computes the **exact closed-form calculus solution** at any continuous
/// timestamp `t`.
///
/// ### Mathematical Foundations
/// The governing second-order linear ODE:
/// $$x''(t) + 2 \zeta \omega_0 x'(t) + \omega_0^2 x(t) = 0$$
///
/// Where:
/// - Undamped natural frequency: $\omega_0 = \sqrt{k / m}$
/// - Initial displacement: $x_0 = \text{startPosition} - \text{targetPosition}$
/// - Initial velocity: $v_0 = \text{startVelocity}$
///
/// The characteristic equation roots $r = -\zeta \omega_0 \pm \omega_0 \sqrt{\zeta^2 - 1}$
/// give rise to three exact physical regimes:
///
/// 1. **Under-Damped ($\zeta < 1.0$)**:
///    Complex conjugate roots: $r = -\zeta \omega_0 \pm i \omega_d$, where $\omega_d = \omega_0 \sqrt{1 - \zeta^2}$.
///    $$x(t) = e^{-\zeta \omega_0 t} \left( c_1 \cos(\omega_d t) + c_2 \sin(\omega_d t) \right)$$
///    With initial conditions: $c_1 = x_0$, $c_2 = \frac{v_0 + \zeta \omega_0 x_0}{\omega_d}$.
///
/// 2. **Critically Damped ($\zeta = 1.0$)**:
///    Repeated real root: $r = -\omega_0$.
///    $$x(t) = (c_1 + c_2 t) e^{-\omega_0 t}$$
///    With initial conditions: $c_1 = x_0$, $c_2 = v_0 + \omega_0 x_0$.
///
/// 3. **Over-Damped ($\zeta > 1.0$)**:
///    Two distinct negative real roots: $r_{1,2} = -\omega_0 (\zeta \pm \sqrt{\zeta^2 - 1})$.
///    $$x(t) = c_1 e^{r_1 t} + c_2 e^{r_2 t}$$
///    With initial conditions: $c_1 = \frac{v_0 - x_0 r_2}{r_1 - r_2}$, $c_2 = x_0 - c_1$.
class SpringSimulation {
  /// Creates an analytical spring simulation from [startPosition] toward
  /// [targetPosition] with an initial [startVelocity].
  SpringSimulation({
    required this.startPosition,
    required this.targetPosition,
    required this.startVelocity,
    this.config = const SpringConfig(),
  }) {
    final k = config.stiffness;
    final m = config.mass;
    final zeta = config.dampingRatio;

    // Undamped natural angular frequency
    _w0 = math.sqrt(k / m);
    // Initial displacement relative to target
    _x0 = startPosition - targetPosition;
    _v0 = startVelocity;

    if (zeta < 1.0) {
      // Regime 1: Under-damped (oscillatory)
      _regime = _SpringRegime.underDamped;
      _wD = _w0 * math.sqrt(1.0 - zeta * zeta);
      _c1 = _x0;
      _c2 = (_v0 + zeta * _w0 * _x0) / _wD;
      _r1 = 0;
      _r2 = 0;
    } else if ((zeta - 1.0).abs() < 1e-9) {
      // Regime 2: Critically damped (fastest non-oscillatory return)
      _regime = _SpringRegime.criticallyDamped;
      _wD = 0;
      _c1 = _x0;
      _c2 = _v0 + _w0 * _x0;
      _r1 = 0;
      _r2 = 0;
    } else {
      // Regime 3: Over-damped (heavily cushioned non-oscillatory return)
      _regime = _SpringRegime.overDamped;
      final disc = math.sqrt(zeta * zeta - 1.0);
      _r1 = -_w0 * (zeta + disc);
      _r2 = -_w0 * (zeta - disc);
      _c1 = (_v0 - _x0 * _r2) / (_r1 - _r2);
      _c2 = _x0 - _c1;
      _wD = 0;
    }
  }

  /// Initial position at time t=0.
  final double startPosition;

  /// Target equilibrium position the spring pulls toward.
  final double targetPosition;

  /// Initial velocity at time t=0.
  final double startVelocity;

  /// Physical spring tuning parameters.
  final SpringConfig config;

  late final double _w0;
  late final double _wD;
  late final double _x0;
  late final double _v0;
  late final double _c1;
  late final double _c2;
  late final double _r1;
  late final double _r2;
  late final _SpringRegime _regime;

  /// Exact position at continuous time [t] seconds.
  double position(double t) {
    if (t <= 0) return startPosition;
    return targetPosition + _displacement(t);
  }

  /// Exact velocity at continuous time [t] seconds (first time derivative of position).
  double velocity(double t) {
    if (t <= 0) return startVelocity;
    return switch (_regime) {
      _SpringRegime.underDamped => _velocityUnderDamped(t),
      _SpringRegime.criticallyDamped => _velocityCritical(t),
      _SpringRegime.overDamped => _velocityOverDamped(t),
    };
  }

  /// Evaluates whether the spring has settled close enough to rest to terminate the animation loop.
  bool isDone(double t) {
    final dist = (position(t) - targetPosition).abs();
    final vel = velocity(t).abs();
    return dist < config.restTolerance &&
        vel < config.restTolerance * 10;
  }

  double _displacement(double t) => switch (_regime) {
    _SpringRegime.underDamped => _displacementUnderDamped(t),
    _SpringRegime.criticallyDamped => _displacementCritical(t),
    _SpringRegime.overDamped => _displacementOverDamped(t),
  };

  // Under-damped position: x(t) = exp(-zeta*w0*t) * (c1*cos(wD*t) + c2*sin(wD*t))
  double _displacementUnderDamped(double t) {
    final decay = math.exp(-config.dampingRatio * _w0 * t);
    return decay * (_c1 * math.cos(_wD * t) + _c2 * math.sin(_wD * t));
  }

  // Under-damped velocity: product rule derivative d/dt [ decay(t) * trig(t) ]
  double _velocityUnderDamped(double t) {
    final zeta = config.dampingRatio;
    final decay = math.exp(-zeta * _w0 * t);
    final cosVal = math.cos(_wD * t);
    final sinVal = math.sin(_wD * t);
    final dDecay = -zeta * _w0 * decay;
    final dTrig = _wD * (-_c1 * sinVal + _c2 * cosVal);
    return dDecay * (_c1 * cosVal + _c2 * sinVal) + decay * dTrig;
  }

  // Critically damped position: x(t) = (c1 + c2*t) * exp(-w0*t)
  double _displacementCritical(double t) {
    final decay = math.exp(-_w0 * t);
    return decay * (_c1 + _c2 * t);
  }

  // Critically damped velocity: d/dt [ (c1 + c2*t) * exp(-w0*t) ]
  double _velocityCritical(double t) {
    final decay = math.exp(-_w0 * t);
    return decay * (_c2 - _w0 * (_c1 + _c2 * t));
  }

  // Over-damped position: x(t) = c1*exp(r1*t) + c2*exp(r2*t)
  double _displacementOverDamped(double t) {
    return _c1 * math.exp(_r1 * t) + _c2 * math.exp(_r2 * t);
  }

  // Over-damped velocity: d/dt [ c1*exp(r1*t) + c2*exp(r2*t) ]
  double _velocityOverDamped(double t) {
    return _c1 * _r1 * math.exp(_r1 * t) + _c2 * _r2 * math.exp(_r2 * t);
  }
}
