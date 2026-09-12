import 'dart:ui' as ui;

import 'package:duo_motion/src/core/fold_parameters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FoldParameters', () {
    group('resolvePixelsPerMillimeter', () {
      test('explicit value takes priority', () {
        const p = FoldParameters(pixelsPerMillimeter: 10);
        expect(p.resolvePixelsPerMillimeter(8), 10);
      });

      test('display value used when explicit is zero', () {
        const p = FoldParameters(pixelsPerMillimeter: 0);
        expect(p.resolvePixelsPerMillimeter(8), 8);
      });

      test('fallback used when both explicit and display are absent', () {
        const p = FoldParameters(pixelsPerMillimeter: 0);
        expect(
          p.resolvePixelsPerMillimeter(null),
          FoldParameters.fallbackPixelsPerMillimeter,
        );
      });

      test('fallback used when display is not finite', () {
        const p = FoldParameters(pixelsPerMillimeter: 0);
        expect(
          p.resolvePixelsPerMillimeter(double.infinity),
          FoldParameters.fallbackPixelsPerMillimeter,
        );
        expect(
          p.resolvePixelsPerMillimeter(double.nan),
          FoldParameters.fallbackPixelsPerMillimeter,
        );
      });

      test('fallback used when display is zero or negative', () {
        const p = FoldParameters(pixelsPerMillimeter: 0);
        expect(
          p.resolvePixelsPerMillimeter(0),
          FoldParameters.fallbackPixelsPerMillimeter,
        );
        expect(
          p.resolvePixelsPerMillimeter(-3),
          FoldParameters.fallbackPixelsPerMillimeter,
        );
      });
    });

    group('packUniforms', () {
      test('returns exactly 14 floats', () {
        const p = FoldParameters();
        final uniforms = p.packUniforms(
          tiltDegrees: 10,
          liftDirX: -1,
          liftDirY: 0,
          pixelsPerMillimeter: 6,
        );
        expect(uniforms.length, 14);
      });

      test('uniforms are in correct order', () {
        const p = FoldParameters(
          eyeDistanceMillimeters: 450,
          blurSpread: 0.12,
          darkening: 0.0084,
          surroundColor: ui.Color(0xFFFF0000), // red
          hazeColor: ui.Color(0xFF00FF00), // green
          baseBlurMillimeters: 0.10,
          stretchEdges: true,
        );
        final uniforms = p.packUniforms(
          tiltDegrees: 10,
          liftDirX: -1,
          liftDirY: 0,
          pixelsPerMillimeter: 6,
        );
        // [0] = shaped tilt
        expect(uniforms[0], closeTo(10.0, 1e-9)); // tiltResponse=1 => linear
        // [1] = liftDirX
        expect(uniforms[1], closeTo(-1.0, 1e-9));
        // [2] = liftDirY
        expect(uniforms[2], closeTo(0.0, 1e-9));
        // [3] = eyeDistance * density = 450 * 6 = 2700
        expect(uniforms[3], closeTo(2700.0, 1e-6));
        // [4] = blurSpread
        expect(uniforms[4], closeTo(0.12, 1e-9));
        // [5] = darkening * reference / density = 0.0084 * 6 / 6 = 0.0084
        expect(uniforms[5], closeTo(0.0084, 1e-9));
        // [6,7,8] = surround R,G,B (red = 1,0,0 in linear)
        expect(uniforms[6], closeTo(1.0, 1e-2)); // red channel
        expect(uniforms[7], closeTo(0.0, 1e-2)); // green channel
        expect(uniforms[8], closeTo(0.0, 1e-2)); // blue channel
        // [9,10,11] = haze R,G,B (green = 0,1,0 in linear)
        expect(uniforms[9], closeTo(0.0, 1e-2));
        expect(uniforms[10], closeTo(1.0, 1e-2));
        expect(uniforms[11], closeTo(0.0, 1e-2));
        // [12] = baseBlurMm * density = 0.10 * 6 = 0.6
        expect(uniforms[12], closeTo(0.6, 1e-9));
        // [13] = stretchEdges flag
        expect(uniforms[13], closeTo(1.0, 1e-9));
      });

      test('tiltResponse shaping applies power curve', () {
        const p = FoldParameters(tiltResponse: 2);
        final uniforms = p.packUniforms(
          tiltDegrees: 45, // full max
          liftDirX: 1,
          liftDirY: 0,
          pixelsPerMillimeter: 6,
        );
        // At max tilt (45), fraction = 45/45 = 1, pow(1,2) * 45 = 45.
        expect(uniforms[0], closeTo(45.0, 1e-9));

        final uniformsHalf = p.packUniforms(
          tiltDegrees: 22.5, // half max
          liftDirX: 1,
          liftDirY: 0,
          pixelsPerMillimeter: 6,
        );
        // fraction = 22.5/45 = 0.5, pow(0.5, 2) * 45 = 0.25 * 45 = 11.25
        expect(uniformsHalf[0], closeTo(11.25, 1e-9));
      });

      test('density normalisation scales darkening', () {
        const p = FoldParameters(darkening: 0.01);
        final u1 = p.packUniforms(
          tiltDegrees: 10,
          liftDirX: 1,
          liftDirY: 0,
          pixelsPerMillimeter: 3,
        );
        // darkening * reference / density = 0.01 * 6 / 3 = 0.02
        expect(u1[5], closeTo(0.02, 1e-9));

        final u2 = p.packUniforms(
          tiltDegrees: 10,
          liftDirX: 1,
          liftDirY: 0,
          pixelsPerMillimeter: 12,
        );
        // 0.01 * 6 / 12 = 0.005
        expect(u2[5], closeTo(0.005, 1e-9));
      });

      test('surround and haze alpha is ignored (only RGB packed)', () {
        const p = FoldParameters(
          surroundColor: ui.Color(0x80FF0000), // half-transparent red
          hazeColor: ui.Color(0x4000FF00), // quarter-transparent green
        );
        final uniforms = p.packUniforms(
          tiltDegrees: 5,
          liftDirX: 1,
          liftDirY: 0,
          pixelsPerMillimeter: 6,
        );
        // Only 3 components for surround, 3 for haze, no alpha slot.
        // Indices 6-8 are surround RGB, 9-11 are haze RGB.
        // There are exactly 14 uniforms; no extra alpha floats.
        expect(uniforms.length, 14);
      });

      test('stretchEdges false produces zero', () {
        const p = FoldParameters(stretchEdges: false);
        final uniforms = p.packUniforms(
          tiltDegrees: 10,
          liftDirX: 1,
          liftDirY: 0,
          pixelsPerMillimeter: 6,
        );
        expect(uniforms[13], closeTo(0.0, 1e-9));
      });

      test('negative tilt becomes positive magnitude', () {
        const p = FoldParameters();
        final uniforms = p.packUniforms(
          tiltDegrees: -20,
          liftDirX: 1,
          liftDirY: 0,
          pixelsPerMillimeter: 6,
        );
        // _shape takes abs(-20) = 20. With tiltResponse=1, shaped = 20.
        expect(uniforms[0], closeTo(20.0, 1e-9));
      });
    });

    group('copyWith', () {
      test('replaces specified fields', () {
        const p = FoldParameters(eyeDistanceMillimeters: 400, blurSpread: 0.2);
        final p2 = p.copyWith(blurSpread: 0.5);
        expect(p2.blurSpread, 0.5);
        expect(p2.eyeDistanceMillimeters, 400);
      });

      test('returns identical value when no arguments given', () {
        const p = FoldParameters();
        final p2 = p.copyWith();
        expect(p2, equals(p));
      });

      test('all fields can be replaced', () {
        const p = FoldParameters();
        final p2 = p.copyWith(
          eyeDistanceMillimeters: 500,
          pixelsPerMillimeter: 10,
          blurSpread: 0.3,
          darkening: 0.01,
          surroundColor: const ui.Color(0xFF112233),
          hazeColor: const ui.Color(0xFF445566),
          baseBlurMillimeters: 0.2,
          stretchEdges: false,
          tiltResponse: 2.5,
        );
        expect(p2.eyeDistanceMillimeters, 500);
        expect(p2.pixelsPerMillimeter, 10);
        expect(p2.blurSpread, 0.3);
        expect(p2.darkening, 0.01);
        expect(p2.surroundColor, const ui.Color(0xFF112233));
        expect(p2.hazeColor, const ui.Color(0xFF445566));
        expect(p2.baseBlurMillimeters, 0.2);
        expect(p2.stretchEdges, isFalse);
        expect(p2.tiltResponse, 2.5);
      });
    });

    group('value equality', () {
      test('equal parameters', () {
        const a = FoldParameters(blurSpread: 0.15, darkening: 0.01);
        const b = FoldParameters(blurSpread: 0.15, darkening: 0.01);
        expect(a, equals(b));
        expect(a.hashCode, b.hashCode);
      });

      test('different parameters not equal', () {
        const a = FoldParameters(blurSpread: 0.15);
        const b = FoldParameters(blurSpread: 0.20);
        expect(a, isNot(equals(b)));
      });

      test('tiltResponse affects equality', () {
        const a = FoldParameters(tiltResponse: 1);
        const b = FoldParameters(tiltResponse: 2);
        expect(a, isNot(equals(b)));
      });
    });

    group('toString (Bug 5 regression)', () {
      test('includes tiltResponse', () {
        const p = FoldParameters(tiltResponse: 2.5);
        final s = p.toString();
        expect(s, contains('tiltResponse'));
        expect(s, contains('2.5'));
      });

      test('includes all key fields', () {
        const p = FoldParameters();
        final s = p.toString();
        expect(s, contains('FoldParameters'));
        expect(s, contains('eye'));
        expect(s, contains('pxPerMm'));
        expect(s, contains('blur'));
        expect(s, contains('darken'));
        expect(s, contains('stretchEdges'));
        expect(s, contains('tiltResponse'));
      });
    });
  });
}
