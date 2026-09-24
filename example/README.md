# DuoMotion Showcase & Benchmark Example

<p align="center">
  <img src="https://raw.githubusercontent.com/bhx20/duo_motion/main/assets/showcase.webp" alt="DuoMotion Showcase Demo" width="340" />
</p>

This showcase demonstrates the viral **iPhone Duo / SoloTilt** frosted-glass 3D perspective fold effect using `duo_motion`, optimized to achieve **90.0 FPS locked** on physical mid-range mobile hardware.

---

## Features Demonstrated

- **Real-Time Gyroscope Tilt**: Live device attitude tracking using hardware sensors (`FoldController.useSensor = true`). Double-tap anywhere to recalibrate.
- **3D Pinhole Ray-Traced Optics**: Observer perspective foreshortening with progressive depth-of-field blur on Impeller shaders.
- **Built-In Live Benchmark Modes**: Tap the bottom **Spotlight Search Pill** to cycle between three live benchmark modes:
  - `MODE 0`: **Baseline** (Static UI, fold shader disabled, music paused).
  - `MODE 1`: **Standard Widget Animation** (Live music equalizer and rotating vinyl active).
  - `MODE 2`: **Full DuoMotion** (Hardware-accelerated 3D perspective fold + tilt oscillation + live music).
- **Glassmorphic Interactive UI**: Frosted glass cards, live dynamic audio equalizer, rotating vinyl disc, and authentic iOS dock.
- **Bi-Directional Gesture Control**: Touch dragging with snappy second-order physics return.
- **Multi-Theme Support**: Obsidian Midnight Dark, Pure White, Ocean Blue, Neon Purple, and Emerald Mint.

---

## Measured Hardware Performance (Samsung Galaxy A33 5G)

Tested live on physical hardware (`SM-A336E`, Exynos 1280, Mali-G68 GPU, 90.0 Hz AMOLED):

| Metric | Measured Value | Standard / Budget |
|---|---:|---:|
| **Framerate** | **90.0 FPS** | $\ge 60.0$ FPS |
| **Total Frame Time** | **9.55 ms** | $\le 11.11$ ms |
| **GPU Raster Time** | **5.41 ms** | $\le 8.00$ ms |
| **Dart UI Thread Time** | **2.21 ms** | $\le 4.00$ ms |
| **P90 Frame Time** | **9.71 ms** | $\le 11.11$ ms |
| **Jank Percentage** | **3.2%** | $< 5.0\%$ |
| **Power Consumption** | **2.25 W** | $\le 2.50$ W |

---

## Running the Example

### Normal / Debug Mode
```bash
cd example
flutter pub get
flutter run
```

### High-Refresh Hardware Benchmark Mode
To measure real-world frame timings without debug VM overhead, run in **Profile** or **Release** mode on a physical device:

```bash
flutter run --profile
```

Frame metrics are printed to the system log every 2 seconds:
```bash
adb logcat -s flutter | grep "BENCH_DATA"
```
