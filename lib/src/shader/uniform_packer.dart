import '../core/fold_effects.dart';
import '../core/fold_mode.dart';
import '../core/fold_parameters.dart';
import '../core/fold_state.dart';

/// Serializes high-level Dart fold models into flat float uniform arrays matching
/// the exact binary layout declared in each Impeller fragment shader (`glsl/`).
///
/// ### Uniform Index Conventions
/// In Flutter Impeller's `ui.ImageFilter.shader`:
/// - Float uniform index 0: Input layer width (engine-owned).
/// - Float uniform index 1: Input layer height (engine-owned).
/// - Float uniform index 2+: Custom shader uniforms populated by [UniformPacker].
///
/// Colors are deliberately passed as triplets of individual scalars (`r, g, b`)
/// rather than GPU `vec3` or `vec4` to avoid architecture-specific std140/std430
/// byte alignment padding shifts.
abstract final class UniformPacker {
  /// Packs the 17 custom float uniforms for [SingleHingeFold] (floats 2..18 in GLSL):
  ///
  /// - `0..13`: Base optical uniforms from [FoldParameters.packUniforms]
  ///   (`uTiltDegrees`, `uLiftDirX`, `uLiftDirY`, `uEyeDistancePx`, `uBlurSpread`,
  ///    `uDarkening`, `uSurroundColor.rgb`, `uHazeColor.rgb`, `uBaseBlurPx`, `uStretchEdges`)
  /// - `14`: `uCausticIntensity`
  /// - `15`: `uShadowIntensity`
  /// - `16`: `uShadowSoftness`
  static List<double> packSingleHinge({
    required FoldState state,
    required FoldParameters params,
    required FoldEffects effects,
    required double pixelsPerMillimeter,
  }) {
    final base = params.packUniforms(
      tiltDegrees: state.tiltDegrees,
      liftDirX: state.liftDirX,
      liftDirY: state.liftDirY,
      pixelsPerMillimeter: pixelsPerMillimeter,
    );
    return <double>[
      ...base,
      effects.causticIntensity,
      effects.shadowIntensity,
      effects.shadowSoftness,
    ];
  }

  /// Packs the 18 custom float uniforms for [BookFold] (floats 2..19 in GLSL):
  ///
  /// - `0..13`: Base optical uniforms from [FoldParameters.packUniforms]
  /// - `14`: `uHingePosition` (normalized 0.0..1.0 coordinate of the central spine)
  /// - `15`: `uCausticIntensity`
  /// - `16`: `uShadowIntensity`
  /// - `17`: `uShadowSoftness`
  static List<double> packBookFold({
    required FoldState state,
    required FoldParameters params,
    required FoldEffects effects,
    required double hingePosition,
    required double pixelsPerMillimeter,
  }) {
    final base = params.packUniforms(
      tiltDegrees: state.tiltDegrees,
      liftDirX: state.liftDirX,
      liftDirY: state.liftDirY,
      pixelsPerMillimeter: pixelsPerMillimeter,
    );
    return <double>[
      ...base,
      hingePosition.clamp(0.0, 1.0),
      effects.causticIntensity,
      effects.shadowIntensity,
      effects.shadowSoftness,
    ];
  }

  /// Packs the 18 custom float uniforms for [AccordionFold] (floats 2..19 in GLSL):
  ///
  /// - `0..13`: Base optical uniforms from [FoldParameters.packUniforms]
  /// - `14`: `uFoldCount` (number of alternating paper fold segments, clamped to 2..16)
  /// - `15`: `uCausticIntensity`
  /// - `16`: `uShadowIntensity`
  /// - `17`: `uShadowSoftness`
  static List<double> packAccordion({
    required FoldState state,
    required FoldParameters params,
    required FoldEffects effects,
    required int foldCount,
    required double pixelsPerMillimeter,
  }) {
    final base = params.packUniforms(
      tiltDegrees: state.tiltDegrees,
      liftDirX: state.liftDirX,
      liftDirY: state.liftDirY,
      pixelsPerMillimeter: pixelsPerMillimeter,
    );
    return <double>[
      ...base,
      foldCount.toDouble().clamp(2.0, 16.0),
      effects.causticIntensity,
      effects.shadowIntensity,
      effects.shadowSoftness,
    ];
  }

  /// Dispatches uniform packing dynamically according to the concrete [FoldMode] subtype.
  static List<double> pack({
    required FoldMode mode,
    required FoldState state,
    required FoldParameters params,
    required FoldEffects effects,
    required double pixelsPerMillimeter,
  }) => switch (mode) {
    SingleHingeFold() => packSingleHinge(
      state: state,
      params: params,
      effects: effects,
      pixelsPerMillimeter: pixelsPerMillimeter,
    ),
    BookFold(hingePosition: final hp) => packBookFold(
      state: state,
      params: params,
      effects: effects,
      hingePosition: hp,
      pixelsPerMillimeter: pixelsPerMillimeter,
    ),
    AccordionFold(foldCount: final fc) => packAccordion(
      state: state,
      params: params,
      effects: effects,
      foldCount: fc,
      pixelsPerMillimeter: pixelsPerMillimeter,
    ),
  };
}
