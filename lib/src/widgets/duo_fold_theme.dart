import 'package:flutter/widgets.dart';

import '../core/fold_constraints.dart';
import '../core/fold_effects.dart';
import '../core/fold_mode.dart';
import '../core/fold_parameters.dart';
import '../core/snap_config.dart';
import '../haptics/haptic_policy.dart';
import '../physics/spring_config.dart';
import '../shader/adaptive_quality.dart';

/// Configuration data cascade provided by [DuoFoldTheme].
///
/// Encapsulates consistent styling defaults across multiple fold components:
/// - Optical glass parameters ([parameters])
/// - Visual enhancement effects ([effects])
/// - Fold geometry style ([mode])
/// - Motion axis constraints ([constraints])
/// - Spring physics parameters ([physics])
/// - Discrete snap points ([snapConfig])
/// - Tactile feedback rules ([hapticPolicy])
class DuoFoldThemeData {
  /// Creates a theme data set with configurable tokens.
  const DuoFoldThemeData({
    this.parameters = const FoldParameters(),
    this.effects = const FoldEffects(),
    this.mode = const SingleHingeFold(),
    this.constraints = const HorizontalFoldConstraints(),
    this.quality,
    this.physics = const SpringConfig(),
    this.snapConfig,
    this.hapticPolicy = const HapticPolicy(),
  });

  /// Default optical and perspective parameters.
  final FoldParameters parameters;

  /// Default visual enhancement effects (caustics, shadows, aberration).
  final FoldEffects effects;

  /// Default fold geometry mode.
  final FoldMode mode;

  /// Default directional constraint policy.
  final FoldConstraints constraints;

  /// Optional fixed shader quality tier override.
  final QualityLevel? quality;

  /// Default spring simulation parameters.
  final SpringConfig physics;

  /// Default snap-point configuration.
  final SnapConfig? snapConfig;

  /// Default haptic feedback policy.
  final HapticPolicy hapticPolicy;

  @override
  bool operator ==(Object other) =>
      other is DuoFoldThemeData &&
      other.parameters == parameters &&
      other.effects == effects &&
      other.mode == mode &&
      other.constraints == constraints &&
      other.quality == quality &&
      other.physics == physics &&
      other.snapConfig == snapConfig &&
      other.hapticPolicy == hapticPolicy;

  @override
  int get hashCode => Object.hash(
    parameters,
    effects,
    mode,
    constraints,
    quality,
    physics,
    snapConfig,
    hapticPolicy,
  );
}

/// [InheritedWidget] providing default fold styling tokens down the widget tree.
///
/// Any descendant [DuoFold], [DuoFoldInteractive], or [DuoFoldMotion] widget can read
/// these defaults using `DuoFoldTheme.of(context)` without redundant prop-drilling.
class DuoFoldTheme extends InheritedWidget {
  /// Wraps [child] in fold theme data.
  const DuoFoldTheme({
    super.key,
    required this.data,
    required super.child,
  });

  /// The theme tokens provided by this inherited widget.
  final DuoFoldThemeData data;

  /// Retrieves the nearest [DuoFoldThemeData], or `null` if none exists.
  static DuoFoldThemeData? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<DuoFoldTheme>()?.data;
  }

  /// Retrieves the nearest [DuoFoldThemeData] or default fallback if none exists.
  static DuoFoldThemeData of(BuildContext context) {
    return maybeOf(context) ?? const DuoFoldThemeData();
  }

  @override
  bool updateShouldNotify(DuoFoldTheme oldWidget) => data != oldWidget.data;
}
