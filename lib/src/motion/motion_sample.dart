/// Single orientation frame reading, reduced to screen axes by the native platform.
///
/// Plain Dart model with zero Flutter UI imports, allowing the motion pipeline
/// and physics engines to be executed and tested without platform hardware.
class MotionSample {
  /// Creates a motion sample. [screenMatrix] must be a flat row-major 3x3 array of 9 elements.
  const MotionSample({
    required this.screenMatrix,
    required this.omegaScreenY,
    required this.omegaScreenX,
    required this.omegaMagnitude,
    required this.hasGyro,
    required this.timestampSeconds,
  });

  /// Current 3D device orientation matrix, columns being screen-right, screen-up, and screen-normal.
  final List<double> screenMatrix;

  /// Angular velocity rate about the screen's up axis (Y), in radians per second.
  final double omegaScreenY;

  /// Angular velocity rate about the screen's right axis (X), in radians per second.
  final double omegaScreenX;

  /// Magnitude of the combined 3D angular rate gyro vector, in radians per second.
  final double omegaMagnitude;

  /// Whether an operational hardware gyroscope reading backed this sample.
  final bool hasGyro;

  /// Hardware sensor timestamp in seconds (used exclusively for delta time `dt` calculations).
  final double timestampSeconds;
}
