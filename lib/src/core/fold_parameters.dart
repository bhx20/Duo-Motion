import 'dart:math' as math;
import 'dart:ui' as ui;

/// Physical and optical parameters defining the frosted-glass fold simulation.
///
/// Every property corresponds to a real-world physical quantity:
/// - The virtual camera represents human eyes positioned at [eyeDistanceMillimeters]
///   looking at a screen plane through an angled pane of thick frosted glass.
/// - Glass frost, scattering, and perspective distortion are calculated in real physical
///   millimeter units using [pixelsPerMillimeter], ensuring identical visual scale across
///   differing display DPI/PPI densities.
class FoldParameters {
  /// Creates a physical parameter set.
  const FoldParameters({
    this.eyeDistanceMillimeters = 450,
    this.pixelsPerMillimeter = 0,
    this.blurSpread = 0.12,
    this.darkening = 0.0084,
    this.surroundColor = const ui.Color(0xFF000000),
    this.hazeColor = const ui.Color(0xFF000000),
    this.baseBlurMillimeters = 0.10,
    this.stretchEdges = true,
    this.tiltResponse = 1,
  });

  /// Distance from the viewer's eyes to the screen in physical millimetres.
  ///
  /// Typically 300mm to 450mm for smartphones, and 500mm+ for tablets and laptops.
  /// Controls the perspective convergence of the 3D ray-casting shader.
  final double eyeDistanceMillimeters;

  /// Physical pixel density (pixels per millimetre).
  ///
  /// When `0.0`, the system queries the native display metrics (Android DisplayMetrics / iOS screen scale).
  final double pixelsPerMillimeter;

  /// Blur spread coefficient: frost blur radius gained per pixel of glass-to-content separation gap.
  ///
  /// Higher values cause the glass to frost much faster as the pane lifts away from the surface.
  final double blurSpread;

  /// Photometric light loss attenuation per pixel of blur radius.
  ///
  /// As glass frosts, scattered light dissipates, causing the image to subtly darken toward [hazeColor].
  final double darkening;

  /// Background color shown when the 3D optical refraction rays sample outside the bounds of the widget.
  final ui.Color surroundColor;

  /// Haze color that scattered light fades toward under heavy frost blur.
  final ui.Color hazeColor;

  /// Uniform baseline frost thickness applied everywhere as soon as the fold departs from rest.
  ///
  /// Without baseline blur, the hinge boundary remains artificially needle-sharp.
  /// Measured in physical millimetres to stay consistent across resolutions.
  final double baseBlurMillimeters;

  /// Whether out-of-bounds UV coordinates clamp/stretch the edge pixels or reveal [surroundColor].
  final bool stretchEdges;

  /// Non-linear tilt response power curve exponent.
  ///
  /// - `1.0`: Direct linear mapping between device tilt and fold angle.
  /// - `> 1.0`: Gentle initial response that ramps up progressively.
  /// - `< 1.0`: Immediate rapid initial response that levels off.
  final double tiltResponse;

  /// Fallback pixel density (6 px/mm ~= 152 DPI) used when hardware metrics are unavailable.
  static const double fallbackPixelsPerMillimeter = 6;

  /// Reference density that default [darkening] coefficients were calibrated against.
  static const double referencePixelsPerMillimeter = 6;

  /// Maximum physical fold angle in degrees over which the optical ray-caster remains numerically stable.
  static const double maxTiltDegrees = 45;

  /// Resolves the actual pixel density: explicit override first, then platform display metrics, then fallback.
  double resolvePixelsPerMillimeter(double? fromDisplay) {
    if (pixelsPerMillimeter > 0) return pixelsPerMillimeter;
    if (fromDisplay != null && fromDisplay.isFinite && fromDisplay > 0) {
      return fromDisplay;
    }
    return fallbackPixelsPerMillimeter;
  }

