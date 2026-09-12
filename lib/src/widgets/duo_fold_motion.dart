import 'package:flutter/widgets.dart';

import '../controller/fold_controller.dart';
import '../core/fold_effects.dart';
import '../core/fold_mode.dart';
import '../core/fold_parameters.dart';
import '../shader/adaptive_quality.dart';
import 'duo_fold.dart';

/// Sensor-driven fold widget that automatically rebuilds when [controller] publishes motion updates.
///
/// Binds directly to a [FoldController] using a high-efficiency [ListenableBuilder],
/// updating shader uniforms whenever incoming gyroscope samples or manual changes occur.
///
/// Features:
/// - Rebuilds the underlying [DuoFold] shader parameters without dirtying or re-rendering [child].
/// - Inherits mode, effects, parameters, and display density from the controller or enclosing theme.
class DuoFoldMotion extends StatelessWidget {
  /// Wraps [child] in a sensor-driven fold.
  const DuoFoldMotion({
    super.key,
    required this.controller,
    this.mode,
    this.parameters,
    this.surroundColor,
    this.effects,
    this.quality,
    this.enabled = true,
    required this.child,
  });

  /// Main controller providing real-time fold state and hardware metrics.
  final FoldController controller;

  /// Optional geometric mode override (SingleHingeFold, BookFold, AccordionFold).
  /// Falls back to controller mode or theme.
  final FoldMode? mode;

  /// Optional physical viewing parameters override. Falls back to controller or theme.
  final FoldParameters? parameters;

  /// Optional shorthand override for the background/surround color revealed behind the fold.
  final Color? surroundColor;

  /// Optional optical effects override (caustics, shadows). Falls back to controller effects or theme.
  final FoldEffects? effects;

  /// Optional shader quality tier override.
  final QualityLevel? quality;

  /// Whether the fold effect is active. When false, bypasses the shader pipeline.
  final bool enabled;

  /// Child widget subtree displayed behind the optical glass fold.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return DuoFold(
          state: controller.state,
          mode: mode ?? controller.mode,
          parameters: parameters ?? controller.parameters,
          surroundColor: surroundColor,
          effects: effects ?? controller.effects,
          pixelsPerMillimeter: controller.pixelsPerMillimeter,
          quality: quality,
          enabled: enabled,
          child: child,
        );
      },
    );
  }
}
