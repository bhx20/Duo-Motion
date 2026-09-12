import 'package:flutter/widgets.dart';

import '../core/fold_effects.dart';
import '../core/fold_mode.dart';
import '../core/fold_parameters.dart';
import '../core/fold_state.dart';
import '../shader/adaptive_quality.dart';
import 'duo_fold.dart';

/// Implicitly animated fold widget that smoothly animates whenever [targetState] changes.
///
/// Follows Flutter's standard implicit animation patterns (like [AnimatedContainer] or [AnimatedOpacity]):
/// - Set [targetState] to a new fold angle or lift direction in your `build()` method.
/// - The widget automatically creates a smooth tween and drives the transition using [duration] and [curve].
/// - No manual [AnimationController] or ticker lifecycle management required.
class DuoFoldAnimated extends ImplicitlyAnimatedWidget {
  /// Creates an implicitly animated fold widget.
  const DuoFoldAnimated({
    super.key,
    required this.targetState,
    this.mode,
    this.parameters,
    this.effects,
    this.quality,
    this.enabled = true,
    super.duration = const Duration(milliseconds: 350),
    super.curve = Curves.easeOutCubic,
    super.onEnd,
    required this.child,
  });

  /// The destination [FoldState] to animate toward.
  final FoldState targetState;

  /// Fold geometry mode (SingleHingeFold, BookFold, AccordionFold).
  final FoldMode? mode;

  /// Physical perspective and optical parameters.
  final FoldParameters? parameters;

  /// Visual effects (caustics, shadows, aberration).
  final FoldEffects? effects;

  /// Shader quality tier.
  final QualityLevel? quality;

  /// Whether the fold effect is enabled.
  final bool enabled;

  /// Child widget displayed behind the frosted glass pane.
  final Widget child;

  @override
  AnimatedWidgetBaseState<DuoFoldAnimated> createState() => _DuoFoldAnimatedState();
}

class _DuoFoldAnimatedState extends AnimatedWidgetBaseState<DuoFoldAnimated> {
  _FoldStateTween? _stateTween;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _stateTween = visitor(
      _stateTween,
      widget.targetState,
      (dynamic value) => _FoldStateTween(begin: value as FoldState),
    ) as _FoldStateTween?;
  }

  @override
  Widget build(BuildContext context) {
    final state = _stateTween?.evaluate(animation) ?? widget.targetState;
    return DuoFold(
      state: state,
      mode: widget.mode,
      parameters: widget.parameters,
      effects: widget.effects,
      quality: widget.quality,
      enabled: widget.enabled,
      child: widget.child,
    );
  }
}

/// Custom [Tween] handling smooth spherical/linear interpolation between [FoldState] instances.
class _FoldStateTween extends Tween<FoldState> {
  _FoldStateTween({super.begin});

  @override
  FoldState lerp(double t) {
    if (begin == null) return end ?? FoldState.zero;
    if (end == null) return begin!;
    return FoldState.lerp(begin!, end!, t);
  }
}
