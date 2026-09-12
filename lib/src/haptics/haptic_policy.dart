/// Tactile vibration intensity categories for fold interactions.
enum HapticIntensity {
  /// Subtle pulse. Suitable for continuous angle ticks or soft snaps.
  light,

  /// Defined tactile click. Default for landing on snap detents.
  medium,

  /// Strong impact. Triggered when hitting maximum fold bounds (e.g. 45° limit).
  heavy,

  /// Discreet selection click.
  selection,
}

/// Defines rules governing when haptic pulses fire during user interaction.
class HapticPolicy {
  /// Creates a [HapticPolicy] with configurable event triggers.
  const HapticPolicy({
    this.onSnap = true,
    this.onLimit = true,
    this.onFlingRelease = false,
    this.snapIntensity = HapticIntensity.light,
    this.limitIntensity = HapticIntensity.medium,
  });

  /// Preset that disables all tactile haptic feedback.
  static const HapticPolicy none = HapticPolicy(
    onSnap: false,
    onLimit: false,
    onFlingRelease: false,
  );

  /// Whether to trigger feedback when snapping to a discrete angle.
  final bool onSnap;

  /// Whether to trigger feedback when hitting maximum fold limits (e.g. 45°).
  final bool onLimit;

  /// Whether to trigger feedback at the start of an inertial fling release.
  final bool onFlingRelease;

  /// Feedback intensity applied when snapping.
  final HapticIntensity snapIntensity;

  /// Feedback intensity applied when hitting limits.
  final HapticIntensity limitIntensity;

  @override
  bool operator ==(Object other) =>
      other is HapticPolicy &&
      other.onSnap == onSnap &&
      other.onLimit == onLimit &&
      other.onFlingRelease == onFlingRelease &&
      other.snapIntensity == snapIntensity &&
      other.limitIntensity == limitIntensity;

  @override
  int get hashCode => Object.hash(
    onSnap,
    onLimit,
    onFlingRelease,
    snapIntensity,
    limitIntensity,
  );
}
