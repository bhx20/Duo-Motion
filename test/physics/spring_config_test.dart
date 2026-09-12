import 'package:duo_motion/src/physics/spring_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SpringConfig', () {
    group('presets exist', () {
      test('snappy preset has expected values', () {
        expect(SpringConfig.snappy.stiffness, 300.0);
        expect(SpringConfig.snappy.dampingRatio, 0.75);
        expect(SpringConfig.snappy.mass, 1.0);
      });

      test('gentle preset has expected values', () {
        expect(SpringConfig.gentle.stiffness, 120.0);
        expect(SpringConfig.gentle.dampingRatio, 0.95);
        expect(SpringConfig.gentle.mass, 1.0);
      });

      test('bouncy preset has expected values', () {
        expect(SpringConfig.bouncy.stiffness, 250.0);
        expect(SpringConfig.bouncy.dampingRatio, 0.55);
        expect(SpringConfig.bouncy.mass, 1.0);
      });

      test('default has documented values', () {
        const config = SpringConfig();
        expect(config.stiffness, 180.0);
        expect(config.dampingRatio, 0.85);
        expect(config.mass, 1.0);
        expect(config.restTolerance, 0.01);
      });
    });

    group('presets are distinct', () {
      test('snappy != gentle != bouncy', () {
        expect(SpringConfig.snappy, isNot(equals(SpringConfig.gentle)));
        expect(SpringConfig.gentle, isNot(equals(SpringConfig.bouncy)));
        expect(SpringConfig.bouncy, isNot(equals(SpringConfig.snappy)));
      });
    });

    group('value equality', () {
      test('identical configs are equal', () {
        const a = SpringConfig(stiffness: 200, dampingRatio: 0.8, mass: 1.5);
        const b = SpringConfig(stiffness: 200, dampingRatio: 0.8, mass: 1.5);
        expect(a, equals(b));
      });

      test('different stiffness not equal', () {
        const a = SpringConfig(stiffness: 200);
        const b = SpringConfig(stiffness: 300);
        expect(a, isNot(equals(b)));
      });

      test('different dampingRatio not equal', () {
        const a = SpringConfig(dampingRatio: 0.5);
        const b = SpringConfig(dampingRatio: 1.0);
        expect(a, isNot(equals(b)));
      });

      test('different mass not equal', () {
        const a = SpringConfig(mass: 1);
        const b = SpringConfig(mass: 2);
        expect(a, isNot(equals(b)));
      });

      test('different restTolerance not equal', () {
        const a = SpringConfig(restTolerance: 0.01);
        const b = SpringConfig(restTolerance: 0.1);
        expect(a, isNot(equals(b)));
      });
    });

    group('hashCode', () {
      test('equal objects have equal hashCodes', () {
        const a = SpringConfig(stiffness: 200, dampingRatio: 0.9);
        const b = SpringConfig(stiffness: 200, dampingRatio: 0.9);
        expect(a.hashCode, b.hashCode);
      });

      test('presets have consistent hashCode', () {
        // Same preset should always produce the same hash.
        expect(SpringConfig.snappy.hashCode, SpringConfig.snappy.hashCode);
      });
    });

    group('toString', () {
      test('includes key fields', () {
        const config = SpringConfig(stiffness: 200, dampingRatio: 0.7, mass: 2);
        final s = config.toString();
        expect(s, contains('SpringConfig'));
        expect(s, contains('200'));
        expect(s, contains('0.7'));
        expect(s, contains('2'));
      });
    });
  });
}
