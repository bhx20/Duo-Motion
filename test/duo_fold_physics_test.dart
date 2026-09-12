import 'package:duo_motion/duo_motion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DuoFoldPhysics', () {
    test('value equality and defaults', () {
      const p1 = DuoFoldPhysics();
      const p2 = DuoFoldPhysics();
      expect(p1, equals(p2));
      expect(p1.hashCode, equals(p2.hashCode));
      expect(DuoFoldPhysics.snappy.stiffness, equals(300.0));
      expect(DuoFoldPhysics.gentle.dampingRatio, equals(0.95));
      expect(DuoFoldPhysics.bouncy.dampingRatio, equals(0.55));
    });
  });

  group('DuoFoldSpringSimulation', () {
    test('starts at initial position and velocity', () {
      final sim = DuoFoldSpringSimulation(
        startPosition: 30.0,
        targetPosition: 0.0,
        startVelocity: 10.0,
        physics: const DuoFoldPhysics(),
      );

      expect(sim.position(0.0), equals(30.0));
      expect(sim.velocity(0.0), equals(10.0));
    });

    test('converges to target position over time', () {
      final sim = DuoFoldSpringSimulation(
        startPosition: 45.0,
        targetPosition: 0.0,
        startVelocity: 0.0,
        physics: DuoFoldPhysics.snappy,
      );

      final pos1 = sim.position(0.1);
      final pos2 = sim.position(0.5);
      final pos3 = sim.position(2.0);

      expect(pos1, lessThan(45.0));
      expect(pos2, lessThan(pos1));
      expect(pos3, closeTo(0.0, 0.01));
      expect(sim.isDone(2.0), isTrue);
    });

    test('under-damped spring produces oscillation', () {
      final sim = DuoFoldSpringSimulation(
        startPosition: 20.0,
        targetPosition: 0.0,
        startVelocity: 0.0,
        physics: DuoFoldPhysics.bouncy,
      );

      // Under-damped spring moves past target (negative position) before returning
      bool crossedTarget = false;
      for (double t = 0; t <= 1.5; t += 0.02) {
        if (sim.position(t) < -0.1) {
          crossedTarget = true;
          break;
        }
      }
      expect(crossedTarget, isTrue);
    });
  });
}
