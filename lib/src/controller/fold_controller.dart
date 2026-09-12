import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import '../core/fold_constraints.dart';
import '../core/fold_effects.dart';
import '../core/fold_mode.dart';
import '../core/fold_parameters.dart';
import '../core/snap_config.dart';
import '../gesture/input_mixer.dart';
import '../motion/channel_motion_source.dart';
import '../motion/fold_motion_model.dart';
import '../motion/motion_source.dart';

/// Central state orchestrator blending hardware motion sensors, manual touch,
/// constraints, and discrete snap angles.
///
/// Dispatches reactive updates as a [ChangeNotifier] that widgets ([DuoFoldMotion],
/// [DuoFoldInteractive]) listen to directly.
///
/// ### Dual-Input Architecture
/// - **Sensor Mode**: Listens to [DuoMotionSource] at 60-120Hz, filtering device attitude
///   through [FoldMotionModel] with latency prediction and drift washout.
/// - **Manual Mode**: Directly driven by touch gestures, sliders, or programmatic inputs.
/// - **Constraint & Snap Resolution**: On every state access, passes raw poses through
///   [FoldConstraints] and snaps to discrete detents configured by [SnapConfig].
class FoldController extends ChangeNotifier {
  /// Creates a [FoldController] with customizable initial configuration.
  FoldController({
    DuoMotionSource? source,
    bool autoRecenter = true,
    FoldConstraints constraints = const HorizontalFoldConstraints(),
    FoldMode mode = const SingleHingeFold(),
    FoldEffects effects = const FoldEffects(),
    FoldParameters parameters = const FoldParameters(),
    SnapConfig? snapConfig,
  })  : _source = source ?? ChannelMotionSource(),
        _model = FoldMotionModel(autoRecenter: autoRecenter),
        _constraints = constraints,
        _mode = mode,
        _effects = effects,
        _parameters = parameters,
        _snapConfig = snapConfig;

  final DuoMotionSource _source;
  final FoldMotionModel _model;

  StreamSubscription<MotionSample>? _subscription;
  DuoFoldDisplayMetrics _metrics = DuoFoldDisplayMetrics.unknown;
  FoldState _sensorState = FoldState.zero;
  FoldState _manualState = FoldState.zero;

  FoldConstraints _constraints;
  FoldMode _mode;
  FoldEffects _effects;
  FoldParameters _parameters;
  SnapConfig? _snapConfig;

  bool _useSensor = false;
  bool _started = false;

  /// Initializes hardware display metrics and subscribes to the native motion stream.
  ///
  /// Safe to call multiple times (idempotent).
  Future<void> start() async {
    if (_started) return;
    _started = true;

    _metrics = await _source.readMetrics();
    _useSensor = _metrics.hasRotationSensor;
    _subscription = _source.samples.listen(_onSample);
    notifyListeners();
  }

  /// Internal callback processing incoming high-frequency gyroscope samples.
  void _onSample(MotionSample sample) {
    _sensorState = _model.update(sample);
    if (_useSensor) {
      notifyListeners();
    }
  }

  /// Whether the host hardware device provides an operational rotation vector / gyro sensor.
  bool get hasSensor => _metrics.hasRotationSensor;

  /// Display density in physical pixels per millimeter reported by platform metrics.
  double? get pixelsPerMillimeter =>
      _metrics.pixelsPerMillimeter > 0 ? _metrics.pixelsPerMillimeter : null;

  /// Whether the native hardware sensor stream actively drives the current fold angle.
  bool get useSensor => _useSensor && hasSensor;

  set useSensor(bool value) {
    final next = value && hasSensor;
    if (next == _useSensor) return;
    _useSensor = next;
    notifyListeners();
  }

  /// Raw unconstrained sensor state snapshot. Crucial for [InputMixer] handoffs.
  FoldState get sensorState => _sensorState;

