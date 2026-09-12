import 'fold_hinge.dart';
import 'fold_state.dart';

/// Sealed hierarchy governing which fold directions a widget or controller will respond to.
///
/// Hardware sensors (gyroscopes) and free-form 2D pan gestures can produce arbitrary
/// 360-degree rotation angles. [FoldConstraints] restricts these inputs into clean,
/// deliberate UI behaviors (such as purely horizontal card folds or locking to a single hinge).
///
/// Being a `sealed` class, consumers can perform compile-time exhaustive pattern matching.
/// The core method is [resolve], which takes a raw unconstrained [FoldState] and projects it
/// onto the permitted hinge geometry.
sealed class FoldConstraints {
  /// Base constructor.
  ///
  /// [maxTiltDegrees] sets the maximum allowable fold angle ceiling (typically clamped to 45°).
  const FoldConstraints({this.maxTiltDegrees = 45.0});

  /// Maximum allowable tilt this constraint will output, in degrees.
  final double maxTiltDegrees;

  /// Applies this constraint to a raw, free-rotation pose.
  ///
  /// Returns a new [FoldState] snapped to the allowable hinges and clamped to [maxTiltDegrees].
  FoldState resolve(FoldState raw);
}

/// Continuous 360-degree free folding: the hinge line dynamically follows device lean without axis locking.
final class FreeFoldConstraints extends FoldConstraints {
  /// Creates an unconstrained set, optionally capping at [maxTiltDegrees].
  const FreeFoldConstraints({super.maxTiltDegrees});

  @override
  FoldState resolve(FoldState raw) {
    final clamped = raw.tiltDegrees.clamp(0.0, maxTiltDegrees).toDouble();
    return raw.withTilt(clamped);
  }

  @override
  bool operator ==(Object other) =>
      other is FreeFoldConstraints && other.maxTiltDegrees == maxTiltDegrees;

  @override
  int get hashCode => Object.hash(runtimeType, maxTiltDegrees);

  @override
  String toString() => 'FreeFoldConstraints(maxTilt: ${maxTiltDegrees}deg)';
}

/// Restricts folding strictly to left and right hinges (vertical hinge axis).
///
/// This is the recommended default for phone and tablet cards, as vertical tilting
/// naturally occurs whenever a user picks up or tilts a phone toward themselves.
final class HorizontalFoldConstraints extends FoldConstraints {
  /// Creates a horizontal-only constraint.
  const HorizontalFoldConstraints({super.maxTiltDegrees});

  static const _hinges = {FoldHinge.left, FoldHinge.right};

  @override
  FoldState resolve(FoldState raw) =>
      _resolveForHinges(_hinges, raw, maxTiltDegrees);

  @override
  bool operator ==(Object other) =>
      other is HorizontalFoldConstraints &&
      other.maxTiltDegrees == maxTiltDegrees;

  @override
  int get hashCode => Object.hash(runtimeType, maxTiltDegrees);

  @override
  String toString() =>
      'HorizontalFoldConstraints(maxTilt: ${maxTiltDegrees}deg)';
}

/// Restricts folding strictly to top and bottom hinges (horizontal hinge axis).
///
/// Useful for calendar flips, bottom-sheet flaps, and vertical drawer animations.
final class VerticalFoldConstraints extends FoldConstraints {
  /// Creates a vertical-only constraint.
  const VerticalFoldConstraints({super.maxTiltDegrees});

  static const _hinges = {FoldHinge.top, FoldHinge.bottom};

  @override
  FoldState resolve(FoldState raw) =>
      _resolveForHinges(_hinges, raw, maxTiltDegrees);

  @override
  bool operator ==(Object other) =>
      other is VerticalFoldConstraints &&
      other.maxTiltDegrees == maxTiltDegrees;

  @override
  int get hashCode => Object.hash(runtimeType, maxTiltDegrees);

  @override
  String toString() =>
      'VerticalFoldConstraints(maxTilt: ${maxTiltDegrees}deg)';
}

/// Restricts folding strictly to one single fixed hinge.
///
/// Tilting in any other direction resolves to flat (tilt = 0°).
final class SingleHingeFoldConstraints extends FoldConstraints {
  /// Creates a single-hinge constraint.
  const SingleHingeFoldConstraints(this.hinge, {super.maxTiltDegrees});

