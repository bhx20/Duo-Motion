import 'dart:math' as math;

import '../core/fold_state.dart';
export '../core/fold_state.dart';
import '../core/matrix3.dart';
import 'motion_sample.dart';

/// Single-axis digital signal processing filter implementing:
/// 1. **Velocity Extrapolation (Latency Prediction)**: Offsets the measured angle forward
///    by `omega * predictionInterval` (40ms) to counteract display and compositor latency.
/// 2. **Continuous Drift Washout (Auto-Recentering)**: When the device is held stationary
///    (`omegaMagnitude < stillThreshold`), slowly leaches out accumulated DC offset over
///    time constant tau = 15 seconds.
/// 3. **Exponential Low-Pass Smoothing**: Smooths high-frequency sensor noise.
class _AxisFilter {
  double tiltRadians = 0;
  double baselineRadians = 0;
  double lastPredicted = 0;

  /// Clears filter state to zero.
  void reset() {
    tiltRadians = 0;
    baselineRadians = 0;
    lastPredicted = 0;
  }

  /// Sets the baseline to the current angle so that recentering starts from the active pose.
  void snapBaseline() {
    baselineRadians = Matrix3.wrapAngle(lastPredicted - tiltRadians);
  }

  /// Filters a single axis sensor measurement.
  double update({
    required double measured,
    required double omega,
    required bool hasGyro,
    required double dt,
    required bool autoRecenter,
    required bool still,
    double tau = FoldMotionModel.recenterTau,
  }) {
    // Step 1: Forward latency prediction using gyro angular rate
    var predicted = measured;
    if (hasGyro) {
      predicted = measured + omega * FoldMotionModel.predictionInterval;
    }
    lastPredicted = predicted;

    // Step 2: Exponential baseline drift washout if stationary
    if (autoRecenter && still) {
      final alpha =
          (dt / tau).clamp(0.0, 1.0).toDouble();
      baselineRadians +=
          Matrix3.wrapAngle(predicted - baselineRadians) * alpha;
    }

    // Step 3: Compute relative target deviation from baseline
    final target = autoRecenter
        ? Matrix3.wrapAngle(predicted - baselineRadians)
        : predicted;

    // Step 4: Low-pass filter toward target angle
    tiltRadians +=
        Matrix3.wrapAngle(target - tiltRadians) * FoldMotionModel.smoothing;
    return tiltRadians;
  }
}

/// Transforms high-rate raw sensor readings into a smoothed, self-calibrating [FoldState].
///
/// Designed as a pure Dart mathematical pipeline without Flutter UI or platform dependencies,
/// enabling 100% deterministic unit testing and verification.
///
/// ### Pipeline Architecture
/// 1. **Reference Frame Calibration**: Upon startup or [recalibrate], captures the first
///    pose as `R_reference`. All future samples are expressed relative to this frame:
///    $$R_{\text{relative}} = R_{\text{reference}}^T \cdot R_{\text{sample}}$$
/// 2. **Tilt Extraction**: Extracts horizontal (yaw/roll) and vertical (pitch) tilt
///    angles from the relative matrix normal column using `atan2`.
/// 3. **Per-Axis Filtering**: Passes X and Y excursions through [_AxisFilter] for latency
///    prediction, low-pass noise suppression, and slow recentering.
/// 4. **Vector Normalization**: Combines the filtered angles into a total tilt magnitude
///    clamped to 45° and a normalized 2D unit lift direction vector.
class FoldMotionModel {
  /// Creates a motion model. [autoRecenter] can be toggled dynamically at runtime.
  FoldMotionModel({bool autoRecenter = true}) {
    _autoRecenter = autoRecenter;
  }

  /// Low-pass filter smoothing coefficient (fraction of remaining error closed per sample).
  static const double smoothing = 0.7;

  /// Gyroscope forward latency prediction horizon in seconds (40ms).
  static const double predictionInterval = 0.04;

  /// Time constant for the slow auto-recentering drift washout, in seconds (15s).
  static const double recenterTau = 15;

  /// Angular velocity threshold below which the device is considered stationary (rad/s).
  static const double stillThreshold = 0.15;

  /// Maximum physical fold tilt angle magnitude in degrees.
  static const double maxTiltDegrees = 45;

  static const double _liftDirEpsilonDegrees = 1e-9;

