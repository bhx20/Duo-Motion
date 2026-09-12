import 'dart:math' as math;

import 'package:duo_motion/src/core/optics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Optics', () {
    group('gap', () {
      test('is zero at zero tilt', () {
        expect(Optics.gap(100, 0), closeTo(0, 1e-9));
      });

      test('equals d at 90-degree tilt', () {
        expect(Optics.gap(100, math.pi / 2), closeTo(100, 1e-9));
      });

      test('is proportional to distance from hinge', () {
        const tilt = 0.3;
        final gap1 = Optics.gap(10, tilt);
        final gap2 = Optics.gap(20, tilt);
        expect(gap2, closeTo(2 * gap1, 1e-9));
      });

      test('increases with tilt angle', () {
        final gapSmall = Optics.gap(50, 0.1);
        final gapLarge = Optics.gap(50, 0.5);
        expect(gapLarge, greaterThan(gapSmall));
      });
    });

    group('glassDisplacement', () {
      test('is zero at zero tilt', () {
        expect(Optics.glassDisplacement(100, 0), closeTo(0, 1e-9));
      });

      test('is d at 90-degree tilt', () {
        // 1 - cos(pi/2) = 1 - 0 = 1, so displacement = d.
        expect(Optics.glassDisplacement(100, math.pi / 2), closeTo(100, 1e-9));
      });

      test('formula d*(1 - cos(tilt))', () {
        const d = 50.0;
        const tilt = 0.4;
        expect(
          Optics.glassDisplacement(d, tilt),
          closeTo(d * (1 - math.cos(tilt)), 1e-9),
        );
      });
    });

    group('blurRadius', () {
      test('equals baseBlurPx when gap is zero', () {
        expect(Optics.blurRadius(0, 0.12, 2.0), closeTo(2.0, 1e-9));
      });

      test('increases linearly with gap', () {
        final r1 = Optics.blurRadius(10, 0.12, 0);
        final r2 = Optics.blurRadius(20, 0.12, 0);
        expect(r2, closeTo(2 * r1, 1e-9));
      });

      test('combines spread and base', () {
        expect(
          Optics.blurRadius(10, 0.5, 3),
          closeTo(0.5 * 10 + 3, 1e-9),
        );
      });
    });

    group('attenuation', () {
      test('zero darkening returns 1.0', () {
        expect(Optics.attenuation(100, 0), closeTo(1.0, 1e-9));
      });

      test('large darkening clamps to zero', () {
        // 1.0 - 10 * 100 = -999. Clamped to 0.
        expect(Optics.attenuation(100, 10), closeTo(0, 1e-9));
      });

      test('partial attenuation', () {
        // 1 - 0.01 * 50 = 0.5
        expect(Optics.attenuation(50, 0.01), closeTo(0.5, 1e-9));
      });

      test('zero radius returns 1.0', () {
        expect(Optics.attenuation(0, 0.5), closeTo(1.0, 1e-9));
      });
    });

    group('rayHit', () {
      test('normal case returns correct coordinates', () {
        final result = Optics.rayHit(
          glassX: 10,
          glassY: 20,
          gap: 50,
          eyeX: 0,
          eyeY: 0,
          eyeDistance: 200,
        );
        expect(result, isNotNull);
        // t = eyeDistance / (eyeDistance - gap) = 200 / 150 = 4/3
        // x = 0 + (10 - 0) * 4/3 = 40/3
        // y = 0 + (20 - 0) * 4/3 = 80/3
        expect(result!.x, closeTo(40 / 3, 1e-9));
        expect(result.y, closeTo(80 / 3, 1e-9));
      });

      test('zero gap means glass on content, so t=1', () {
        final result = Optics.rayHit(
          glassX: 5,
          glassY: 10,
          gap: 0,
          eyeX: 0,
          eyeY: 0,
          eyeDistance: 200,
        );
        expect(result, isNotNull);
        // t = 200/200 = 1, so hit = glassPos.
        expect(result!.x, closeTo(5, 1e-9));
        expect(result.y, closeTo(10, 1e-9));
      });

      test('depth <= 0 returns null (gap at eye distance)', () {
        final result = Optics.rayHit(
          glassX: 5,
          glassY: 10,
          gap: 200,
          eyeX: 0,
          eyeY: 0,
          eyeDistance: 200,
        );
        expect(result, isNull);
      });

      test('depth just below threshold returns null', () {
        // eyeDistance - gap = 200 - 199.5 = 0.5, which is <= 1e-3? No, 0.5>1e-3.
        // eyeDistance - gap must be <= 1e-3 for null.
        final result = Optics.rayHit(
          glassX: 5,
          glassY: 10,
          gap: 199.9995,
          eyeX: 0,
          eyeY: 0,
          eyeDistance: 200,
        );
        // depth = 200 - 199.9995 = 0.0005, which is <= 1e-3 => null.
        expect(result, isNull);
      });

      test('gap beyond eye returns null', () {
        final result = Optics.rayHit(
          glassX: 5,
          glassY: 10,
          gap: 300,
          eyeX: 0,
          eyeY: 0,
          eyeDistance: 200,
        );
        expect(result, isNull);
      });

      test('with offset eye position', () {
        final result = Optics.rayHit(
          glassX: 10,
          glassY: 10,
          gap: 0,
          eyeX: 5,
          eyeY: 5,
          eyeDistance: 100,
        );
        expect(result, isNotNull);
        // t = 100/100 = 1, x = 5 + (10-5)*1 = 10, y = 5 + (10-5)*1 = 10
        expect(result!.x, closeTo(10, 1e-9));
        expect(result.y, closeTo(10, 1e-9));
      });
    });
  });
}
