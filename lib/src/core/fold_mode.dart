/// Sealed hierarchy defining the geometric deformation mode for the fold effect.
///
/// Each mode corresponds directly to an Impeller fragment shader asset declared
/// in `glsl/`. [ShaderManager] compiles and caches the shader per mode, while
/// [UniformPacker] packs the exact binary buffer layout expected by that shader.
sealed class FoldMode {
  /// Base constructor.
  const FoldMode();

  /// Runtime asset key for the Impeller fragment shader compiled for this mode.
  String get shaderAssetKey;

  /// Number of custom float uniforms this mode's shader expects.
  ///
  /// Note: The first two floats (indices 0 and 1) in Flutter ImageFilter shaders
  /// are reserved and automatically populated by the engine with the input texture size.
  /// Custom uniforms start at index 2.
  int get customUniformCount;
}

/// Single-hinge fold: a planar pane anchored along one edge lifts away from the viewer.
///
/// This is the classic Duo/Apple fold effect.
///
/// Uniforms expected: 17 custom floats (indices 2..18).
final class SingleHingeFold extends FoldMode {
  /// Creates a single-hinge fold mode.
  const SingleHingeFold();

  @override
  String get shaderAssetKey =>
      'packages/duo_motion/glsl/duo_motion_single.frag';

  @override
  int get customUniformCount => 17;

  @override
  bool operator ==(Object other) => other is SingleHingeFold;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'SingleHingeFold()';
}

/// Book fold: two panels hinged at a central or offset spine line, folding like an open book.
///
/// As the device tilts or drag occurs, both leaves fold inward symmetrically or relative
/// to the spine line.
///
/// Uniforms expected: 18 custom floats (indices 2..19), including `uHingePosition`.
final class BookFold extends FoldMode {
  /// Creates a book fold mode.
  ///
  /// [hingePosition] specifies the normalized 0.0..1.0 coordinate across the card width
  /// where the spine hinge is placed. `0.5` represents dead center.
  const BookFold({this.hingePosition = 0.5});

  /// Normalized position of the spine hinge across the content width (0.0 = left edge, 1.0 = right edge).
  final double hingePosition;

  @override
  String get shaderAssetKey =>
      'packages/duo_motion/glsl/duo_motion_book.frag';

  @override
  int get customUniformCount => 18;

  @override
  bool operator ==(Object other) =>
      other is BookFold && other.hingePosition == hingePosition;

  @override
  int get hashCode => Object.hash(runtimeType, hingePosition);

  @override
  String toString() => 'BookFold(hinge: $hingePosition)';
}

/// Accordion fold: multi-segment paper fan folding with alternating panel hinges.
///
/// Alternates fold lift directions between adjacent segments across the card width,
/// creating a 3D pleated concertina paper deformation.
///
/// Uniforms expected: 18 custom floats (indices 2..19), including `uFoldCount`.
final class AccordionFold extends FoldMode {
  /// Creates an accordion fold mode.
  ///
  /// [foldCount] defines the number of alternating fold segments (minimum 2, clamped to 16).
  const AccordionFold({this.foldCount = 3});

  /// Number of alternating fold segments.
  final int foldCount;

  @override
  String get shaderAssetKey =>
      'packages/duo_motion/glsl/duo_motion_accordion.frag';

  @override
  int get customUniformCount => 18;

  @override
  bool operator ==(Object other) =>
      other is AccordionFold && other.foldCount == foldCount;

  @override
  int get hashCode => Object.hash(runtimeType, foldCount);

  @override
  String toString() => 'AccordionFold(folds: $foldCount)';
}
