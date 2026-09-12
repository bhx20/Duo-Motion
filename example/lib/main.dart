import 'dart:math' as math;

import 'package:duo_motion/duo_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    ),
  );
  runApp(const SoloTiltShowcaseApp());
}

/// Color theme preset for the SoloTilt showcase.
class SoloTheme {
  const SoloTheme({
    required this.name,
    required this.backgroundColor,
    required this.cardColor,
    required this.textColor,
    required this.subtextColor,
    required this.accentColor,
    required this.hazeColor,
    required this.isDark,
  });

  final String name;
  final Color backgroundColor;
  final Color cardColor;
  final Color textColor;
  final Color subtextColor;
  final Color accentColor;
  final Color hazeColor;
  final bool isDark;

  static const white = SoloTheme(
    name: 'Pure White',
    backgroundColor: Color(0xFFF2F4F7),
    cardColor: Colors.white,
    textColor: Color(0xFF111827),
    subtextColor: Color(0xFF6B7280),
    accentColor: Color(0xFF007AFF),
    hazeColor: Colors.white,
    isDark: false,
  );

  static const midnight = SoloTheme(
    name: 'Midnight Dark',
    backgroundColor: Color(0xFF07090E),
    cardColor: Color(0xFF131722),
    textColor: Color(0xFFF9FAFB),
    subtextColor: Color(0xFF9CA3AF),
    accentColor: Color(0xFF0A84FF),
    hazeColor: Color(0xFF1E2538),
    isDark: true,
  );

  static const ocean = SoloTheme(
    name: 'Ocean Blue',
    backgroundColor: Color(0xFFEBF3FB),
    cardColor: Colors.white,
    textColor: Color(0xFF0F2B48),
    subtextColor: Color(0xFF537699),
    accentColor: Color(0xFF007AFF),
    hazeColor: Color(0xFFD6E8FA),
    isDark: false,
  );

  static const purple = SoloTheme(
    name: 'Neon Purple',
    backgroundColor: Color(0xFF140D26),
    cardColor: Color(0xFF22173D),
    textColor: Color(0xFFF5EEFD),
    subtextColor: Color(0xFFA894CC),
    accentColor: Color(0xFFBF5AF2),
    hazeColor: Color(0xFF35205C),
    isDark: true,
  );

  static const emerald = SoloTheme(
    name: 'Emerald Mint',
    backgroundColor: Color(0xFFEBF6F0),
    cardColor: Colors.white,
    textColor: Color(0xFF0D3320),
    subtextColor: Color(0xFF4E7A62),
    accentColor: Color(0xFF34C759),
    hazeColor: Color(0xFFD4EEDF),
    isDark: false,
  );

  static const all = [white, midnight, ocean, purple, emerald];
}

/// Authentic Apple iPhone Duo / SoloTilt Showcase Application.
///
/// Implements the viral 3D perspective fold illusion from solotilt.com:
/// - Real-time perspective projection where the screen turns on a fixed hinge.
/// - Clean full-bleed edge rendering with zero black lines or artifacts.
/// - Progressive optical depth-of-field defocus blur increasing away from the hinge.
/// - Specular glass light reflection sweep across the surface.
/// - Real-time hardware gyroscope motion & bi-directional touch exploration (-85° to +85°).
/// - Instant "Calibrate Stand" button to zero out mobile stand tilt angles.
/// - Multi-theme color palette switcher (Pure White, Midnight Dark, Ocean Blue, Neon Purple, Emerald).
class SoloTiltShowcaseApp extends StatelessWidget {
  const SoloTiltShowcaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Solo Tilt — iPhone Duo Illusion',
      debugShowCheckedModeBanner: false,
      home: SoloTiltHomeScreen(),
    );
  }
}

/// Operation mode for the iPhone Duo showcase.
enum ShowcaseMode {
  /// Interactive touch dragging with analytical second-order spring release.
  touch,

  /// Continuous harmonic sway animation reproducing the viral iPhone Duo video.
  autoDemo,

  /// Hardware gyroscope attitude tracking with drift washout.
  gyro,
}

class SoloTiltHomeScreen extends StatefulWidget {
  const SoloTiltHomeScreen({super.key});

  @override
  State<SoloTiltHomeScreen> createState() => _SoloTiltHomeScreenState();
}

