import 'package:duo_motion/src/core/fold_effects.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FoldEffects', () {
    group('default zeroes', () {
      test('all intensities default to zero', () {
        const e = FoldEffects();
        expect(e.causticIntensity, 0.0);
        expect(e.chromaticAberration, 0.0);
        expect(e.shadowIntensity, 0.0);
        expect(e.lightAngle, 0.0);
      });

      test('shadowSoftness defaults to 0.5', () {
        const e = FoldEffects();
        expect(e.shadowSoftness, 0.5);
      });
    });

    group('copyWith', () {
      test('replaces specified fields', () {
        const e = FoldEffects(causticIntensity: 0.3, shadowIntensity: 0.5);
        final e2 = e.copyWith(causticIntensity: 0.8);
        expect(e2.causticIntensity, 0.8);
        expect(e2.shadowIntensity, 0.5);
      });

      test('returns equal value when no arguments given', () {
        const e = FoldEffects(chromaticAberration: 1.5);
        final e2 = e.copyWith();
        expect(e2, equals(e));
      });

      test('all fields can be replaced', () {
        const e = FoldEffects();
        final e2 = e.copyWith(
          causticIntensity: 0.1,
          chromaticAberration: 2.0,
          shadowIntensity: 0.4,
          shadowSoftness: 0.8,
          lightAngle: 1.57,
        );
        expect(e2.causticIntensity, 0.1);
        expect(e2.chromaticAberration, 2.0);
        expect(e2.shadowIntensity, 0.4);
        expect(e2.shadowSoftness, 0.8);
        expect(e2.lightAngle, 1.57);
      });
    });

    group('value equality', () {
      test('equal effects', () {
        const a = FoldEffects(causticIntensity: 0.5, shadowSoftness: 0.3);
        const b = FoldEffects(causticIntensity: 0.5, shadowSoftness: 0.3);
        expect(a, equals(b));
        expect(a.hashCode, b.hashCode);
      });

      test('different effects not equal', () {
        const a = FoldEffects(causticIntensity: 0.5);
        const b = FoldEffects(causticIntensity: 0.6);
        expect(a, isNot(equals(b)));
      });

      test('all fields participate in equality', () {
        const base = FoldEffects(
          causticIntensity: 0.1,
          chromaticAberration: 0.2,
          shadowIntensity: 0.3,
          shadowSoftness: 0.4,
          lightAngle: 0.5,
        );
        // Changing each field should break equality.
        expect(base, isNot(equals(base.copyWith(causticIntensity: 0.9))));
        expect(base, isNot(equals(base.copyWith(chromaticAberration: 0.9))));
        expect(base, isNot(equals(base.copyWith(shadowIntensity: 0.9))));
        expect(base, isNot(equals(base.copyWith(shadowSoftness: 0.9))));
        expect(base, isNot(equals(base.copyWith(lightAngle: 0.9))));
      });
    });

    group('toString', () {
      test('includes all field names', () {
        const e = FoldEffects(
          causticIntensity: 0.3,
          chromaticAberration: 1.0,
          shadowIntensity: 0.5,
          shadowSoftness: 0.2,
          lightAngle: 1.57,
        );
        final s = e.toString();
        expect(s, contains('FoldEffects'));
        expect(s, contains('caustic'));
        expect(s, contains('0.3'));
        expect(s, contains('chromatic'));
        expect(s, contains('1.0'));
        expect(s, contains('shadow'));
        expect(s, contains('0.5'));
        expect(s, contains('softness'));
        expect(s, contains('0.2'));
        expect(s, contains('lightAngle'));
        expect(s, contains('1.57'));
      });
    });
  });
}
