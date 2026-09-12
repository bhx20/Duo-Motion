import 'dart:async';

import 'display_metrics.dart';
import 'motion_sample.dart';

export 'display_metrics.dart';
export 'motion_sample.dart';

/// Abstract contract providing native device motion samples and display metrics.
///
/// Implementations:
/// - [ChannelMotionSource]: Communicates with iOS CoreMotion and Android SensorManager via Pigeon.
/// - [FakeMotionSource]: Scriptable source for unit testing, previews, and manual simulation.
abstract class DuoMotionSource {
  /// Reads display physical pixel density and hardware sensor availability once upon startup.
  Future<DuoFoldDisplayMetrics> readMetrics();

  /// Continuous stream of orientation readings dispatched at 60Hz-120Hz.
  Stream<MotionSample> get samples;

  /// Releases native sensor event channel listeners.
  Future<void> dispose();
}

/// A scriptable motion source driven by hand, used for unit testing and emulator fallbacks.
class FakeMotionSource implements DuoMotionSource {
  /// Creates a fake motion source reporting [metrics].
  FakeMotionSource({DuoFoldDisplayMetrics metrics = _defaultMetrics}) {
    _metrics = metrics;
  }

  static const DuoFoldDisplayMetrics _defaultMetrics = DuoFoldDisplayMetrics(
    pixelsPerMillimeter: 6,
    hasRotationSensor: false,
  );

  DuoFoldDisplayMetrics _metrics = _defaultMetrics;
  final StreamController<MotionSample> _controller =
      StreamController<MotionSample>.broadcast();

  /// Emits a scripted [sample] to all active stream listeners.
  void emit(MotionSample sample) => _controller.add(sample);

  @override
  Future<DuoFoldDisplayMetrics> readMetrics() async => _metrics;

  @override
  Stream<MotionSample> get samples => _controller.stream;

  @override
  Future<void> dispose() => _controller.close();
}