  /// Packs the base 14 custom float uniforms in exact shader declaration order:
  ///
  /// - Float 0: `uTiltDegrees` (shaped by [tiltResponse])
  /// - Float 1: `uLiftDirX`
  /// - Float 2: `uLiftDirY`
  /// - Float 3: `uEyeDistancePx` (converted from mm using screen density)
  /// - Float 4: `uBlurSpread`
  /// - Float 5: `uDarkening` (calibrated for current screen density)
  /// - Floats 6..8: `uSurroundColor` (R, G, B as separate scalars to avoid GPU alignment padding)
  /// - Floats 9..11: `uHazeColor` (R, G, B as separate scalars)
  /// - Float 12: `uBaseBlurPx`
  /// - Float 13: `uStretchEdges` (1.0 for true, 0.0 for false)
  List<double> packUniforms({
    required double tiltDegrees,
    required double liftDirX,
    required double liftDirY,
    required double pixelsPerMillimeter,
  }) {
    final clampedTilt =
        tiltDegrees.clamp(-maxTiltDegrees, maxTiltDegrees).toDouble();
    final shapedTilt = _shape(clampedTilt.abs());
    final density = math.max(pixelsPerMillimeter, 1e-6);
    return <double>[
      shapedTilt,
      liftDirX,
      liftDirY,
      eyeDistanceMillimeters * density,
      blurSpread,
      darkening * referencePixelsPerMillimeter / density,
      surroundColor.r,
      surroundColor.g,
      surroundColor.b,
      hazeColor.r,
      hazeColor.g,
      hazeColor.b,
      baseBlurMillimeters * density,
      stretchEdges ? 1.0 : 0.0,
    ];
  }

  /// Shapes the raw tilt angle using the power exponent [tiltResponse] while preserving 0° and 45° endpoints.
  double _shape(double magnitude) {
    if (tiltResponse == 1 || tiltResponse <= 0 || !tiltResponse.isFinite) {
      return magnitude;
    }
    final fraction = magnitude / maxTiltDegrees;
    return math.pow(fraction, tiltResponse).toDouble() * maxTiltDegrees;
  }

  /// Returns a copy with the given fields replaced.
  FoldParameters copyWith({
    double? eyeDistanceMillimeters,
    double? pixelsPerMillimeter,
    double? blurSpread,
    double? darkening,
    ui.Color? surroundColor,
    ui.Color? hazeColor,
    double? baseBlurMillimeters,
    bool? stretchEdges,
    double? tiltResponse,
  }) {
    return FoldParameters(
      eyeDistanceMillimeters:
          eyeDistanceMillimeters ?? this.eyeDistanceMillimeters,
      pixelsPerMillimeter: pixelsPerMillimeter ?? this.pixelsPerMillimeter,
      blurSpread: blurSpread ?? this.blurSpread,
      darkening: darkening ?? this.darkening,
      surroundColor: surroundColor ?? this.surroundColor,
      hazeColor: hazeColor ?? this.hazeColor,
      baseBlurMillimeters: baseBlurMillimeters ?? this.baseBlurMillimeters,
      stretchEdges: stretchEdges ?? this.stretchEdges,
      tiltResponse: tiltResponse ?? this.tiltResponse,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FoldParameters &&
        other.eyeDistanceMillimeters == eyeDistanceMillimeters &&
        other.pixelsPerMillimeter == pixelsPerMillimeter &&
        other.blurSpread == blurSpread &&
        other.darkening == darkening &&
        other.surroundColor == surroundColor &&
        other.hazeColor == hazeColor &&
        other.baseBlurMillimeters == baseBlurMillimeters &&
        other.stretchEdges == stretchEdges &&
        other.tiltResponse == tiltResponse;
  }

  @override
  int get hashCode => Object.hash(
    eyeDistanceMillimeters,
    pixelsPerMillimeter,
    blurSpread,
    darkening,
    surroundColor,
    hazeColor,
    baseBlurMillimeters,
    stretchEdges,
    tiltResponse,
  );

  @override
  String toString() =>
      'FoldParameters(eye: ${eyeDistanceMillimeters}mm, '
      'pxPerMm: $pixelsPerMillimeter, blur: $blurSpread, darken: $darkening, '
      'surround: $surroundColor, haze: $hazeColor, '
      'baseBlur: ${baseBlurMillimeters}mm, stretchEdges: $stretchEdges, '
      'tiltResponse: $tiltResponse)';
}
