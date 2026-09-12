import 'package:duo_motion/src/controller/fold_animation_controller.dart';
import 'package:duo_motion/src/controller/fold_controller.dart';
import 'package:duo_motion/src/core/fold_constraints.dart';
import 'package:duo_motion/src/core/fold_mode.dart';
import 'package:duo_motion/src/core/fold_state.dart';
import 'package:duo_motion/src/core/snap_config.dart';
import 'package:duo_motion/src/motion/motion_source.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FoldController', () {
    test('initial state is at rest with SingleHingeFold and HorizontalFoldConstraints', () {
      final source = FakeMotionSource();
      final controller = FoldController(source: source);

      expect(controller.isAtRest, isTrue);
      expect(controller.tiltDegrees, 0.0);
      expect(controller.mode, const SingleHingeFold());
      expect(controller.constraints, isA<HorizontalFoldConstraints>());
    });

    test('manual tilt updates state and respects constraints', () {
      final source = FakeMotionSource();
      final controller = FoldController(
        source: source,
        constraints: const HorizontalFoldConstraints(),
      );

      var notified = false;
      controller.addListener(() => notified = true);

      controller.setManualTilt(25.0);
      expect(notified, isTrue);
      expect(controller.tiltDegrees, closeTo(25.0, 1e-5));
      expect(controller.liftDirection.dx, -1.0);
      expect(controller.liftDirection.dy, 0.0);
    });

    test('snapConfig quantizes tilt to nearest angle', () {
      final source = FakeMotionSource();
      final controller = FoldController(
        source: source,
        constraints: const FreeFoldConstraints(),
        snapConfig: const SnapConfig(angles: [0.0, 15.0, 30.0], threshold: 4.0),
      );

      // Set manual tilt to 14.0 -> within threshold of 15.0
      controller.setManualTilt(14.0);
      expect(controller.tiltDegrees, 15.0);

      // Set manual tilt to 22.0 -> outside threshold of 15 and 30 -> unquantized 22.0
      controller.setManualTilt(22.0);
      expect(controller.tiltDegrees, 22.0);
    });
  });

  testWidgets('FoldAnimationController smoothly updates currentState with vsync', (tester) async {
    late FoldAnimationController anim;

    await tester.pumpWidget(
      TestTickerWidget(
        onInit: (vsync) {
          anim = FoldAnimationController(
            vsync: vsync,
            duration: const Duration(milliseconds: 300),
          );
        },
      ),
    );

    expect(anim.currentState, FoldState.zero);

    anim.animateTo(const FoldState(tiltDegrees: 30.0, liftDirX: -1.0, liftDirY: 0.0));
    expect(anim.isAnimating, isTrue);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(anim.currentState.tiltDegrees, greaterThan(0.0));
    expect(anim.currentState.tiltDegrees, lessThan(30.0));

    await tester.pump(const Duration(milliseconds: 200));
    expect(anim.isAnimating, isFalse);
    expect(anim.currentState.tiltDegrees, closeTo(30.0, 1e-4));

    anim.dispose();
  });
}

class TestTickerWidget extends StatefulWidget {
  const TestTickerWidget({super.key, required this.onInit});
  final void Function(TickerProvider vsync) onInit;

  @override
  State<TestTickerWidget> createState() => _TestTickerWidgetState();
}

class _TestTickerWidgetState extends State<TestTickerWidget> with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    widget.onInit(this);
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}