class _SoloTiltHomeScreenState extends State<SoloTiltHomeScreen> with TickerProviderStateMixin {
  late final FoldController _controller;
  late final AnimationController _demoController;

  Ticker? _springTicker;
  SpringSimulation? _springSim;
  final Stopwatch _springStopwatch = Stopwatch();

  final FoldMode _mode = const SingleHingeFold();

  // Active theme color (defaults to Apple Pure White)
  SoloTheme _activeTheme = SoloTheme.white;

  // Active operation mode (defaults to Touch exploration with auto-spring back)
  ShowcaseMode _currentMode = ShowcaseMode.touch;
  bool _isPlayingMusic = false;

  // Signed exploration angle: negative = hinged on right, positive = hinged on left
  double _signedExploreAngle = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = FoldController(
      constraints: const HorizontalFoldConstraints(maxTiltDegrees: 85),
    );
    _controller.start();
    _controller.effects = const FoldEffects(
      shadowIntensity: 0.20,
      shadowSoftness: 0.40,
      causticIntensity: 0.35,
    );

    // Continuous harmonic sway animation controller for Auto-Demo mode
    _demoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..addListener(_onDemoTick);
  }

  @override
  void dispose() {
    _springTicker?.dispose();
    _demoController.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Builds optical parameters matching the authentic SoloTilt / iPhone Duo specifications.
  FoldParameters _buildParameters() {
    return FoldParameters(
      surroundColor: Colors.black,
      hazeColor: Colors.white,
      blurSpread: 0.16,
      darkening: _activeTheme.isDark ? 0.005 : 0.002,
      baseBlurMillimeters: 0.10,
      eyeDistanceMillimeters: 450,
      stretchEdges: false,
    );
  }

  /// Sets the bi-directional tilt angle (-85° to +85°).
  void _setSignedAngle(double angle) {
    setState(() {
      _signedExploreAngle = angle;
      if (_currentMode != ShowcaseMode.gyro) {
        _controller.useSensor = false;
      }

      final isLeftHinge = angle >= 0;
      final magnitude = angle.abs().clamp(0.0, 85.0);

      _controller.setManualState(
        FoldState(
          tiltDegrees: magnitude,
          liftDirX: isLeftHinge ? 1.0 : -1.0,
          liftDirY: 0.0,
        ),
      );
    });
  }

  /// Stops any running spring simulation.
  void _stopSpring() {
    _springTicker?.stop();
    _springStopwatch.stop();
    _springSim = null;
  }

  /// Launches analytical second-order spring physics simulation returning the fold to 0° flat.
  void _startSpringBack({double velocity = 0.0}) {
    _stopSpring();
    if (_currentMode == ShowcaseMode.autoDemo) return;

    final initialVelocity = velocity.clamp(-450.0, 450.0);
    _springSim = SpringSimulation(
      config: SpringConfig.snappy,
      startPosition: _signedExploreAngle,
      targetPosition: 0.0,
      startVelocity: initialVelocity,
    );
    _springStopwatch.reset();
    _springStopwatch.start();
    _springTicker ??= createTicker(_onSpringTick);
    _springTicker!.start();
  }

  void _onSpringTick(Duration elapsed) {
    if (_springSim == null) return;
    final t = _springStopwatch.elapsedMicroseconds / 1000000.0;
    final angle = _springSim!.position(t);
    _setSignedAngle(angle);

    if (_springSim!.isDone(t)) {
      _stopSpring();
      _setSignedAngle(0.0);
    }
  }

  /// Harmonic sway tick for Auto-Demo mode.
  void _onDemoTick() {
    if (_currentMode != ShowcaseMode.autoDemo) return;
    // Harmonic sinusoidal sway between -75° and +75°
    final t = _demoController.value * 2.0 * math.pi;
    final angle = math.sin(t) * 75.0;
    _setSignedAngle(angle);
  }

  /// Switches active showcase mode.
  void _switchMode(ShowcaseMode mode) {
    if (_currentMode == mode) return;
    setState(() {
      _currentMode = mode;
      _stopSpring();

      if (mode == ShowcaseMode.autoDemo) {
        _controller.useSensor = false;
        _demoController.repeat();
      } else if (mode == ShowcaseMode.touch) {
        _demoController.stop();
        _controller.useSensor = false;
        _startSpringBack(velocity: 0.0);
      } else if (mode == ShowcaseMode.gyro) {
        _demoController.stop();
        _signedExploreAngle = 0.0;
        _controller.useSensor = true;
        _controller.recalibrate();
        _controller.start();
      }
    });
  }

  /// Cycles to next color theme.
  void _cycleTheme() {
    final idx = SoloTheme.all.indexOf(_activeTheme);
    final next = SoloTheme.all[(idx + 1) % SoloTheme.all.length];
    setState(() => _activeTheme = next);
  }

  @override
  Widget build(BuildContext context) {
    final params = _buildParameters();
    const backdrop = Colors.black;

    return Scaffold(
      backgroundColor: backdrop,
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLandscape = constraints.maxWidth > constraints.maxHeight;

          return Stack(
            children: [
              // 3D Optical Fold Surface
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onDoubleTap: () {
                  if (_currentMode == ShowcaseMode.autoDemo) {
                    _switchMode(ShowcaseMode.touch);
                  }
                  _startSpringBack(velocity: 0.0);
                },
                onHorizontalDragStart: (_) {
                  if (_currentMode == ShowcaseMode.autoDemo) {
                    _switchMode(ShowcaseMode.touch);
                  }
                  _stopSpring();
                },
                onHorizontalDragUpdate: (details) {
                  _stopSpring();
                  final delta = details.primaryDelta ?? 0;
                  final newAngle = (_signedExploreAngle + delta * 0.45).clamp(-85.0, 85.0);
                  _setSignedAngle(newAngle);
                },
                onHorizontalDragEnd: (details) {
                  final vx = details.primaryVelocity ?? details.velocity.pixelsPerSecond.dx;
                  _startSpringBack(velocity: vx * 0.35);
                },
                child: _currentMode == ShowcaseMode.gyro
                    ? DuoFoldMotion(
                        controller: _controller,
                        mode: _mode,
                        parameters: params,
                        surroundColor: backdrop,
                        effects: _controller.effects,
                        child: _buildIosHomeScreenContent(isLandscape: isLandscape),
                      )
                    : DuoFold(
                        state: _controller.state,
                        mode: _mode,
                        parameters: params,
                        surroundColor: backdrop,
                        effects: _controller.effects,
                        child: _buildIosHomeScreenContent(isLandscape: isLandscape),
                      ),
              ),

              // Floating Precision Angle & Mode HUD (responsive layout)
              Positioned(
                left: isLandscape ? 36 : 20,
                right: isLandscape ? 36 : 20,
                bottom: isLandscape ? 10 : 24,
                child: _buildFloatingControlsHud(isLandscape: isLandscape),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Elegant Apple-style floating controls HUD for mode switching and angle scrub.
  Widget _buildFloatingControlsHud({required bool isLandscape}) {
    final isDark = _activeTheme.isDark;
    final hudBackground = isDark ? const Color(0xE6131722) : const Color(0xE6FFFFFF);
    final hudBorder = isDark ? Colors.white12 : Colors.black12;
    final hudText = isDark ? Colors.white : Colors.black87;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: isLandscape ? 5 : 8),
      decoration: BoxDecoration(
        color: hudBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: hudBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: isLandscape
          ? Row(
              children: [
                _buildModePill(
                  title: 'Touch',
                  icon: Icons.touch_app_rounded,
                  selected: _currentMode == ShowcaseMode.touch,
                  onTap: () => _switchMode(ShowcaseMode.touch),
                ),
                const SizedBox(width: 5),
                _buildModePill(
                  title: 'Auto Sway',
                  icon: Icons.auto_awesome_rounded,
                  selected: _currentMode == ShowcaseMode.autoDemo,
                  onTap: () => _switchMode(ShowcaseMode.autoDemo),
                ),
                const SizedBox(width: 5),
                _buildModePill(
                  title: 'Gyro',
                  icon: Icons.screen_rotation_rounded,
                  selected: _currentMode == ShowcaseMode.gyro,
                  onTap: () => _switchMode(ShowcaseMode.gyro),
                ),
                const SizedBox(width: 10),
                if (_currentMode != ShowcaseMode.gyro) ...[
                  Text(
                    'Left',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: hudText.withValues(alpha: 0.5)),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: _activeTheme.accentColor,
                        inactiveTrackColor: hudText.withValues(alpha: 0.15),
                        thumbColor: _activeTheme.accentColor,
                        overlayColor: _activeTheme.accentColor.withValues(alpha: 0.15),
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      ),
                      child: Slider(
                        value: _signedExploreAngle.clamp(-85.0, 85.0),
                        min: -85.0,
                        max: 85.0,
                        onChanged: (val) {
                          if (_currentMode == ShowcaseMode.autoDemo) {
                            _switchMode(ShowcaseMode.touch);
                          }
                          _stopSpring();
                          _setSignedAngle(val);
                        },
                        onChangeEnd: (_) => _startSpringBack(velocity: 0.0),
                      ),
                    ),
                  ),
                  Text(
                    'Right',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: hudText.withValues(alpha: 0.5)),
                  ),
                  const SizedBox(width: 10),
                ] else
                  const Spacer(),
                _buildAngleIndicator(),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    _buildModePill(
                      title: 'Touch',
                      icon: Icons.touch_app_rounded,
                      selected: _currentMode == ShowcaseMode.touch,
                      onTap: () => _switchMode(ShowcaseMode.touch),
                    ),
                    const SizedBox(width: 6),
                    _buildModePill(
                      title: 'Auto Sway',
                      icon: Icons.auto_awesome_rounded,
                      selected: _currentMode == ShowcaseMode.autoDemo,
                      onTap: () => _switchMode(ShowcaseMode.autoDemo),
                    ),
                    const SizedBox(width: 6),
                    _buildModePill(
                      title: 'Gyro',
                      icon: Icons.screen_rotation_rounded,
                      selected: _currentMode == ShowcaseMode.gyro,
                      onTap: () => _switchMode(ShowcaseMode.gyro),
                    ),
                    const Spacer(),
                    _buildAngleIndicator(),
                  ],
                ),
                if (_currentMode != ShowcaseMode.gyro) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        'Left',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: hudText.withValues(alpha: 0.5)),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: _activeTheme.accentColor,
                            inactiveTrackColor: hudText.withValues(alpha: 0.15),
                            thumbColor: _activeTheme.accentColor,
                            overlayColor: _activeTheme.accentColor.withValues(alpha: 0.15),
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          ),
                          child: Slider(
                            value: _signedExploreAngle.clamp(-85.0, 85.0),
                            min: -85.0,
                            max: 85.0,
                            onChanged: (val) {
                              if (_currentMode == ShowcaseMode.autoDemo) {
                                _switchMode(ShowcaseMode.touch);
                              }
                              _stopSpring();
                              _setSignedAngle(val);
                            },
                            onChangeEnd: (_) => _startSpringBack(velocity: 0.0),
                          ),
                        ),
                      ),
                      Text(
                        'Right',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: hudText.withValues(alpha: 0.5)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildAngleIndicator() {
    return InkWell(
      onTap: () => _startSpringBack(velocity: 0.0),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _activeTheme.accentColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _activeTheme.accentColor.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _currentMode == ShowcaseMode.gyro
                  ? '${_controller.state.tiltDegrees.toStringAsFixed(0)}°'
                  : '${_signedExploreAngle >= 0 ? '+' : ''}${_signedExploreAngle.toStringAsFixed(0)}°',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _activeTheme.accentColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.replay_rounded, size: 13, color: _activeTheme.accentColor),
          ],
        ),
      ),
    );
  }

  Widget _buildModePill({
    required String title,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final accent = _activeTheme.accentColor;
    final isDark = _activeTheme.isDark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? accent : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: selected ? Colors.white : _activeTheme.subtextColor),
            const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected ? Colors.white : _activeTheme.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Authentic Apple iOS Light Home Screen with widgets, app grid, and frosted dock.
  Widget _buildIosHomeScreenContent({required bool isLandscape}) {
    final t = _activeTheme;

    if (isLandscape) {
      return _buildLandscapeHomeScreen(t);
    }
    return _buildPortraitHomeScreen(t);
  }

  Widget _buildLandscapeHomeScreen(SoloTheme t) {
    return Container(
      decoration: BoxDecoration(
        color: t.backgroundColor,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            t.backgroundColor,
            Color.lerp(t.backgroundColor, t.cardColor, t.isDark ? 0.08 : 0.4)!,
            t.backgroundColor,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 52),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Column: Brand bar + 2 Widgets
              SizedBox(
                width: 280,
                child: Column(
                  children: [
                    _buildBrandBar(t),
                    const SizedBox(height: 10),
                    Expanded(
                      child: _buildIosWidgetCard(
                        padding: const EdgeInsets.all(12),
                        child: _buildMusicContent(t),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: _buildIosWidgetCard(
                        padding: const EdgeInsets.all(12),
                        child: _buildAudienceContent(t),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Right Column: 2 rows of 6 Apps + Dock
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildAppIcon(name: 'Photos', icon: Icons.photo_library_rounded, color: const Color(0xFFFF9500), size: 44),
                              _buildAppIcon(name: 'Camera', icon: Icons.camera_alt_rounded, color: const Color(0xFF8E8E93), size: 44),
                              _buildAppIcon(name: 'Safari', icon: Icons.explore_rounded, color: const Color(0xFF007AFF), size: 44),
                              _buildAppIcon(name: 'Files', icon: Icons.folder_rounded, color: const Color(0xFF007AFF), size: 44),
                              _buildAppIcon(name: 'Messages', icon: Icons.chat_bubble_rounded, color: const Color(0xFF34C759), size: 44),
                              _buildAppIcon(name: 'Maps', icon: Icons.map_rounded, color: const Color(0xFF30B0C7), size: 44),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildAppIcon(name: 'Calendar', icon: Icons.calendar_month_rounded, color: const Color(0xFFFF3B30), size: 44),
                              _buildAppIcon(name: 'Weather', icon: Icons.cloud_rounded, color: const Color(0xFF32ADE6), size: 44),
                              _buildAppIcon(name: 'Clock', icon: Icons.access_time_filled_rounded, color: const Color(0xFF1C1C1E), size: 44),
                              _buildAppIcon(name: 'Notes', icon: Icons.sticky_note_2_rounded, color: const Color(0xFFFFCC00), size: 44),
                              _buildAppIcon(name: 'Health', icon: Icons.favorite_rounded, color: const Color(0xFFFF2D55), size: 44),
                              _buildAppIcon(name: 'App Store', icon: Icons.shopping_bag_rounded, color: const Color(0xFF007AFF), size: 44),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDock(t, compact: true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPortraitHomeScreen(SoloTheme t) {
    return Container(
      decoration: BoxDecoration(
        color: t.backgroundColor,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            t.backgroundColor,
            Color.lerp(t.backgroundColor, t.cardColor, t.isDark ? 0.08 : 0.4)!,
            t.backgroundColor,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 14),
            _buildBrandBar(t),
            const SizedBox(height: 16),

            // Interactive Widgets Row: Live Music Player + Live Audience
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildIosWidgetCard(
                      height: 140,
                      child: _buildMusicContent(t),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildIosWidgetCard(
                      height: 140,
                      child: _buildAudienceContent(t),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // iOS App Grid (3 rows x 4 columns)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildAppIcon(name: 'Photos', icon: Icons.photo_library_rounded, color: const Color(0xFFFF9500)),
                        _buildAppIcon(name: 'Camera', icon: Icons.camera_alt_rounded, color: const Color(0xFF8E8E93)),
                        _buildAppIcon(name: 'Safari', icon: Icons.explore_rounded, color: const Color(0xFF007AFF)),
                        _buildAppIcon(name: 'Files', icon: Icons.folder_rounded, color: const Color(0xFF007AFF)),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildAppIcon(name: 'Messages', icon: Icons.chat_bubble_rounded, color: const Color(0xFF34C759)),
                        _buildAppIcon(name: 'Maps', icon: Icons.map_rounded, color: const Color(0xFF30B0C7)),
                        _buildAppIcon(name: 'Calendar', icon: Icons.calendar_month_rounded, color: const Color(0xFFFF3B30)),
                        _buildAppIcon(name: 'Weather', icon: Icons.cloud_rounded, color: const Color(0xFF32ADE6)),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildAppIcon(name: 'Clock', icon: Icons.access_time_filled_rounded, color: const Color(0xFF1C1C1E)),
                        _buildAppIcon(name: 'Notes', icon: Icons.sticky_note_2_rounded, color: const Color(0xFFFFCC00)),
                        _buildAppIcon(name: 'Health', icon: Icons.favorite_rounded, color: const Color(0xFFFF2D55)),
                        _buildAppIcon(name: 'App Store', icon: Icons.shopping_bag_rounded, color: const Color(0xFF007AFF)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Spotlight Search Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: t.cardColor.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: t.textColor.withValues(alpha: 0.06)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_rounded, size: 13, color: t.subtextColor),
                  const SizedBox(width: 5),
                  Text(
                    'Search',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: t.subtextColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Bottom Frosted Glass Dock
            _buildDock(t, compact: false),
            const SizedBox(height: 60), // Margin for bottom floating HUD
          ],
        ),
      ),
    );
  }

  Widget _buildBrandBar(SoloTheme t) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: t.accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Solo Tilt · iPhone Duo',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: t.textColor,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          InkWell(
            onTap: _cycleTheme,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: t.textColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.palette_outlined, size: 11, color: t.subtextColor),
                  const SizedBox(width: 4),
                  Text(
                    t.name,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: t.subtextColor),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMusicContent(SoloTheme t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFFA2D55).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.music_note_rounded, color: Color(0xFFFA2D55), size: 14),
            ),
            const SizedBox(width: 6),
            const Text(
              'NOW PLAYING',
              style: TextStyle(color: Color(0xFFFA2D55), fontSize: 10, fontWeight: FontWeight.w800),
            ),
            const Spacer(),
            InkWell(
              onTap: () => setState(() => _isPlayingMusic = !_isPlayingMusic),
              child: Icon(
                _isPlayingMusic ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                color: const Color(0xFFFA2D55),
                size: 22,
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '热河',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: t.textColor),
            ),
            Text(
              '李志 · Solo Tilt Radio',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: t.subtextColor),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: _isPlayingMusic ? 0.65 : 0.25,
              backgroundColor: t.textColor.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFA2D55)),
              borderRadius: BorderRadius.circular(4),
              minHeight: 3,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAudienceContent(SoloTheme t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Color(0xFF34C759),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'LIVE PLAYERS',
              style: TextStyle(color: Color(0xFF34C759), fontSize: 10, fontWeight: FontWeight.w800),
            ),
            const Spacer(),
            const Text('👍', style: TextStyle(fontSize: 14)),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '1,842',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: t.textColor, height: 1.0),
            ),
            Text(
              'people playing now',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: t.subtextColor),
            ),
            const SizedBox(height: 6),
            Row(
              children: List.generate(
                12,
                (i) => Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    height: (math.sin(i * 0.7) * 5 + 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF34C759).withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDock(SoloTheme t, {required bool compact}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8.0 : 20.0),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: compact ? 6 : 10, horizontal: compact ? 12 : 16),
        decoration: BoxDecoration(
          color: t.cardColor.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(compact ? 20 : 30),
          border: Border.all(color: t.textColor.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildDockIcon(icon: Icons.phone_rounded, color: const Color(0xFF34C759), compact: compact),
            _buildDockIcon(icon: Icons.mail_rounded, color: const Color(0xFF007AFF), compact: compact),
            _buildDockIcon(icon: Icons.explore_rounded, color: const Color(0xFF007AFF), compact: compact),
            _buildDockIcon(icon: Icons.music_note_rounded, color: const Color(0xFFFA2D55), compact: compact),
          ],
        ),
      ),
    );
  }

  Widget _buildIosWidgetCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
    double? height,
  }) {
    final t = _activeTheme;

    return Container(
      height: height,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: t.textColor.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: t.isDark ? 0.25 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildAppIcon({
    required String name,
    required IconData icon,
    required Color color,
    double size = 56,
    bool compact = false,
  }) {
    final iconBoxSize = size;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: iconBoxSize,
          height: iconBoxSize,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(iconBoxSize * 0.27),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.28),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: iconBoxSize * 0.5),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          style: TextStyle(
            fontSize: compact ? 9.5 : 11,
            fontWeight: FontWeight.w600,
            color: _activeTheme.textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildDockIcon({
    required IconData icon,
    required Color color,
    bool compact = false,
  }) {
    final size = compact ? 38.0 : 50.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(compact ? 10 : 14),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: compact ? 20 : 24),
    );
  }
}