  /// Sets manual tilt degrees and optional custom unit lift direction vector.
  void setManualTilt(double degrees, {ui.Offset? liftDirection}) {
    final dirX = liftDirection?.dx ?? (degrees >= 0 ? -1.0 : 1.0);
    final dirY = liftDirection?.dy ?? 0.0;
    final maxLimit = _constraints.maxTiltDegrees > 0 ? _constraints.maxTiltDegrees : FoldMotionModel.maxTiltDegrees;
    final next = FoldState(
      tiltDegrees: degrees.abs().clamp(0.0, maxLimit),
      liftDirX: dirX,
      liftDirY: dirY,
    );

    if (next == _manualState) return;
    _manualState = next;

    if (!useSensor) {
      notifyListeners();
    }
  }

  /// Sets manual state directly with an explicit [FoldState].
  void setManualState(FoldState state) {
    if (state == _manualState) return;
    _manualState = state;
    if (!useSensor) {
      notifyListeners();
    }
  }

  /// Current raw unconstrained fold pose (active sensor reading or manual state).
  FoldState get rawState => useSensor ? _sensorState : _manualState;

  /// Current fully resolved and snapped [FoldState].
  ///
  /// Applies [constraints] and snaps to the nearest angle in [snapConfig].
  FoldState get state {
    final resolved = _constraints.resolve(rawState);
    if (_snapConfig != null && resolved.tiltDegrees > 0) {
      final snap = _snapConfig!.nearestSnap(resolved.tiltDegrees);
      if (snap != null) {
        return resolved.withTilt(snap);
      }
    }
    return resolved;
  }

  /// Shorthand getter for current tilt angle in degrees.
  double get tiltDegrees => state.tiltDegrees;

  /// Shorthand getter for current lift direction unit vector.
  ui.Offset get liftDirection => state.liftDirection;

  /// Manual tilt magnitude in degrees.
  double get manualTiltDegrees => _manualState.tiltDegrees;

  /// Whether the fold is currently at rest (tilt < 0.05°).
  bool get isAtRest => state.isAtRest;

  /// Active directional constraints restricting allowable fold axes.
  FoldConstraints get constraints => _constraints;

  set constraints(FoldConstraints value) {
    if (value == _constraints) return;
    _constraints = value;
    notifyListeners();
  }

  /// Active geometric fold mode (SingleHingeFold, BookFold, or AccordionFold).
  FoldMode get mode => _mode;

  set mode(FoldMode value) {
    if (value == _mode) return;
    _mode = value;
    notifyListeners();
  }

  /// Active optical enhancement effects (caustics, aberration, shadows).
  FoldEffects get effects => _effects;

  set effects(FoldEffects value) {
    if (value == _effects) return;
    _effects = value;
    notifyListeners();
  }

  /// Active physical and optical viewing parameters (eye distance, blur, surroundColor).
  FoldParameters get parameters => _parameters;

  set parameters(FoldParameters value) {
    if (value == _parameters) return;
    _parameters = value;
    notifyListeners();
  }

  /// Shorthand getter for the background/surround color revealed behind the 3D optical fold.
  ui.Color get surroundColor => _parameters.surroundColor;

  /// Updates [surroundColor] on the active [parameters] without overwriting other properties.
  set surroundColor(ui.Color value) {
    if (value == _parameters.surroundColor) return;
    _parameters = _parameters.copyWith(surroundColor: value);
    notifyListeners();
  }

  /// Optional discrete angle snapping rules.
  SnapConfig? get snapConfig => _snapConfig;

  set snapConfig(SnapConfig? value) {
    if (value == _snapConfig) return;
    _snapConfig = value;
    notifyListeners();
  }

  /// Whether the slow auto-recentering drift washout filter is active.
  bool get autoRecenter => _model.autoRecenter;

  set autoRecenter(bool value) {
    if (value == _model.autoRecenter) return;
    _model.autoRecenter = value;
    notifyListeners();
  }

  /// Re-zeros the sensor calibration baseline to the current phone orientation.
  void recalibrate() {
    _model.recalibrate();
    _sensorState = FoldState.zero;
    _manualState = FoldState.zero;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _source.dispose();
    super.dispose();
  }
}
