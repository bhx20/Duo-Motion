import 'dart:math' as math;

import 'package:duo_motion/src/core/fold_constraints.dart';
import 'package:duo_motion/src/core/fold_hinge.dart';
import 'package:duo_motion/src/core/fold_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FreeFoldConstraints', () {
    test('passes through tilt within max', () {
      const c = FreeFoldConstraints();
      const raw = FoldState(tiltDegrees: 20, liftDirX: -1, liftDirY: 0);
      final result = c.resolve(raw);
      expect(result.tiltDegrees, closeTo(20, 1e-9));
      expect(result.liftDirX, raw.liftDirX);
      expect(result.liftDirY, raw.liftDirY);
    });

    test('clamps tilt above maxTiltDegrees', () {
      const c = FreeFoldConstraints(maxTiltDegrees: 30);
      const raw = FoldState(tiltDegrees: 50, liftDirX: -1, liftDirY: 0);
      final result = c.resolve(raw);
      expect(result.tiltDegrees, closeTo(30, 1e-9));
    });

    test('clamps negative tilt to zero', () {
      const c = FreeFoldConstraints();
      const raw = FoldState(tiltDegrees: -5, liftDirX: -1, liftDirY: 0);
      final result = c.resolve(raw);
      expect(result.tiltDegrees, closeTo(0, 1e-9));
    });

    test('equality', () {
      const a = FreeFoldConstraints(maxTiltDegrees: 45);
      const b = FreeFoldConstraints(maxTiltDegrees: 45);
      const c = FreeFoldConstraints(maxTiltDegrees: 30);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('hashCode', () {
      const a = FreeFoldConstraints(maxTiltDegrees: 45);
      const b = FreeFoldConstraints(maxTiltDegrees: 45);
      expect(a.hashCode, b.hashCode);
    });

    test('resting pose yields finite direction', () {
      const c = FreeFoldConstraints();
      final result = c.resolve(FoldState.zero);
      expect(result.liftDirX.isFinite, isTrue);
      expect(result.liftDirY.isFinite, isTrue);
    });
  });

  group('HorizontalFoldConstraints', () {
    test('diagonal projects to horizontal component only', () {
      const c = HorizontalFoldConstraints();
      // Direction at 45 degrees: (cos45, sin45) = (0.707, 0.707).
      // The horizontal hinges are left (liftDir 1,0) and right (liftDir -1,0).
      // cos45 from raw direction toward right hinge direction.
      final sqrt2inv = 1.0 / math.sqrt(2);
      final raw = FoldState(
        tiltDegrees: 20,
        liftDirX: sqrt2inv,
        liftDirY: sqrt2inv,
      );
      final result = c.resolve(raw);
      // Best hinge is left (liftDir 1,0) because dot product with (0.707,0.707)
      // and (1,0) = 0.707 > dot with (-1,0) = -0.707.
      // Projected component = 20 * 0.707 ~ 14.14.
      expect(result.tiltDegrees, closeTo(20 * sqrt2inv, 1e-6));
      // Direction snapped to the left hinge's lift direction.
      expect(result.liftDirX, closeTo(1.0, 1e-9));
      expect(result.liftDirY, closeTo(0.0, 1e-9));
    });

    test('purely vertical input yields flat', () {
      const c = HorizontalFoldConstraints();
      // Direction (0,1) is pure vertical; dot with both horizontal hinges = 0.
      const raw = FoldState(tiltDegrees: 20, liftDirX: 0, liftDirY: 1);
      final result = c.resolve(raw);
      expect(result.tiltDegrees, closeTo(0, 1e-9));
    });

    test('equality', () {
      const a = HorizontalFoldConstraints(maxTiltDegrees: 45);
      const b = HorizontalFoldConstraints(maxTiltDegrees: 45);
      expect(a, equals(b));
    });

    test('hashCode', () {
      const a = HorizontalFoldConstraints(maxTiltDegrees: 45);
      const b = HorizontalFoldConstraints(maxTiltDegrees: 45);
      expect(a.hashCode, b.hashCode);
    });

    test('resting pose yields finite direction', () {
      const c = HorizontalFoldConstraints();
      final result = c.resolve(FoldState.zero);
      expect(result.liftDirX.isFinite, isTrue);
      expect(result.liftDirY.isFinite, isTrue);
    });
  });

  group('VerticalFoldConstraints', () {
    test('projects to vertical component', () {
      const c = VerticalFoldConstraints();
      // Pure vertical direction (0, -1) aligns with bottom hinge (liftDir 0,-1).
      const raw = FoldState(tiltDegrees: 15, liftDirX: 0, liftDirY: -1);
      final result = c.resolve(raw);
      expect(result.tiltDegrees, closeTo(15, 1e-9));
      expect(result.liftDirX, closeTo(0.0, 1e-9));
      expect(result.liftDirY, closeTo(-1.0, 1e-9));
    });

    test('purely horizontal input yields flat', () {
      const c = VerticalFoldConstraints();
      const raw = FoldState(tiltDegrees: 20, liftDirX: 1, liftDirY: 0);
      final result = c.resolve(raw);
      expect(result.tiltDegrees, closeTo(0, 1e-9));
    });

    test('equality', () {
      const a = VerticalFoldConstraints(maxTiltDegrees: 45);
      const b = VerticalFoldConstraints(maxTiltDegrees: 45);
      const c = VerticalFoldConstraints(maxTiltDegrees: 30);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('hashCode', () {
      const a = VerticalFoldConstraints();
      const b = VerticalFoldConstraints();
      expect(a.hashCode, b.hashCode);
    });

    test('resting pose yields finite direction', () {
      const c = VerticalFoldConstraints();
      final result = c.resolve(FoldState.zero);
      expect(result.liftDirX.isFinite, isTrue);
      expect(result.liftDirY.isFinite, isTrue);
    });
  });

  group('SingleHingeFoldConstraints', () {
    test('responds to allowed hinge', () {
      const c = SingleHingeFoldConstraints(FoldHinge.left);
      // Left hinge lift direction is (1, 0).
      const raw = FoldState(tiltDegrees: 25, liftDirX: 1, liftDirY: 0);
      final result = c.resolve(raw);
      expect(result.tiltDegrees, closeTo(25, 1e-9));
      expect(result.liftDirX, closeTo(1.0, 1e-9));
      expect(result.liftDirY, closeTo(0.0, 1e-9));
    });

    test('returns flat for opposite hinge direction', () {
      const c = SingleHingeFoldConstraints(FoldHinge.left);
      // Opposite of left lift (1,0) is right lift (-1,0). The dot product
      // is negative so it should read as flat.
      const raw = FoldState(tiltDegrees: 25, liftDirX: -1, liftDirY: 0);
      final result = c.resolve(raw);
      expect(result.tiltDegrees, closeTo(0, 1e-9));
    });

    test('returns flat for perpendicular direction', () {
      const c = SingleHingeFoldConstraints(FoldHinge.left);
      // Perpendicular: (0,1) dot (1,0) = 0, which is <= 0.
      const raw = FoldState(tiltDegrees: 25, liftDirX: 0, liftDirY: 1);
      final result = c.resolve(raw);
      expect(result.tiltDegrees, closeTo(0, 1e-9));
    });

    test('equality and hashCode', () {
      const a = SingleHingeFoldConstraints(FoldHinge.top);
      const b = SingleHingeFoldConstraints(FoldHinge.top);
      const c = SingleHingeFoldConstraints(FoldHinge.bottom);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
    });

    test('resting pose yields finite direction', () {
      const c = SingleHingeFoldConstraints(FoldHinge.right);
      final result = c.resolve(FoldState.zero);
      expect(result.liftDirX.isFinite, isTrue);
      expect(result.liftDirY.isFinite, isTrue);
    });
  });

  group('CustomFoldConstraints', () {
    test('empty set produces flat', () {
      final c = CustomFoldConstraints(<FoldHinge>{});
      const raw = FoldState(tiltDegrees: 20, liftDirX: 1, liftDirY: 0);
      final result = c.resolve(raw);
      expect(result.tiltDegrees, closeTo(0, 1e-9));
    });

    test('all hinges behaves like free', () {
      final c = CustomFoldConstraints(FoldHinge.values.toSet());
      const raw = FoldState(tiltDegrees: 20, liftDirX: 1, liftDirY: 0);
      final result = c.resolve(raw);
      // With direction (1,0), the best-matching hinge is left (liftDir 1,0),
      // dot product 1.0. Component = 20 * 1.0 = 20.
      expect(result.tiltDegrees, closeTo(20, 1e-9));
    });

    test('subset of hinges limits directions', () {
      final c = CustomFoldConstraints({FoldHinge.top, FoldHinge.bottom});
      const raw = FoldState(tiltDegrees: 10, liftDirX: 1, liftDirY: 0);
      final result = c.resolve(raw);
      // (1,0) dot (0,1)=0 and (1,0) dot (0,-1)=0, both <=0 => flat.
      expect(result.tiltDegrees, closeTo(0, 1e-9));
    });

    test('equality checks hinge sets', () {
      final a = CustomFoldConstraints({FoldHinge.left, FoldHinge.right});
      final b = CustomFoldConstraints({FoldHinge.right, FoldHinge.left});
      final c = CustomFoldConstraints({FoldHinge.left});
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
    });

    test('allowedHinges getter returns correct set', () {
      final c = CustomFoldConstraints({FoldHinge.top});
      expect(c.allowedHinges, contains(FoldHinge.top));
      expect(c.allowedHinges.length, 1);
    });

    test('resting pose yields finite direction', () {
      final c = CustomFoldConstraints({FoldHinge.left});
      final result = c.resolve(FoldState.zero);
      expect(result.liftDirX.isFinite, isTrue);
      expect(result.liftDirY.isFinite, isTrue);
    });
  });
}
