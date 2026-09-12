import 'package:duo_motion/duo_motion.dart';
import 'package:duo_motion/src/duo_fold_shader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the asset key carries the package prefix', () {
    // Shaders declared by a package are addressed through packages/<name>/.
    // Dropping the prefix is the classic way this fails only in a consumer app.
    expect(
      DuoFoldShader.assetKey,
      'packages/duo_motion/glsl/duo_motion_base.frag',
    );
  });

  test('custom floats start after the two the engine owns', () {
    expect(DuoFoldShader.firstCustomFloatIndex, 2);
  });

  test('the uniform pack length matches what the shader declares', () {
    const params = DuoFoldParameters();
    final uniforms = params.packUniforms(
      tiltDegrees: 10,
      liftDirX: -1,
      liftDirY: 0,
      pixelsPerMillimeter: 6,
    );

    // uTiltDegrees, uLiftDirX, uLiftDirY, uEyeDistancePx, uBlurSpread,
    // uDarkening, three components each for the surround and haze colours,
    // then uBaseBlurPx and uEdgeStretch.
    expect(uniforms.length, DuoFoldShader.customFloatCount);
  });
}
