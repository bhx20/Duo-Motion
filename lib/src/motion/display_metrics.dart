/// Physical hardware characteristics of the host display and motion sensors.
class DuoFoldDisplayMetrics {
  /// Creates a display metrics snapshot.
  const DuoFoldDisplayMetrics({
    required this.pixelsPerMillimeter,
    required this.hasRotationSensor,
  });

  /// Default fallback assumed when the host platform cannot query display hardware.
  static const DuoFoldDisplayMetrics unknown = DuoFoldDisplayMetrics(
    pixelsPerMillimeter: 0,
    hasRotationSensor: false,
  );

  /// Physical display pixel density in pixels per millimetre (or 0.0 if unknown).
  final double pixelsPerMillimeter;

  /// Whether a usable gyroscope-backed rotation vector sensor exists on this device.
  final bool hasRotationSensor;

  @override
  String toString() =>
      'DuoFoldDisplayMetrics('
      '${pixelsPerMillimeter.toStringAsFixed(2)} px/mm, '
      'sensor: $hasRotationSensor)';
}
