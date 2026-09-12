/// Quality tiers trading GPU blur tap budgets against frame-rate stability.
///
/// Gaussian and Poisson disk optical blurs are proportional in cost to the number
/// of texture samples (taps) executed per fragment. Lowering taps preserves 60/120fps
/// on entry-level hardware or during thermal throttling.
enum QualityLevel {
  /// 8 blur taps. Minimal GPU overhead; recommended for entry-level devices or thermal load.
  low,

  /// 16 blur taps. Well-balanced fidelity and performance for mid-range devices.
  medium,

  /// 32 blur taps. Full photorealistic frosted glass fidelity (default tier).
  high,

  /// 48 blur taps. Ultra-fine optical dispersion for high-refresh 120Hz tablets and desktops.
  ultra,
}

/// Dynamic frame-budget monitor that steps down GPU sampling tiers if frames drop below target.
///
/// Tracks real-world frame render times against a [targetFrameTime] (e.g. 16.6ms for 60fps).
/// If frame rendering time exceeds the budget by 25%, quality degrades progressively
/// (ultra -> high -> medium -> low). When performance recovers sustainably, it steps back up.
class AdaptiveQuality {
  /// Creates an adaptive quality coordinator.
  AdaptiveQuality({
    this.targetFrameTime = const Duration(milliseconds: 16),
  });

  /// Target frame rendering duration threshold (16ms = 60fps, 8ms = 120fps).
  final Duration targetFrameTime;

  QualityLevel _current = QualityLevel.high;
  bool _isLocked = false;

  /// The currently active quality tier.
  QualityLevel get current => _current;

  /// Returns the maximum blur sampling taps corresponding to the active quality tier.
  int get maxBlurTaps => switch (_current) {
    QualityLevel.low => 8,
    QualityLevel.medium => 16,
    QualityLevel.high => 32,
    QualityLevel.ultra => 48,
  };

  /// Manually locks quality to [level], disabling automated frame-time scaling.
  void override(QualityLevel level) {
    _current = level;
    _isLocked = true;
  }

  /// Clears manual lock and restores dynamic automated frame-time scaling.
  void unlock() {
    _isLocked = false;
  }

  /// Evaluates an observed frame render duration [elapsed].
  ///
  /// Returns `true` if a tier transition occurred, triggering shader recompilation/re-binding.
  bool reportFrameTime(Duration elapsed) {
    if (_isLocked) return false;

    // Downgrade if frame elapsed time exceeds budget by > 25% (dropping frames)
    if (elapsed > targetFrameTime * 1.25) {
      if (_current == QualityLevel.ultra) {
        _current = QualityLevel.high;
        return true;
      } else if (_current == QualityLevel.high) {
        _current = QualityLevel.medium;
        return true;
      } else if (_current == QualityLevel.medium) {
        _current = QualityLevel.low;
        return true;
      }
    } else if (elapsed < targetFrameTime * 0.6) {
      // Upgrade if comfortably and consistently under budget (< 60% of frame time)
      if (_current == QualityLevel.low) {
        _current = QualityLevel.medium;
        return true;
      } else if (_current == QualityLevel.medium) {
        _current = QualityLevel.high;
        return true;
      }
    }
    return false;
  }
}
