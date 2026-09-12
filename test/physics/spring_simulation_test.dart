import 'package:duo_motion/src/physics/spring_config.dart';
import 'package:duo_motion/src/physics/spring_simulation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SpringSimulation', () {
    // -----------------------------------------------------------------------
    // Initial conditions
    // -----------------------------------------------------------------------
    group('initial conditions', () {
      test('position(0) == startPosition for under-damped', () {
        final sim = SpringSimulation(
          startPosition: 10,
          targetPosition: 0,
          startVelocity: 5,
          config: const SpringConfig(dampingRatio: 0.5),
        );
        expect(sim.position(0), closeTo(10, 1e-9));
      });

      test('velocity(0) == startVelocity for under-damped', () {
        final sim = SpringSimulation(
          startPosition: 10,
          targetPosition: 0,
          startVelocity: 5,
          config: const SpringConfig(dampingRatio: 0.5),
        );
        expect(sim.velocity(0), closeTo(5, 1e-9));
      });

      test('position(0) == startPosition for critically damped', () {
        final sim = SpringSimulation(
          startPosition: 10,
          targetPosition: 0,
          startVelocity: -3,
          config: const SpringConfig(dampingRatio: 1.0),
        );
        expect(sim.position(0), closeTo(10, 1e-9));
      });

      test('velocity(0) == startVelocity for critically damped', () {
        final sim = SpringSimulation(
          startPosition: 10,
          targetPosition: 0,
          startVelocity: -3,
          config: const SpringConfig(dampingRatio: 1.0),
        );
        expect(sim.velocity(0), closeTo(-3, 1e-9));
      });

      test('position(0) == startPosition for over-damped', () {
        final sim = SpringSimulation(
          startPosition: 10,
          targetPosition: 0,
          startVelocity: 0,
          config: const SpringConfig(dampingRatio: 1.5),
        );
        expect(sim.position(0), closeTo(10, 1e-9));
      });

      test('velocity(0) == startVelocity for over-damped', () {
        final sim = SpringSimulation(
          startPosition: 10,
          targetPosition: 0,
          startVelocity: -2,
          config: const SpringConfig(dampingRatio: 1.5),
        );
        expect(sim.velocity(0), closeTo(-2, 1e-9));
      });
    });

    // -----------------------------------------------------------------------
    // Under-damped (dampingRatio 0.5): oscillation past target, converges
    // -----------------------------------------------------------------------
    group('under-damped (dampingRatio 0.5)', () {
      late SpringSimulation sim;

      setUp(() {
        sim = SpringSimulation(
          startPosition: 10,
          targetPosition: 0,
          startVelocity: 0,
          config: const SpringConfig(
            stiffness: 180,
            dampingRatio: 0.5,
            mass: 1,
          ),
        );
      });

      test('oscillates past target', () {
        // An under-damped spring overshoots: at some time the position
        // should be on the other side of the target.
        var foundOvershoot = false;
        for (var t = 0.01; t < 2.0; t += 0.01) {
          if (sim.position(t) < 0) {
            foundOvershoot = true;
            break;
          }
        }
        expect(foundOvershoot, isTrue, reason: 'Under-damped should overshoot');
      });

      test('eventually converges to target', () {
        final pos = sim.position(5);
        expect(pos, closeTo(0, 0.01));
      });

      test('isDone after enough time', () {
        expect(sim.isDone(10), isTrue);
      });

      test('is not done initially', () {
        expect(sim.isDone(0), isFalse);
      });
    });

    // -----------------------------------------------------------------------
    // Critically damped (dampingRatio 1.0): fastest return, no oscillation
    // -----------------------------------------------------------------------
    group('critically damped (dampingRatio 1.0)', () {
      late SpringSimulation sim;

      setUp(() {
        sim = SpringSimulation(
          startPosition: 10,
          targetPosition: 0,
          startVelocity: 0,
          config: const SpringConfig(
            stiffness: 180,
            dampingRatio: 1.0,
            mass: 1,
          ),
        );
      });

      test('no oscillation past target', () {
        // Critically damped: position should never go below target (0)
        // when starting above it with zero initial velocity.
        for (var t = 0.01; t < 5.0; t += 0.01) {
          expect(
            sim.position(t),
            greaterThanOrEqualTo(-0.001),
            reason: 'Critically damped should not oscillate past target at t=$t',
          );
        }
      });

      test('converges to target', () {
        final pos = sim.position(5);
        expect(pos, closeTo(0, 0.01));
      });

      test('isDone after enough time', () {
        expect(sim.isDone(10), isTrue);
      });

      test('fastest return compared to over-damped', () {
        // Critically damped should settle faster than over-damped.
        final overDamped = SpringSimulation(
          startPosition: 10,
          targetPosition: 0,
          startVelocity: 0,
          config: const SpringConfig(
            stiffness: 180,
            dampingRatio: 1.5,
            mass: 1,
          ),
        );

        // Find time-to-settle for each.
        double settleTime(SpringSimulation s) {
          for (var t = 0.01; t < 20.0; t += 0.01) {
            if (s.isDone(t)) return t;
          }
          return 20.0;
        }

        final criticalSettle = settleTime(sim);
        final overSettle = settleTime(overDamped);
        expect(
          criticalSettle,
          lessThan(overSettle),
          reason: 'Critically damped should settle faster than over-damped',
        );
      });
    });

    // -----------------------------------------------------------------------
    // Over-damped (dampingRatio 1.5): slow return, NO oscillation
    // Bug 4 regression test: the old code wrongly used the critically
    // damped formula.
    // -----------------------------------------------------------------------
    group('over-damped (dampingRatio 1.5) — Bug 4 regression', () {
      late SpringSimulation sim;

      setUp(() {
        sim = SpringSimulation(
          startPosition: 10,
          targetPosition: 0,
          startVelocity: 0,
          config: const SpringConfig(
            stiffness: 180,
            dampingRatio: 1.5,
            mass: 1,
          ),
        );
      });

      test('no oscillation past target', () {
        // The critical Bug 4 check: over-damped must NOT oscillate.
        // If the old critically-damped formula were used, this would fail.
        for (var t = 0.01; t < 10.0; t += 0.01) {
          expect(
            sim.position(t),
            greaterThanOrEqualTo(-0.001),
            reason: 'Over-damped must not oscillate past target at t=$t. '
                'If this fails, the over-damped formula might be using the '
                'critically-damped branch (Bug 4 regression).',
          );
        }
      });

      test('returns monotonically toward target (no overshoot)', () {
        // Position should decrease monotonically from start toward target.
        var prev = sim.position(0);
        for (var t = 0.05; t < 10.0; t += 0.05) {
          final current = sim.position(t);
          expect(
            current,
            lessThanOrEqualTo(prev + 0.001),
            reason: 'Over-damped position should not increase at t=$t',
          );
          prev = current;
        }
      });

      test('converges to target', () {
        final pos = sim.position(10);
        expect(pos, closeTo(0, 0.01));
      });

      test('isDone after enough time', () {
        expect(sim.isDone(15), isTrue);
      });

      test('slow return compared to critically damped', () {
        final critical = SpringSimulation(
          startPosition: 10,
          targetPosition: 0,
          startVelocity: 0,
          config: const SpringConfig(
            stiffness: 180,
            dampingRatio: 1.0,
            mass: 1,
          ),
        );
        // At an early time, over-damped should still be further from target
        // than critically damped, because it approaches more slowly.
        final tEarly = 0.2;
        expect(
          sim.position(tEarly).abs(),
          greaterThan(critical.position(tEarly).abs()),
          reason:
              'Over-damped should approach target more slowly than critically damped',
        );
      });
    });

    // -----------------------------------------------------------------------
    // Additional edge cases
    // -----------------------------------------------------------------------
    group('edge cases', () {
      test('zero displacement with velocity', () {
        final sim = SpringSimulation(
          startPosition: 0,
          targetPosition: 0,
          startVelocity: 10,
          config: const SpringConfig(dampingRatio: 0.5),
        );
        expect(sim.position(0), closeTo(0, 1e-9));
        expect(sim.velocity(0), closeTo(10, 1e-9));
        // Should eventually return to target.
        expect(sim.isDone(10), isTrue);
      });

      test('already at target with zero velocity is immediately done', () {
        final sim = SpringSimulation(
          startPosition: 0,
          targetPosition: 0,
          startVelocity: 0,
          config: const SpringConfig(),
        );
        expect(sim.isDone(0), isTrue);
      });

      test('negative time returns start conditions', () {
        final sim = SpringSimulation(
          startPosition: 5,
          targetPosition: 0,
          startVelocity: 3,
          config: const SpringConfig(dampingRatio: 0.85),
        );
        expect(sim.position(-1), closeTo(5, 1e-9));
        expect(sim.velocity(-1), closeTo(3, 1e-9));
      });

      test('uses default SpringConfig when none provided', () {
        final sim = SpringSimulation(
          startPosition: 5,
          targetPosition: 0,
          startVelocity: 0,
        );
        expect(sim.config, equals(const SpringConfig()));
      });
    });
  });
}
