import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'motion_api.g.dart';
import 'motion_source.dart';

/// Concrete [DuoMotionSource] communicating with Kotlin (Android) and Swift (iOS) plugins.
///
/// Uses pre-compiled, strongly-typed Pigeon platform channels to deliver binary-serialized
/// 60Hz-120Hz orientation data with near-zero memory allocation.
class ChannelMotionSource implements DuoMotionSource {
  /// Creates a channel source. The optional [api] parameter enables mock injection in unit tests.
  ChannelMotionSource({DuoMotionHostApi? api})
    : _api = api ?? DuoMotionHostApi();

  final DuoMotionHostApi _api;
  Stream<MotionSample>? _samples;

  @override
  Future<DuoFoldDisplayMetrics> readMetrics() async {
    try {
      final metrics = await _api.metrics();
      return DuoFoldDisplayMetrics(
        pixelsPerMillimeter: metrics.pixelsPerMillimeter,
        hasRotationSensor: metrics.hasRotationSensor,
      );
    } on PlatformException catch (error) {
      debugPrint('duo_motion: metrics call failed: ${error.code}');
      return DuoFoldDisplayMetrics.unknown;
    } on MissingPluginException {
      debugPrint('duo_motion: no platform implementation registered');
      return DuoFoldDisplayMetrics.unknown;
    }
  }

  @override
  Stream<MotionSample> get samples {
    return _samples ??= streamMotion()
        .handleError(_reportAndSwallow)
        .map(_toSample);
  }

  void _reportAndSwallow(Object error) {
    if (error is PlatformException) {
      debugPrint('duo_motion: motion stream error: ${error.code}');
      return;
    }
    debugPrint('duo_motion: motion stream error: $error');
  }

  /// Maps native platform [MotionFrame] into the pure Dart [MotionSample] domain model.
  MotionSample _toSample(MotionFrame frame) {
    return MotionSample(
      screenMatrix: frame.screenMatrix,
      omegaScreenY: frame.omegaScreenY,
      omegaScreenX: frame.omegaScreenX,
      omegaMagnitude: frame.omegaMagnitude,
      hasGyro: frame.hasGyro,
      timestampSeconds: frame.timestampSeconds,
    );
  }

  @override
  Future<void> dispose() async {
    _samples = null;
    try {
      await _api.stop();
    } on PlatformException catch (_) {}
    on MissingPluginException {
      // Ignore if plugin channel is not registered (e.g. in unit tests or unsupported platforms).
    }
  }
}
