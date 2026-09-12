import 'package:duo_motion/src/core/snap_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SnapConfig', () {
    group('nearestSnap', () {
      test('returns angle when within threshold', () {
        const config = SnapConfig(angles: [0, 15, 30, 45], threshold: 3);
        // 14.0 is within 3 of 15.
        expect(config.nearestSnap(14.0), 15.0);
      });

      test('returns null when outside threshold', () {
        const config = SnapConfig(angles: [0, 15, 30, 45], threshold: 3);
        // 10.0 is 5 away from both 15 and 0.
        expect(config.nearestSnap(10.0), isNull);
      });

      test('returns null for empty angles', () {
        const config = SnapConfig(angles: [], threshold: 3);
        expect(config.nearestSnap(10.0), isNull);
      });

      test('returns exact angle when tilt is exactly on it', () {
        const config = SnapConfig(angles: [0, 15, 30, 45]);
        expect(config.nearestSnap(15.0), 15.0);
      });

      test('returns closest angle at boundary', () {
        const config = SnapConfig(angles: [0, 15, 30], threshold: 3);
        // 3.0 is exactly at threshold distance from 0.
        expect(config.nearestSnap(3.0), 0.0);
      });

      test('picks the closest among multiple candidates', () {
        const config = SnapConfig(angles: [0, 10, 20], threshold: 6);
        // 9.0 is 1 from 10, 9 from 0, 11 from 20.
        expect(config.nearestSnap(9.0), 10.0);
      });
    });

    group('flingTarget', () {
      test('positive velocity picks next higher angle', () {
        const config = SnapConfig(angles: [0, 15, 30, 45]);
        expect(config.flingTarget(10, 100), 15);
      });

      test('negative velocity picks next lower angle', () {
        const config = SnapConfig(angles: [0, 15, 30, 45]);
        expect(config.flingTarget(20, -100), 15);
      });

      test('positive velocity at top boundary clamps to last', () {
        const config = SnapConfig(angles: [0, 15, 30, 45]);
        expect(config.flingTarget(44, 100), 45);
      });

      test('negative velocity at bottom boundary clamps to first', () {
        const config = SnapConfig(angles: [0, 15, 30, 45]);
        expect(config.flingTarget(1, -100), 0);
      });

      test('empty angles returns currentTilt', () {
        const config = SnapConfig(angles: []);
        expect(config.flingTarget(10, 100), 10);
      });

      test('single angle returns that angle', () {
        const config = SnapConfig(angles: [15]);
        expect(config.flingTarget(10, 100), 15);
        expect(config.flingTarget(20, -100), 15);
      });

      test('zero velocity picks next higher (treated as positive)', () {
        const config = SnapConfig(angles: [0, 15, 30]);
        expect(config.flingTarget(10, 0), 15);
      });

      test('skips angles within 0.5 of currentTilt', () {
        const config = SnapConfig(angles: [0, 15, 30]);
        // 15.3 is within 0.5 of 15, so positive fling should go to 30.
        expect(config.flingTarget(15.3, 100), 30);
        // 14.7 is within 0.5 of 15, so negative fling should go to 0.
        expect(config.flingTarget(14.7, -100), 0);
      });
    });

    group('equality', () {
      test('equal configs', () {
        const a = SnapConfig(angles: [0, 15, 30], threshold: 3);
        const b = SnapConfig(angles: [0, 15, 30], threshold: 3);
        expect(a, equals(b));
        expect(a.hashCode, b.hashCode);
      });

      test('different angles not equal', () {
        const a = SnapConfig(angles: [0, 15, 30]);
        const b = SnapConfig(angles: [0, 15, 45]);
        expect(a, isNot(equals(b)));
      });

      test('different threshold not equal', () {
        const a = SnapConfig(angles: [0, 15], threshold: 3);
        const b = SnapConfig(angles: [0, 15], threshold: 5);
        expect(a, isNot(equals(b)));
      });

      test('different hapticOnSnap not equal', () {
        const a = SnapConfig(angles: [0], hapticOnSnap: true);
        const b = SnapConfig(angles: [0], hapticOnSnap: false);
        expect(a, isNot(equals(b)));
      });
    });
  });
}
