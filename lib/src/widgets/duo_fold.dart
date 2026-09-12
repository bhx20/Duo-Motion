import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../core/fold_effects.dart';
import '../core/fold_mode.dart';
import '../core/fold_parameters.dart';
import '../core/fold_state.dart';
import '../errors/fold_errors.dart';
import '../shader/adaptive_quality.dart';
import '../shader/shader_manager.dart';
import '../shader/uniform_packer.dart';
import 'duo_fold_theme.dart';

/// Renders [child] through an optical frosted-glass fold fragment shader.
///
/// This is the core low-level rendering widget in the `duo_motion` suite.
///
/// ### Zero-Cost Fast Path
/// Whenever the fold state is flat ([FoldState.isAtRest] `< 0.05°`), disabled ([enabled] = false),
/// or while shaders are asynchronously compiling in the background, this widget returns
/// [child] directly with **zero layer allocations and zero GPU overhead**.
///
/// ### Theme Cascading
/// Any parameter not explicitly provided here will cascade automatically from the nearest
/// enclosing [DuoFoldTheme].
class DuoFold extends StatefulWidget {
  /// Creates a fold rendering widget.
  const DuoFold({
    super.key,
    required this.state,
    this.mode,
    this.parameters,
    this.surroundColor,
    this.effects,
    this.pixelsPerMillimeter,
    this.quality,
    this.enabled = true,
    required this.child,
  });

  /// Canonical fold pose (tilt in degrees and 2D unit lift direction vector).
  final FoldState state;

  /// Geometric deformation mode (SingleHingeFold, BookFold, or AccordionFold).
  /// Falls back to theme or [SingleHingeFold].
  final FoldMode? mode;

  /// Physical perspective and optical viewing parameters. Falls back to theme or defaults.
  final FoldParameters? parameters;

  /// Optional shorthand override for the background/surround color revealed behind the fold.
  /// When provided, overrides [parameters.surroundColor].
  final ui.Color? surroundColor;

  /// Optional visual enhancement effects (caustics, aberration, shadows).
  final FoldEffects? effects;

  /// Display density in physical pixels per millimeter, or null to query platform metrics.
  final double? pixelsPerMillimeter;

  /// Quality tier controlling blur tap sampling budget.
  final QualityLevel? quality;

  /// Set to false to bypass the layer and shader entirely without rebuilding or unmounting the child.
  final bool enabled;

  /// Content sitting behind the tilting glass pane.
  final Widget child;

  @override
  State<DuoFold> createState() => _DuoFoldState();
}

class _DuoFoldState extends State<DuoFold> {
  ui.FragmentShader? _shader;
  Object? _loadError;
  FoldMode? _loadedMode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkAndLoadShader();
  }

  @override
  void didUpdateWidget(DuoFold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mode != oldWidget.mode) {
      _checkAndLoadShader();
    }
  }

  /// Resolves active fold mode from widget property, theme cascade, or default single hinge.
  FoldMode _resolveMode(BuildContext context) {
    return widget.mode ?? DuoFoldTheme.maybeOf(context)?.mode ?? const SingleHingeFold();
  }

  /// Compiles and creates a shader instance for the active mode.
  Future<void> _checkAndLoadShader() async {
    final targetMode = _resolveMode(context);
    if (_loadedMode == targetMode && _shader != null) return;

    if (kIsWeb) {
      setState(() {
        _loadError = const DuoFoldUnsupportedError(
          reason: 'Flutter web renders with CanvasKit, not Impeller',
        );
      });
      return;
    }

    try {
      final shader = await ShaderManager.createShader(targetMode);
      if (!mounted) {
        shader.dispose();
        return;
      }
      _shader?.dispose();
      setState(() {
        _shader = shader;
        _loadedMode = targetMode;
        _loadError = null;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _loadError = error);
    }
  }

  @override
  void dispose() {
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final shader = _shader;

    // FAST-PATH: If disabled, at rest (< 0.05°), or shader is loading, render child directly
    if (!widget.enabled || state.isAtRest || shader == null || _loadError != null) {
      return widget.child;
    }

    // Cascade theme configurations
    final theme = DuoFoldTheme.of(context);
    final rawParams = widget.parameters ?? theme.parameters;
    final params = widget.surroundColor != null
        ? rawParams.copyWith(surroundColor: widget.surroundColor)
        : rawParams;
    final effects = widget.effects ?? theme.effects;
    final density = params.resolvePixelsPerMillimeter(widget.pixelsPerMillimeter);
    final mode = _loadedMode ?? const SingleHingeFold();

    // Pack uniform float buffer for this mode's shader
    final uniforms = UniformPacker.pack(
      mode: mode,
      state: state,
      params: params,
      effects: effects,
      pixelsPerMillimeter: density,
    );

    // Upload uniforms into GPU shader memory
    ShaderManager.applyUniforms(shader, uniforms);

    // Instantiate Impeller ImageFilter backed by the fragment shader
    final ui.ImageFilter filter;
    try {
      filter = ui.ImageFilter.shader(shader);
    } on Object catch (cause) {
      throw DuoFoldShaderError(
        'ui.ImageFilter.shader was rejected by backend. Impeller is required.',
        cause,
      );
    }

    return ClipRect(
      child: ImageFiltered(imageFilter: filter, child: widget.child),
    );
  }
}
