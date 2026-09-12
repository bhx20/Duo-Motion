import 'dart:ui' as ui;

import 'package:duo_motion/src/core/fold_effects.dart';
import 'package:duo_motion/src/core/fold_mode.dart';
import 'package:duo_motion/src/core/fold_parameters.dart';
import 'package:duo_motion/src/core/fold_state.dart';
import 'package:duo_motion/src/shader/adaptive_quality.dart';
import 'package:duo_motion/src/shader/shader_manager.dart';
import 'package:duo_motion/src/shader/uniform_packer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UniformPacker', () {
    const state = FoldState(
      tiltDegrees: 20.0,
      liftDirX: -1.0,
      liftDirY: 0.0,
    );

    const params = FoldParameters(
      eyeDistanceMillimeters: 450,
      blurSpread: 0.12,
      darkening: 0.015,
      surroundColor: ui.Color(0xFF112233),
      hazeColor: ui.Color(0xFF445566),
    );

    const effects = FoldEffects(
      causticIntensity: 0.3,
      shadowIntensity: 0.5,
      shadowSoftness: 0.6,
    );

    test('packSingleHinge produces exactly 17 uniforms matching declaration', () {
      final uniforms = UniformPacker.packSingleHinge(
        state: state,
        params: params,
        effects: effects,
        pixelsPerMillimeter: 6.0,
      );

      expect(uniforms.length, 17);
      expect(uniforms[0], 20.0); // shaped tilt
      expect(uniforms[1], -1.0); // liftDirX
      expect(uniforms[2], 0.0);  // liftDirY
      expect(uniforms[14], 0.3); // caustic
      expect(uniforms[15], 0.5); // shadow
      expect(uniforms[16], 0.6); // softness
    });

    test('packBookFold produces exactly 18 uniforms with hinge position at index 14', () {
      final uniforms = UniformPacker.packBookFold(
        state: state,
        params: params,
        effects: effects,
        hingePosition: 0.45,
        pixelsPerMillimeter: 6.0,
      );

      expect(uniforms.length, 18);
      expect(uniforms[14], 0.45); // hingePosition
      expect(uniforms[15], 0.3);  // caustic
      expect(uniforms[16], 0.5);  // shadow
      expect(uniforms[17], 0.6);  // softness
    });

    test('packAccordion produces exactly 18 uniforms with clamped foldCount at index 14', () {
      final uniforms = UniformPacker.packAccordion(
        state: state,
        params: params,
        effects: effects,
        foldCount: 4,
        pixelsPerMillimeter: 6.0,
      );

      expect(uniforms.length, 18);
      expect(uniforms[14], 4.0);  // foldCount
      expect(uniforms[15], 0.3);  // caustic
      expect(uniforms[16], 0.5);  // shadow
      expect(uniforms[17], 0.6);  // softness
    });

    test('pack dispatch method routes correctly based on FoldMode type', () {
      final single = UniformPacker.pack(
        mode: const SingleHingeFold(),
        state: state,
        params: params,
        effects: effects,
        pixelsPerMillimeter: 6.0,
      );
      expect(single.length, const SingleHingeFold().customUniformCount);

      final book = UniformPacker.pack(
        mode: const BookFold(hingePosition: 0.7),
        state: state,
        params: params,
        effects: effects,
        pixelsPerMillimeter: 6.0,
      );
      expect(book.length, const BookFold().customUniformCount);
      expect(book[14], 0.7);

      final accordion = UniformPacker.pack(
        mode: const AccordionFold(foldCount: 5),
        state: state,
        params: params,
        effects: effects,
        pixelsPerMillimeter: 6.0,
      );
      expect(accordion.length, const AccordionFold().customUniformCount);
      expect(accordion[14], 5.0);
    });
  });

  group('AdaptiveQuality', () {
    test('default level is high with 32 max blur taps', () {
      final quality = AdaptiveQuality();
      expect(quality.current, QualityLevel.high);
      expect(quality.maxBlurTaps, 32);
    });

    test('override locks quality and ignores reportFrameTime', () {
      final quality = AdaptiveQuality();
      quality.override(QualityLevel.low);
      expect(quality.current, QualityLevel.low);
      expect(quality.maxBlurTaps, 8);

      final changed = quality.reportFrameTime(const Duration(milliseconds: 2));
      expect(changed, isFalse);
      expect(quality.current, QualityLevel.low);

      quality.unlock();
      final upgraded = quality.reportFrameTime(const Duration(milliseconds: 2));
      expect(upgraded, isTrue);
      expect(quality.current, QualityLevel.medium);
    });

    test('reportFrameTime steps down when frames run long', () {
      final quality = AdaptiveQuality(targetFrameTime: const Duration(milliseconds: 16));
      expect(quality.current, QualityLevel.high);

      // Frame runs at 25ms (> 16 * 1.25 = 20ms) -> drops to medium
      final changed = quality.reportFrameTime(const Duration(milliseconds: 25));
      expect(changed, isTrue);
      expect(quality.current, QualityLevel.medium);

      // Another slow frame -> drops to low
      final changed2 = quality.reportFrameTime(const Duration(milliseconds: 25));
      expect(changed2, isTrue);
      expect(quality.current, QualityLevel.low);
    });
  });

  group('ShaderManager', () {
    test('firstCustomFloatIndex is 2 (engine owns size 0,1)', () {
      expect(ShaderManager.firstCustomFloatIndex, 2);
    });
  });
}
