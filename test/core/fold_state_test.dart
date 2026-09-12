import 'package:duo_motion/src/core/fold_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FoldState', () {
    group('zero constant', () {
      test('has zero tilt', () {
        expect(FoldState.zero.tiltDegrees, 0.0);
      });

      test('has direction pointing left (-1, 0)', () {
        expect(FoldState.zero.liftDirX, -1.0);
        expect(FoldState.zero.liftDirY, 0.0);
      });

      test('is at rest', () {
        expect(FoldState.zero.isAtRest, isTrue);
      });
    });

    group('isAtRest', () {
      test('returns true when tilt is exactly zero', () {
        expect(FoldState.zero.isAtRest, isTrue);
      });

      test('returns true when tilt is below restEpsilon', () {
        final state = FoldState(
          tiltDegrees: FoldState.restEpsilon / 2,
          liftDirX: -1,
          liftDirY: 0,
        );
        expect(state.isAtRest, isTrue);
      });

      test('returns false when tilt is above restEpsilon', () {
        final state = FoldState(
          tiltDegrees: FoldState.restEpsilon + 0.01,
          liftDirX: -1,
          liftDirY: 0,
        );
        expect(state.isAtRest, isFalse);
      });

      test('returns false for large tilt', () {
        const state = FoldState(tiltDegrees: 30, liftDirX: 1, liftDirY: 0);
        expect(state.isAtRest, isFalse);
      });
    });

    group('withTilt', () {
      test('returns new state with updated tilt', () {
        const state = FoldState(tiltDegrees: 10, liftDirX: 0.5, liftDirY: 0.5);
        final updated = state.withTilt(25);
        expect(updated.tiltDegrees, 25);
        expect(updated.liftDirX, 0.5);
        expect(updated.liftDirY, 0.5);
      });

      test('preserves direction', () {
        const state = FoldState(tiltDegrees: 10, liftDirX: -1, liftDirY: 0);
        final updated = state.withTilt(0);
        expect(updated.liftDirX, state.liftDirX);
        expect(updated.liftDirY, state.liftDirY);
      });
    });

    group('withDirection', () {
      test('returns new state with updated direction', () {
        const state = FoldState(tiltDegrees: 20, liftDirX: 1, liftDirY: 0);
        final updated = state.withDirection(0, 1);
        expect(updated.tiltDegrees, 20);
        expect(updated.liftDirX, 0);
        expect(updated.liftDirY, 1);
      });

      test('preserves tilt', () {
        const state = FoldState(tiltDegrees: 15, liftDirX: 1, liftDirY: 0);
        final updated = state.withDirection(-1, 0);
        expect(updated.tiltDegrees, state.tiltDegrees);
      });
    });

    group('liftDirection', () {
      test('returns Offset from components', () {
        const state = FoldState(tiltDegrees: 10, liftDirX: 0.6, liftDirY: 0.8);
        final dir = state.liftDirection;
        expect(dir.dx, 0.6);
        expect(dir.dy, 0.8);
      });
    });

    group('lerp', () {
      test('at t=0 returns a', () {
        const a = FoldState(tiltDegrees: 10, liftDirX: 1, liftDirY: 0);
        const b = FoldState(tiltDegrees: 30, liftDirX: 0, liftDirY: 1);
        final result = FoldState.lerp(a, b, 0);
        expect(result.tiltDegrees, closeTo(10, 1e-9));
        expect(result.liftDirX, closeTo(1, 1e-9));
        expect(result.liftDirY, closeTo(0, 1e-9));
      });

      test('at t=1 returns b', () {
        const a = FoldState(tiltDegrees: 10, liftDirX: 1, liftDirY: 0);
        const b = FoldState(tiltDegrees: 30, liftDirX: 0, liftDirY: 1);
        final result = FoldState.lerp(a, b, 1);
        expect(result.tiltDegrees, closeTo(30, 1e-9));
        expect(result.liftDirX, closeTo(0, 1e-9));
        expect(result.liftDirY, closeTo(1, 1e-9));
      });

      test('at t=0.5 interpolates tilt linearly', () {
        const a = FoldState(tiltDegrees: 10, liftDirX: 1, liftDirY: 0);
        const b = FoldState(tiltDegrees: 30, liftDirX: 1, liftDirY: 0);
        final result = FoldState.lerp(a, b, 0.5);
        expect(result.tiltDegrees, closeTo(20, 1e-9));
      });

      test('normalises direction after interpolation', () {
        const a = FoldState(tiltDegrees: 0, liftDirX: 1, liftDirY: 0);
        const b = FoldState(tiltDegrees: 0, liftDirX: 0, liftDirY: 1);
        final result = FoldState.lerp(a, b, 0.5);
        // Midpoint of (1,0) and (0,1) normalised should have length 1.
        final len = result.liftDirX * result.liftDirX +
            result.liftDirY * result.liftDirY;
        expect(len, closeTo(1.0, 1e-9));
      });

      test('degenerate zero-length direction falls back to zero default', () {
        // Opposite directions that cancel out.
        const a = FoldState(tiltDegrees: 5, liftDirX: 1, liftDirY: 0);
        const b = FoldState(tiltDegrees: 5, liftDirX: -1, liftDirY: 0);
        final result = FoldState.lerp(a, b, 0.5);
        // When the interpolated direction is zero-length, fallback is used.
        expect(result.liftDirX, FoldState.zero.liftDirX);
        expect(result.liftDirY, FoldState.zero.liftDirY);
      });
    });

    group('value equality', () {
      test('identical fields are equal', () {
        const a = FoldState(tiltDegrees: 15, liftDirX: -1, liftDirY: 0);
        const b = FoldState(tiltDegrees: 15, liftDirX: -1, liftDirY: 0);
        expect(a, equals(b));
      });

      test('different tilt not equal', () {
        const a = FoldState(tiltDegrees: 15, liftDirX: -1, liftDirY: 0);
        const b = FoldState(tiltDegrees: 16, liftDirX: -1, liftDirY: 0);
        expect(a, isNot(equals(b)));
      });

      test('different direction not equal', () {
        const a = FoldState(tiltDegrees: 15, liftDirX: 1, liftDirY: 0);
        const b = FoldState(tiltDegrees: 15, liftDirX: 0, liftDirY: 1);
        expect(a, isNot(equals(b)));
      });
    });

    group('hashCode', () {
      test('equal objects have equal hashCodes', () {
        const a = FoldState(tiltDegrees: 15, liftDirX: -1, liftDirY: 0);
        const b = FoldState(tiltDegrees: 15, liftDirX: -1, liftDirY: 0);
        expect(a.hashCode, b.hashCode);
      });
    });

    group('toString', () {
      test('includes tilt and direction', () {
        const state = FoldState(tiltDegrees: 12.5, liftDirX: -1, liftDirY: 0);
        final str = state.toString();
        expect(str, contains('12.50'));
        expect(str, contains('FoldState'));
        expect(str, contains('-1.00'));
        expect(str, contains('0.00'));
      });
    });
  });
}
