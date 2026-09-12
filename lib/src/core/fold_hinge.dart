/// Defines which physical screen edge a pane hinges on.
///
/// The hinge edge acts as an anchor line where the glass pane remains flush
/// with the content plane (separation distance = 0). As you move away from the
/// hinge along the lift direction, the glass pane lifts upwards in 3D space,
/// increasing optical frost blur, refraction displacement, and drop shadows.
///
/// ### Inverse Relationship to Lift Direction
/// The lift direction is always directed opposite to the hinge line:
/// - Hinged on the **left** edge $\rightarrow$ lifts toward the **right** (`+X`).
/// - Hinged on the **right** edge $\rightarrow$ lifts toward the **left** (`-X`).
/// - Hinged on the **top** edge $\rightarrow$ lifts toward the **bottom** (`+Y`).
/// - Hinged on the **bottom** edge $\rightarrow$ lifts toward the **top** (`-Y`).
enum FoldHinge {
  /// Hinge on the left edge. The pane lifts toward the right (`+X`).
  left,

  /// Hinge on the right edge. The pane lifts toward the left (`-X`).
  right,

  /// Hinge on the top edge. The pane lifts toward the bottom (`+Y`).
  top,

  /// Hinge on the bottom edge. The pane lifts toward the top (`-Y`).
  bottom,
}

/// Convenience extension mapping each [FoldHinge] to its unit lift direction
/// in fragment screen coordinates (where `X` is right and `Y` is down).
extension FoldHingeLiftDirection on FoldHinge {
  /// X component of the unit lift direction vector for this hinge.
  ///
  /// Returns `+1.0` for [FoldHinge.left], `-1.0` for [FoldHinge.right], and `0.0` for vertical hinges.
  double get liftDirX => switch (this) {
    FoldHinge.left => 1.0,
    FoldHinge.right => -1.0,
    FoldHinge.top => 0.0,
    FoldHinge.bottom => 0.0,
  };

  /// Y component of the unit lift direction vector for this hinge.
  ///
  /// Returns `+1.0` for [FoldHinge.top], `-1.0` for [FoldHinge.bottom], and `0.0` for horizontal hinges.
  double get liftDirY => switch (this) {
    FoldHinge.left => 0.0,
    FoldHinge.right => 0.0,
    FoldHinge.top => 1.0,
    FoldHinge.bottom => -1.0,
  };
}
