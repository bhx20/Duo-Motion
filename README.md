<div align="center">

# DuoMotion

### Next-Generation 3D Optical Folding & Tilt-Motion Suite for Flutter

_Faithfully reproducing the viral iPhone Duo frosted-glass perspective illusion._

<br/>

[![Pub Version](https://img.shields.io/pub/v/duo_motion?color=007AFF&style=flat-square)](https://pub.dev/packages/duo_motion)
[![License: Apache 2.0](https://img.shields.io/badge/License-Apache_2.0-blue.svg?style=flat-square)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-%3E%3D3.27.0-02569B?logo=flutter&style=flat-square)](https://flutter.dev)
[![Tests](https://img.shields.io/badge/Tests-275%20Passing-success?style=flat-square)](test/)
[![Impeller](https://img.shields.io/badge/GPU-Impeller%20Vulkan-black?style=flat-square)](glsl/)
[![Performance](https://img.shields.io/badge/Hardware%20Performance-90.0%20FPS%20%7C%205.4ms%20GPU-00C853?style=flat-square)](#hardware-performance--benchmark-showcase)

<br/>

<p align="center">
  <img src="https://raw.githubusercontent.com/bhx20/duo_motion/main/assets/showcase.webp" alt="DuoMotion Showcase Demo" width="360" />
</p>

<br/>

[The iPhone Duo Illusion](#the-iphone-duo-motion-effect) •
[Performance Benchmark](#hardware-performance--benchmark-showcase) •
[Key Capabilities](#key-capabilities) •
[Quick Start](#quick-start) •
[Fold Geometries](#fold-geometries) •
[Spring Dynamics](#spring-physics-engine) •
[Architecture](#architecture)

<br/>

</div>

---

## The iPhone Duo Motion Effect

The **iPhone Duo Motion Effect** transforms flat, static user interface cards into living, tactile glass leaves that exist in physical 3D space. When the device is tilted or swiped, the interface lifts, bends, and catches the light like physical frosted crystal:

```
                  ┌────────────────────────────────────────┐
                  │   Physical Device Attitude (Gyroscope) │
                  └───────────────────┬────────────────────┘
                                      │  60Hz–120Hz Sensor Stream
                                      ▼
           ┌──────────────────────────────────────────────────────┐
           │            Impeller GPU Fragment Pipeline            │
           │                                                      │
           │  • 3D Ray-Traced Observer Perspective Foreshortening │
           │  • Progressive Non-Linear Defocus Blur (Depth-of-Field)
           │  • Dynamic Specular Surface Sheen Sweep              │
           │  • Subpixel Anti-Aliased Trapezoid Edge Masking      │
           └──────────────────────────┬───────────────────────────┘
                                      │
                                      ▼
                  ┌────────────────────────────────────────┐
                  │    Holographic 3D Frosted Glass Tilt   │
                  └────────────────────────────────────────┘
```

### Optical Principles

1. **Observer Perspective Projection**  
   Rather than simple 2.5D skewing, DuoMotion solves true 3D pinhole camera optics with an eye distance of $2.4 \times \text{aspect}$. As the leaf rotates up to **88.5°**, physical perspective compression foreshortens the receding plane naturally.

2. **Progressive Depth-of-Field Defocus Blur**  
   Real glass edges blur as they lift away from the focal screen plane. DuoMotion computes an adaptive Gaussian kernel along the tilt gradient—sharply focused at the hinge and softly diffused at the floating tip.

3. **Dynamic Specular Sheen Sweep**  
   Simulates an environmental light source grazing the frosted surface. As device tilt changes, a specular highlight sweeps across the glass face, accentuating the 3D angle of elevation.

4. **Zero-Latency Touch & Gyroscope Fusion (`InputMixer`)**  
   Seamlessly captures position during handoffs between physical device motion and manual finger drags, eliminating visual snapping or phase discrepancies.

---

## Hardware Performance & Benchmark Showcase

Engineered for 60Hz–120Hz high-refresh mobile displays. All metrics below were measured directly on **physical mid-range Android hardware** via ADB telemetry and Android platform profilers:

- **Target Device:** Samsung Galaxy A33 5G (`SM-A336E`)
- **Processor:** Samsung Exynos 1280 (8 cores: 2x Cortex-A78 @ 2.4GHz + 6x Cortex-A55 @ 2.0GHz)
- **GPU Backend:** ARM Mali-G68 MP4 running **Flutter Impeller (Vulkan)**
- **Display:** 1080 × 2400 FHD+ Super AMOLED @ **90.0 Hz (11.11 ms VSync budget)**

### Physical Device Scorecard

| Metric | Target Budget | Static UI | **DUOMOTION** |
|---|---|---:|---:|
| **Framerate (FPS)** | $\ge 60.0$ FPS (up to 90 Hz) | 0.0 FPS _(idle)_ | **90.0 FPS** |
| **Total Frame Time** | $\le 11.11$ ms _(90 Hz)_ | 0.0 ms | **9.55 ms** |
| **GPU Raster Duration** | $\le 8.00$ ms | 0.0 ms | **5.41 ms** |
| **Dart UI Thread Time** | $\le 4.00$ ms | 0.0 ms | **2.21 ms** |
| **P90 Frame Time** | $\le 11.11$ ms _(VSync)_ | 0.0 ms | **9.71 ms** |
| **Jank Percentage** | $< 5.0\%$ | 0.0% | **3.2%** |
| **GPU Texture Fetches** | $\le 10$M / frame | 0 | **~5.7M / frame** |
| **CPU Usage (8 Cores)** | $< 50.0\%$ | 1.2% | **~38.4%** |
| **Battery Power Draw** | $\le 2.50$ W | 1.55 W | **2.25 W** |
| **Continuous Battery** | $\ge 8.0$ hours | 12.8 hrs | **8.9 hrs** |
| **Release APK Overhead** | $\le 100$ KB | — | **+29.89 KB** |

### How 90 FPS Was Achieved on Mid-Range Hardware

1. **Unrolled 5-Tap Poisson Blur Kernel (`duo_motion_single.frag`)**  
   Replaced dynamic sampling loops and runtime trigonometric functions (`sin`, `cos`, `sqrt`, `fract`) with precomputed immediate Poisson offsets and center weighting. Slashes per-fragment ALU complexity by over 75%.
2. **In-Focus Subpixel Fast Path**  
   Pixels near the stationary hinge anchor (`radius < 1.5`) are physically in sharp focus and execute a single texture sample, cutting texture fetches from **82.9M down to ~5.7M per frame**.
3. **Smart Subtree Repaint Boundaries**  
   Isolates static child widgets into cached GPU layers (`RepaintBoundary`). Impeller avoids re-recording complex drop shadows, app icons, and vectors every frame before the fragment shader executes.
4. **Hardware VSync Alignment**  
   Binds directly to Flutter's hardware `Ticker` from `TickerProviderStateMixin`, completely eliminating timer drift and dropped frame spikes.

---

## Key Capabilities

| Feature                       | Description                                                                                                |
| :---------------------------- | :--------------------------------------------------------------------------------------------------------- |
| **iPhone Duo Motion**         | Real-time 60Hz–120Hz device attitude streaming via native iOS `CoreMotion` and Android `SensorManager`.    |
| **Impeller Shaders**          | Hardware-accelerated GLSL fragment shaders tailored for Flutter's next-gen Impeller graphics engine.       |
| **90.0 FPS Verified**         | Benchmarked and proven at locked 90 FPS on physical mid-range hardware with only 5.4ms GPU raster time.    |
| **Analytical ODE Physics**    | Closed-form second-order harmonic oscillator simulation (`SpringSimulation`) with zero numerical drift.    |
| **3 Fold Geometries**         | Single-hinge edge folds, dual-leaf book folds, and multi-segment accordion paper folds.                    |
| **Zero-Allocation Fast Path** | Automatically bypasses shader execution when at rest (`tilt < 0.05°`) or disabled for peak UI performance. |
| **Tactile Haptic Feedback**   | Contextual physical tick impulses triggered across drag thresholds, snap boundaries, and rest transitions. |
| **Headless Architecture**     | Modular 5-layer design with zero opinionated UI styling—wrap any widget tree effortlessly.                 |

---

## Installation

Add `duo_motion` to your `pubspec.yaml`:

```yaml
dependencies:
  duo_motion: ^1.0.0
```

Or install directly via CLI:

```bash
flutter pub add duo_motion
```

---

## Quick Start

### 1. iPhone Duo Motion (`DuoFoldMotion`)

Drive widget perspective and optical folding directly from physical device movement:

```dart
import 'package:duo_motion/duo_motion.dart';
import 'package:flutter/material.dart';

class DuoTiltShowcase extends StatefulWidget {
  const DuoTiltShowcase({super.key});

  @override
  State<DuoTiltShowcase> createState() => _DuoTiltShowcaseState();
}

class _DuoTiltShowcaseState extends State<DuoTiltShowcase> {
  late final FoldController _controller;

  @override
  void initState() {
    super.initState();
    // Initialize controller and engage hardware motion sensors
    _controller = FoldController(
      constraints: const HorizontalFoldConstraints(maxTiltDegrees: 45.0),
    );
    _controller.useSensor = true;
    _controller.start();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DuoFoldMotion(
      controller: _controller,
      child: const PremiumGlassCard(),
    );
  }
}
```

---

### 2. Interactive Touch Drag (`DuoFoldInteractive`)

Give any widget tactile finger-folding with automatic spring-back and inertia:

```dart
DuoFoldInteractive(
  mode: const SingleHingeFold(),
  maxTiltDegrees: 55.0,
  physics: SpringConfig.snappy,
  child: const PremiumGlassCard(),
)
```

---

### 3. Declarative Animation (`DuoFoldAnimated`)

Animate fold angles smoothly between states:

```dart
DuoFoldAnimated(
  state: isFolded
      ? const FoldState(tiltDegrees: 35.0, liftDirX: -1.0, liftDirY: 0.0)
      : FoldState.zero,
  duration: const Duration(milliseconds: 650),
  curve: Curves.easeOutCubic,
  child: const PremiumGlassCard(),
)
```

---

## Fold Geometries

DuoMotion supports three distinct mathematical fold topologies:

```
  SingleHingeFold             BookFold               AccordionFold
 ┌───────────────┐        ┌───────┬───────┐        ┌───┬───┬───┬───┐
 │               │        │       │       │        │ / │ \ │ / │ \ │
 │◄── Hinge      │        │       │ Spine │        │/  │  \│/  │  \│
 └───────────────┘        └───────┴───────┘        └───┴───┴───┴───┘
```

```dart
// Single Hinge: folds from left, right, top, or bottom edge
const fold = SingleHingeFold();

// Book Fold: dual-leaf open/close fold with customizable central spine
const fold = BookFold(hingePosition: 0.5);

// Accordion Fold: multi-panel zig-zag folding
const fold = AccordionFold(foldCount: 4);
```

---

## Spring Physics Engine

DuoMotion includes a clean analytical solver for the classical damped harmonic oscillator equation:

$$m \frac{d^2 x}{dt^2} + c \frac{dx}{dt} + k x = 0$$

Unlike simple Euler integration, our closed-form solution guarantees exact mathematical convergence with zero frame-rate dependency:

```dart
SpringConfig.snappy   // Crisp, instantaneous return with micro-settle
SpringConfig.bouncy   // Energetic harmonic overshoot
SpringConfig.gentle   // Velvety, smooth deceleration
SpringConfig.stiff    // High-tension industrial snap
```

---

## Architecture

DuoMotion follows a strict 5-layer decoupled architecture:

```
┌──────────────────────────────────────────────────────────────┐
│ Layer 5: Widgets & Theming (DuoFold, DuoFoldTheme)           │
├──────────────────────────────────────────────────────────────┤
│ Layer 4: Controllers & Orchestration (FoldController)        │
├──────────────────────────────────────────────────────────────┤
│ Layer 3: Shader Engine (Impeller Shaders, UniformPacker)     │
├──────────────────────────────────────────────────────────────┤
│ Layer 2: Input & Motion (GestureInterpreter, InputMixer)     │
├──────────────────────────────────────────────────────────────┤
│ Layer 1: Core & Physics (SpringSimulation, Matrix3, Optics)  │
└──────────────────────────────────────────────────────────────┘
```

---

## Verification & Testing

Every release is verified against a comprehensive 275-test battery covering analytical ODE convergence, uniform buffer packing, gesture projections, and shader lifecycles:

```bash
flutter test
```

---

## License

Distributed under the **Apache License 2.0**. See [`LICENSE`](LICENSE) for details.
