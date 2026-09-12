/// Snap-point configuration for discretizing continuous fold angles.
///
/// When attached to a [FoldController] or [DuoFoldInteractive], this system
/// creates magnetic "detents" or snap angles (e.g. 0° flat, 25° half-open, 45° full fold).
///
/// Features:
/// - **Proximity Snapping**: Automatically snaps when within [threshold] degrees of any detent.
/// - **Velocity-Biased Flings**: Touch fling gestures evaluate gesture velocity to land on
///   the next logical snap point in the direction of the swipe.
/// - **Haptics**: Triggers tactile clicks upon locking into a snap detent.
class SnapConfig {
  /// Creates a snap configuration.
  ///
  /// [angles] must be a list of non-negative tilt angles in degrees, sorted in ascending order.
  /// Example: `[0.0, 20.0, 45.0]`.
  const SnapConfig({
    required this.angles,
    this.threshold = 3.0,
    this.hapticOnSnap = true,
  });

  /// The list of discrete snap-point angles in degrees, sorted ascending.
  final List<double> angles;

  /// Distance tolerance in degrees within which an angle magnetically snaps.
  final double threshold;

  /// Whether to emit tactile feedback when a snap occurs.
  final bool hapticOnSnap;

  /// Finds the nearest snap angle if [tiltDegrees] is within [threshold] distance.
  ///
  /// Returns `null` if the tilt angle is in free space outside all snap thresholds.
  double? nearestSnap(double tiltDegrees) {
    if (angles.isEmpty) return null;

    double? closest;
    var closestDist = double.infinity;
    for (final angle in angles) {
      final dist = (tiltDegrees - angle).abs();
      if (dist < closestDist) {
        closestDist = dist;
        closest = angle;
      }
    }

    return closestDist <= threshold ? closest : null;
  }

  /// Calculates the destination snap angle for an inertial fling gesture.
  ///
  /// - Positive [velocity] indicates the user is swiping to open the fold further,
  ///   so the target is the next available snap angle above [currentTilt].
  /// - Negative [velocity] indicates closing the fold, selecting the next snap angle below.
  /// - If the fling exceeds the bounds of the snap set, clamps to the first or last angle.
  double flingTarget(double currentTilt, double velocity) {
    if (angles.isEmpty) return currentTilt;
    if (angles.length == 1) return angles.first;

    if (velocity >= 0) {
      // Swiping open: pick the next snap point higher than current tilt
      for (final angle in angles) {
        if (angle > currentTilt + 0.5) return angle;
      }
      return angles.last;
    } else {
      // Swiping closed: pick the next snap point lower than current tilt
      for (var i = angles.length - 1; i >= 0; i--) {
        if (angles[i] < currentTilt - 0.5) return angles[i];
      }
      return angles.first;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is SnapConfig &&
      other.threshold == threshold &&
      other.hapticOnSnap == hapticOnSnap &&
      _listEquals(other.angles, angles);

  @override
  int get hashCode => Object.hash(Object.hashAll(angles), threshold, hapticOnSnap);

  @override
  String toString() =>
      'SnapConfig(angles: $angles, threshold: $threshold, haptic: $hapticOnSnap)';
}

/// Helper comparing contents of two double lists for value equality.
bool _listEquals(List<double> a, List<double> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