  /// The only permitted hinge edge.
  final FoldHinge hinge;

  @override
  FoldState resolve(FoldState raw) =>
      _resolveForHinges({hinge}, raw, maxTiltDegrees);

  @override
  bool operator ==(Object other) =>
      other is SingleHingeFoldConstraints &&
      other.hinge == hinge &&
      other.maxTiltDegrees == maxTiltDegrees;

  @override
  int get hashCode => Object.hash(runtimeType, hinge, maxTiltDegrees);

  @override
  String toString() =>
      'SingleHingeFoldConstraints($hinge, maxTilt: ${maxTiltDegrees}deg)';
}

/// Restricts folding to an arbitrary user-defined subset of hinges (e.g. only Left and Top).
final class CustomFoldConstraints extends FoldConstraints {
  /// Creates a constraint for an arbitrary set of hinges.
  CustomFoldConstraints(Set<FoldHinge> hinges, {super.maxTiltDegrees})
    : _hinges = Set<FoldHinge>.unmodifiable(hinges);

  final Set<FoldHinge> _hinges;

  /// The allowed hinges (unmodifiable set view).
  Set<FoldHinge> get allowedHinges => _hinges;

  @override
  FoldState resolve(FoldState raw) =>
      _resolveForHinges(_hinges, raw, maxTiltDegrees);

  @override
  bool operator ==(Object other) =>
      other is CustomFoldConstraints &&
      other.maxTiltDegrees == maxTiltDegrees &&
      _setEquals(other._hinges, _hinges);

  @override
  int get hashCode =>
      Object.hash(runtimeType, Object.hashAllUnordered(_hinges), maxTiltDegrees);

  @override
  String toString() =>
      'CustomFoldConstraints($_hinges, maxTilt: ${maxTiltDegrees}deg)';
}

// ---------------------------------------------------------------------------
// Shared Vector Resolution Math
// ---------------------------------------------------------------------------

/// Projects a continuous 2D lift direction vector onto a discrete set of permitted hinges.
///
/// Mathematical approach:
/// 1. Clamps raw tilt to [maxTilt].
/// 2. Iterates over all allowable hinges and computes the dot product (cosine of angle):
///    `cos(theta) = raw_dir • hinge_dir`
/// 3. Finds the hinge with the maximum positive dot product (highest directional alignment).
/// 4. If the best alignment is negative or zero, the motion is orthogonal or opposing,
///    so the output settles to flat (tilt = 0).
/// 5. Otherwise, scales the tilt by the projection magnitude: `tilt * cos(theta)` and snaps
///    the lift direction to the chosen hinge's unit axis.
FoldState _resolveForHinges(
  Set<FoldHinge> hinges,
  FoldState raw,
  double maxTilt,
) {
  final clamped = raw.tiltDegrees.clamp(0.0, maxTilt).toDouble();
  if (hinges.isEmpty || clamped <= 0) {
    return FoldState(
      tiltDegrees: 0,
      liftDirX: raw.liftDirX,
      liftDirY: raw.liftDirY,
    );
  }

  FoldHinge? bestHinge;
  var bestCosine = double.negativeInfinity;

  // Find hinge with maximum positive dot product projection
  for (final hinge in hinges) {
    final cosine =
        raw.liftDirX * hinge.liftDirX + raw.liftDirY * hinge.liftDirY;
    if (cosine > bestCosine) {
      bestCosine = cosine;
      bestHinge = hinge;
    }
  }

  // If no hinge aligns with the direction of travel, fold resolves to flat
  if (bestHinge == null || bestCosine <= 0) {
    return FoldState(
      tiltDegrees: 0,
      liftDirX: raw.liftDirX,
      liftDirY: raw.liftDirY,
    );
  }

  // Scale tilt by cosine projection and snap vector to the selected hinge
  final component = (clamped * bestCosine).clamp(0.0, maxTilt).toDouble();
  return FoldState(
    tiltDegrees: component,
    liftDirX: bestHinge.liftDirX,
    liftDirY: bestHinge.liftDirY,
  );
}

/// Unordered set equality comparison helper.
bool _setEquals(Set<FoldHinge> a, Set<FoldHinge> b) =>
    a.length == b.length && a.containsAll(b);
