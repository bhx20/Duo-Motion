/// Photorealistic optical enhancement effects layered over the frosted-glass shader.
///
/// All fields default to `0.0`, ensuring **zero additional GPU performance cost**:
/// The Impeller fragment shader uses early conditional branches that skip caustic,
/// aberration, and drop-shadow calculations entirely when their respective intensities are zero.
class FoldEffects {
  /// Creates an optical effects configuration.
  const FoldEffects({
    this.causticIntensity = 0.0,
    this.chromaticAberration = 0.0,
    this.shadowIntensity = 0.0,
    this.shadowSoftness = 0.5,
    this.lightAngle = 0.0,
  });

  /// Refractive caustic light patterns intensity, normalized from `0.0` (off) to `1.0` (vivid).
  ///
  /// Simulates focused light rays refracted through the angled frosted glass pane,
  /// creating subtle dynamic bright ripples along the fold ridge.
  final double causticIntensity;

  /// Optical chromatic dispersion coefficient (RGB channel pixel offset).
  ///
  /// Replicates prism chromatic aberration caused by wavelengths of light (red, green, blue)
  /// bending at slightly different refractive indices through thick frosted glass.
  /// Typical values range from `0.01` to `0.04`. `0.0` disables aberration.
  final double chromaticAberration;

  /// Ambient contact drop shadow opacity beneath the lifted pane, normalized from `0.0` to `1.0`.
  ///
  /// As the glass lifts away from the surface, it casts an occlusion shadow on the underlying
  /// background plane proportional to the separation gap.
  final double shadowIntensity;

  /// Softness / penumbra blur radius of the cast contact shadow edge, normalized from `0.0` to `1.0`.
  final double shadowSoftness;

  /// Direction of the incident ambient lighting source in radians (`0.0` to `2 * pi`).
  ///
  /// - `0.0`: Light shines from screen-right.
  /// - `pi / 2`: Light shines from screen-bottom.
  /// - `pi`: Light shines from screen-left.
  /// - `3 * pi / 2`: Light shines from screen-top.
  final double lightAngle;

  /// Returns a copy of this [FoldEffects] with the given fields replaced.
  FoldEffects copyWith({
    double? causticIntensity,
    double? chromaticAberration,
    double? shadowIntensity,
    double? shadowSoftness,
    double? lightAngle,
  }) {
    return FoldEffects(
      causticIntensity: causticIntensity ?? this.causticIntensity,
      chromaticAberration: chromaticAberration ?? this.chromaticAberration,
      shadowIntensity: shadowIntensity ?? this.shadowIntensity,
      shadowSoftness: shadowSoftness ?? this.shadowSoftness,
      lightAngle: lightAngle ?? this.lightAngle,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is FoldEffects &&
      other.causticIntensity == causticIntensity &&
      other.chromaticAberration == chromaticAberration &&
      other.shadowIntensity == shadowIntensity &&
      other.shadowSoftness == shadowSoftness &&
      other.lightAngle == lightAngle;

  @override
  int get hashCode => Object.hash(
    causticIntensity,
    chromaticAberration,
    shadowIntensity,
    shadowSoftness,
    lightAngle,
  );

  @override
  String toString() =>
      'FoldEffects(caustic: $causticIntensity, chromatic: $chromaticAberration, '
      'shadow: $shadowIntensity, softness: $shadowSoftness, '
      'lightAngle: $lightAngle)';
}
