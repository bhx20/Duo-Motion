/// DuoMotion: Next-Generation Optical Folding & Motion Animation Framework for Flutter.
///
/// This package brings Apple/Surface Duo style multi-hinge optical folding and
/// tilt-driven frosted-glass effects to Flutter, powered by custom Impeller fragment
/// shaders, second-order analytical spring physics, multi-touch gestures, and hardware
/// gyroscope tracking.
///
/// ### Architecture Overview
/// The library is organized into five decoupled layers:
///
/// - **Layer 1: Core Math & Physics Engine (Zero Flutter UI Dependencies)**
///   - [FoldState]: Immutable representation of fold angle and 2D unit lift vector.
///   - [FoldHinge]: Geometry of edge hinges (left, right, top, bottom).
///   - [FoldConstraints]: Sealed hierarchy constraining allowable folding directions.
///   - [FoldMode]: Sealed fold geometries ([SingleHingeFold], [BookFold], [AccordionFold]).
///   - [FoldEffects]: Optical enhancement parameters (caustics, aberration, shadows).
///   - [FoldParameters]: Real-world physical display and viewing optics.
///   - [Matrix3]: Row-major 3x3 rotation matrices for sensor orientation calculations.
///   - [Optics]: Ray-tracing math for glass gaps, refraction, and attenuation.
///   - [SnapConfig]: Discrete angle snapping and velocity-directed fling targeting.
///   - [SpringConfig]: Harmonic oscillator physical tuning parameters and presets.
///   - [SpringSimulation]: Analytical closed-form ordinary differential equation (ODE) solver.
///
/// - **Layer 2: Input & Motion Runtime**
///   - [GestureInterpreter]: Projects 2D screen pan drags onto hinge axes with signed velocity.
///   - [InputMixer]: Captures state during sensor-to-touch handoffs to eliminate visual jumps.
///   - [FoldMotionModel]: High-rate sensor filter with drift washout and latency prediction.
///   - [DuoMotionSource], [FakeMotionSource]: Abstractions for sensor streams and unit testing.
///   - [MotionSample], [DuoFoldDisplayMetrics]: Sensor readings and physical display density.
///
/// - **Layer 3: Shader Engine**
///   - [UniformPacker]: Packs Dart data models into exact binary float uniform buffers.
///   - [ShaderManager]: Compiles, caches, and binds Impeller [ui.FragmentProgram] instances.
///   - [AdaptiveQuality]: Monitors frame budgets to scale blur taps between 8 and 48 taps.
///
/// - **Layer 4: Controllers & Orchestration**
///   - [FoldController]: Unified reactive orchestrator blending sensors, manual touch, and snaps.
///   - [FoldAnimationController]: VSync-driven smooth interpolation between fold states.
///
/// - **Layer 5: Widgets & Theming**
///   - [DuoFold]: Base shader rasterizer with zero-cost rest bypass (< 0.05° tilt).
///   - [DuoFoldInteractive]: Full touch-interactive card with spring physics and haptics.
///   - [DuoFoldMotion]: Gyroscope-driven widget listening directly to [FoldController].
///   - [DuoFoldAnimated]: Implicitly animated widget responding to target state changes.
///   - [DuoFoldTheme], [DuoFoldThemeData]: Inherited styling cascade down the widget tree.
///
/// - **Cross-Cutting Systems**
///   - [HapticService], [HapticPolicy]: Tactile impulses on snap points, drag limits, and flings.
///   - [FoldErrors]: Typed exception hierarchy for diagnostics.
library;

// Layer 1: Core & Physics
export 'src/core/fold_constraints.dart';
export 'src/core/fold_effects.dart';
export 'src/core/fold_hinge.dart';
export 'src/core/fold_mode.dart';
export 'src/core/fold_parameters.dart';
export 'src/core/fold_state.dart';
export 'src/core/matrix3.dart';
export 'src/core/optics.dart';
export 'src/core/snap_config.dart';
export 'src/physics/spring_config.dart';
export 'src/physics/spring_simulation.dart';

// Layer 2: Input & Motion
export 'src/gesture/gesture_interpreter.dart';
export 'src/gesture/input_mixer.dart';
export 'src/motion/display_metrics.dart';
export 'src/motion/fold_motion_model.dart' show FoldMotionModel;
export 'src/motion/motion_sample.dart';
export 'src/motion/motion_source.dart' show DuoMotionSource, FakeMotionSource;

// Layer 3: Shader Engine
export 'src/shader/adaptive_quality.dart';
export 'src/shader/shader_manager.dart';
export 'src/shader/uniform_packer.dart';

// Layer 4: Controllers
export 'src/controller/fold_animation_controller.dart';
export 'src/controller/fold_controller.dart';

// Layer 5: Widgets & Theming
export 'src/widgets/duo_fold.dart';
export 'src/widgets/duo_fold_animated.dart';
export 'src/widgets/duo_fold_interactive.dart';
export 'src/widgets/duo_fold_motion.dart';
export 'src/widgets/duo_fold_theme.dart';

// Cross-cutting: Haptics & Errors
export 'src/errors/fold_errors.dart';
export 'src/haptics/haptic_policy.dart';
export 'src/haptics/haptic_service.dart';

// Backwards-compatibility aliases for legacy 0.1.0 symbols
export 'src/duo_fold_constraints.dart';
export 'src/duo_fold_controller.dart';
export 'src/duo_fold_parameters.dart';
export 'src/physics/duo_fold_physics.dart';
