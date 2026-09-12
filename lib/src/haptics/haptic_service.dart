import 'package:flutter/services.dart';

import 'haptic_policy.dart';

/// Service dispatching native platform tactile haptic impulses.
///
/// Wraps Flutter's [HapticFeedback] platform channel calls in an easily
/// testable and swappable service layer.
class HapticService {
  /// Default const constructor.
  const HapticService();

  /// Triggers a native haptic impulse according to [intensity].
  Future<void> trigger(HapticIntensity intensity) async {
    switch (intensity) {
      case HapticIntensity.light:
        await HapticFeedback.lightImpact();
      case HapticIntensity.medium:
        await HapticFeedback.mediumImpact();
      case HapticIntensity.heavy:
        await HapticFeedback.heavyImpact();
      case HapticIntensity.selection:
        await HapticFeedback.selectionClick();
    }
  }
}