  List<double>? _reference;
  bool _pendingRecalibrate = false;
  final _AxisFilter _axisX = _AxisFilter();
  final _AxisFilter _axisY = _AxisFilter();
  double? _lastTimestampSeconds;
  bool _autoRecenter = true;
  FoldState _state = FoldState.zero;

  /// Latest resolved canonical fold state.
  FoldState get state => _state;

  /// Whether the slow auto-recenter drift washout filter is actively running.
  bool get autoRecenter => _autoRecenter;

  set autoRecenter(bool value) {
    if (value == _autoRecenter) return;
    _autoRecenter = value;
    if (value) {
      _axisX.snapBaseline();
      _axisY.snapBaseline();
    }
  }

  double _stillTime = 0.0;

  /// Flags the filter to re-zero its orientation baseline on the next incoming sensor sample.
  void recalibrate() {
    _pendingRecalibrate = true;
    _stillTime = 0.0;
    _axisX.reset();
    _axisY.reset();
    _lastTimestampSeconds = null;
    _state = FoldState.zero;
  }

  /// Ingests a high-frequency native [MotionSample] and computes the updated [FoldState].
  FoldState update(MotionSample sample) {
    // If not calibrated yet, latch the current pose as the origin reference frame
    if (_reference == null || _pendingRecalibrate) {
      _reference = List<double>.of(sample.screenMatrix);
      _pendingRecalibrate = false;
      _stillTime = 0.0;
      _axisX.reset();
      _axisY.reset();
      _lastTimestampSeconds = sample.timestampSeconds;
      return _state = FoldState.zero;
    }

    // Express current rotation relative to reference: R_rel = R_ref^T * R_cur
    final relative = Matrix3.multiply(
      Matrix3.transpose(_reference!),
      sample.screenMatrix,
    );
    final measuredX = Matrix3.screenNormalTilt(relative);
    final measuredY = math.atan2(relative[5], relative[8]);

    // Calculate time delta between consecutive sensor frames
    final previous = _lastTimestampSeconds;
    final dt = previous == null
        ? 0.02
        : (sample.timestampSeconds - previous).clamp(0.0, 0.5).toDouble();
    _lastTimestampSeconds = sample.timestampSeconds;

    final still = sample.hasGyro && sample.omegaMagnitude < stillThreshold;
    if (still) {
      _stillTime += dt;
    } else {
      _stillTime = 0.0;
    }

    // When resting motionless on a desk stand or flat surface for >1.0s,
    // adaptively accelerate recenter tau from 15s down to 1.8s so stand tilt settles to 0°.
    final tau = _stillTime > 1.0
        ? math.max(1.8, FoldMotionModel.recenterTau - (_stillTime - 1.0) * 6.0)
        : FoldMotionModel.recenterTau;

    // Filter both axes with latency prediction and drift washout
    final tiltRadiansX = _axisX.update(
      measured: measuredX,
      omega: sample.omegaScreenY,
      hasGyro: sample.hasGyro,
      dt: dt,
      autoRecenter: _autoRecenter,
      still: still,
      tau: tau,
    );
    final tiltRadiansY = _axisY.update(
      measured: measuredY,
      omega: -sample.omegaScreenX,
      hasGyro: sample.hasGyro,
      dt: dt,
      autoRecenter: _autoRecenter,
      still: still,
      tau: tau,
    );

    // Convert radians to degrees
    final tiltDegreesX = tiltRadiansX * 180 / math.pi;
    final tiltDegreesY = tiltRadiansY * 180 / math.pi;

    // Total tilt magnitude
    final magnitude = math
        .sqrt(tiltDegreesX * tiltDegreesX + tiltDegreesY * tiltDegreesY)
        .clamp(0.0, maxTiltDegrees)
        .toDouble();

    // Map screen-relative tilt into unit lift vector
    final rawDirX = -tiltDegreesX;
    final rawDirY = tiltDegreesY;
    final dirNorm = math.sqrt(rawDirX * rawDirX + rawDirY * rawDirY);

    double liftDirX;
    double liftDirY;
    if (dirNorm < _liftDirEpsilonDegrees) {
      liftDirX = FoldState.zero.liftDirX;
      liftDirY = FoldState.zero.liftDirY;
    } else {
      liftDirX = rawDirX / dirNorm;
      liftDirY = rawDirY / dirNorm;
    }

    return _state = FoldState(
      tiltDegrees: magnitude,
      liftDirX: liftDirX,
      liftDirY: liftDirY,
    );
  }
}
