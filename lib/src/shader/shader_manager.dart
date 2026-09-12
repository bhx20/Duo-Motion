import 'dart:ui' as ui;

import '../core/fold_mode.dart';
import '../errors/fold_errors.dart';

/// Manages the asynchronous compilation, caching, and uniform uploading for Impeller shaders.
///
/// Under Flutter Impeller, [ui.FragmentProgram] compilation is asynchronous and can take
/// tens of milliseconds on first load. [ShaderManager] ensures that each shader asset
/// is compiled at most once per application process and cached globally in memory.
abstract final class ShaderManager {
  static final Map<String, Future<ui.FragmentProgram>> _programs = {};

  /// First custom float uniform index in Flutter's ImageFilter shader pipeline.
  ///
  /// Floats 0 and 1 are owned and automatically populated by the Flutter engine
  /// with the input raster layer dimensions `(width, height)`. Custom uniforms begin at index 2.
  static const int firstCustomFloatIndex = 2;

  /// Retrieves the compiled [ui.FragmentProgram] for the specified [FoldMode].
  ///
  /// Subsequent calls return the cached future immediately without redundant IO.
  static Future<ui.FragmentProgram> program(FoldMode mode) {
    return _programs.putIfAbsent(mode.shaderAssetKey, () => _load(mode.shaderAssetKey));
  }

  static Future<ui.FragmentProgram> _load(String assetKey) async {
    try {
      return await ui.FragmentProgram.fromAsset(assetKey);
    } on Object catch (error) {
      // Invalidate cache entry on failure so future attempts can retry
      _programs.remove(assetKey);
      throw DuoFoldShaderError(
        'Could not load shader asset $assetKey. Verify that it is declared under '
        'flutter.shaders in pubspec.yaml and that the application was rebuilt.',
        error,
      );
    }
  }

  /// Instantiates a fresh [ui.FragmentShader] execution instance for the requested [FoldMode].
  static Future<ui.FragmentShader> createShader(FoldMode mode) async {
    final prog = await program(mode);
    return prog.fragmentShader();
  }

  /// Uploads a packed list of float uniforms into the target [shader] instance.
  ///
  /// Automatically offsets the index by [firstCustomFloatIndex] (2).
  static void applyUniforms(ui.FragmentShader shader, List<double> uniforms) {
    for (var i = 0; i < uniforms.length; i++) {
      shader.setFloat(firstCustomFloatIndex + i, uniforms[i]);
    }
  }

  /// Clears the cached program table. Primarily utilized for test isolation and teardown.
  static void resetForTesting() {
    _programs.clear();
  }
}
