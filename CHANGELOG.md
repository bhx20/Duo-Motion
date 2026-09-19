# Changelog

All notable changes to the `duo_motion` package will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.1] - 2026-09-19

### Changed
- Broadened SDK constraints to `sdk: '>=3.6.0 <4.0.0'` and `flutter: '>=3.27.0'` for maximum developer compatibility.
- Declared `assets/` in `pubspec.yaml`.

### Fixed
- Fixed showcase demo image URL in `README.md` and `example/README.md` to use direct raw GitHub CDN for reliable rendering on pub.dev.
- Formatted Apache 2.0 license notice with copyright author attribution.

## [1.0.0] - 2026-09-12

### Added
- **5-Layer Headless Architecture**: Redesigned the core into a clean, modular architecture with zero opinionated UI code:
  - **Layer 1 (Core & Physics)**: Zero-Flutter-UI mathematical foundation with analytical ODE solvers and immutable pose states.
  - **Layer 2 (Input & Motion)**: Axis projection gesture interpreter, hardware motion models, and sensor-to-gesture input mixer.
  - **Layer 3 (Shader Engine)**: Custom Impeller fragment shaders, binary uniform packer, shader cache manager, and adaptive frame budgeting.
  - **Layer 4 (Controllers)**: Unified `FoldController` and VSync-driven `FoldAnimationController`.
  - **Layer 5 (Widgets & Theming)**: Headless `DuoFold`, `DuoFoldInteractive`, `DuoFoldMotion`, `DuoFoldAnimated`, and `DuoFoldTheme`.
- **Authentic iPhone Duo / SoloTilt 3D Perspective Shader (`glsl/duo_motion_single.frag`)**:
  - Exact 3D observer perspective projection matching the viral iPhone Duo optical illusion:
    $$\text{eyeDistance} = 2.4 \times \max(\text{aspect}, 1.0)$$
    $$\text{depth} = \text{fromHinge} \times \text{aspect} \times \sin(\text{tilt})$$
    $$\text{perspective} = \frac{\text{eyeDistance}}{\text{eyeDistance} - \text{depth}}$$
  - **Progressive Depth-of-Field Defocus Blur**: Smooth non-linear defocus falloff that increases with physical tilt angle and distance from the hinge.
  - **Specular Glass Sheen Sweep**: Dynamic reflective light sweep across the surface responsive to tilt changes.
  - **Subpixel Trapezoid Masking**: Clean, anti-aliased edge masking with zero black line clipping or pixel crawl.
  - **Edge Darkening & Light Falloff**: Natural shadow attenuation towards the receding free edge.
- **Deep 3D Tilt Range (Up to 88.5°)**:
  - Added configurable `maxTiltDegrees` to `GestureInterpreter` and `HorizontalFoldConstraints`, supporting extreme perspective turns up to 88.5°.
- **3 Fold Geometries (`FoldMode`)**:
  - `SingleHingeFold`: Edge-anchored folding along left, right, top, or bottom hinges.
  - `BookFold`: Dual-leaf fold with configurable central spine position (`hingePosition`).
  - `AccordionFold`: Multi-segment zig-zag accordion paper fold with configurable segment counts (`foldCount`).
- **Interactive Touch Engine (`DuoFoldInteractive`)**:
  - Signed drag projection onto hinge axes with velocity tracking.
  - Automatic spring-back to flat using analytical second-order physics.
  - Inertial fling targeting and discrete angle snap points (`SnapConfig`).
- **Analytical Spring Physics (`SpringSimulation`, `SpringConfig`)**:
  - Closed-form analytical ODE solver handling under-damped, critically damped, and over-damped regimes without numerical drift or Euler integration jitter.
  - Built-in tuned presets: `SpringConfig.snappy`, `SpringConfig.bouncy`, `SpringConfig.gentle`, `SpringConfig.stiff`, and `SpringConfig.defaultConfig`.
- **Hardware Gyroscope Tracking (`DuoFoldMotion`, `FoldController`)**:
  - Real-time 60Hz–120Hz orientation streaming via native iOS `CoreMotion` and Android `SensorManager` through type-safe Pigeon platform channels.
  - Seamless zero-jump handoff between sensor tilt and manual touch gestures via `InputMixer`.
- **Implicitly Animated Widget (`DuoFoldAnimated`)**:
  - Declarative fold state animation supporting custom animation curves and durations.
- **Inherited Theming (`DuoFoldTheme`, `DuoFoldThemeData`)**:
  - Cascade default fold parameters, effects, constraints, physics, and haptics down the widget hierarchy.
- **Sensory Haptic Feedback (`HapticService`, `HapticPolicy`)**:
  - Contextual tactile feedback on drag thresholds, snap boundaries, and rest transitions.
- **Adaptive Quality (`AdaptiveQuality`)**:
  - Dynamic frame-budget monitor automatically adjusting blur taps between 8 and 48 taps to sustain 60fps/120fps under heavy load.
- **Comprehensive Showcase Application (`example/`)**:
  - Bi-directional touch drag with snappy spring return.
  - Continuous harmonic Auto-Sway demo mode replicating the iPhone Duo showcase.
  - Full portrait and landscape responsive adaptation with aspect-ratio-aware shader scaling.
  - Multi-theme switcher (Pure White, Midnight Dark, Ocean Blue, Neon Purple, Emerald Mint).

### Changed
- Refactored package namespace and symbols to clean, uniform `duo_motion` structure.
- Optimized zero-overhead fast path: automatically bypasses GPU shader allocations whenever the fold is flat (`tilt < 0.05°`) or disabled.
- Full test suite expansion to 275 unit, widget, and physics simulation tests with 100% pass rate.
