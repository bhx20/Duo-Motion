import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:duo_motion/duo_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
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

  static const all = [midnight, white, ocean, purple, emerald];
}

/// Authentic Apple iPhone Duo / SoloTilt Showcase Application.
///
/// Implements the viral 3D perspective fold illusion from solotilt.com:
/// - Real-time perspective projection where the screen turns on a fixed hinge.
/// - Clean full-bleed edge rendering with zero black lines or artifacts.
/// - Progressive optical depth-of-field defocus blur increasing away from the hinge.
/// - Specular glass light reflection sweep across the surface.
/// - Real-time hardware gyroscope motion active by default.
/// - Pure Apple iPhone Midnight Dark glassmorphism interface.
/// - Live animated Now Playing music player with dynamic audio spectrum visualizer.
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

class SoloTiltHomeScreen extends StatefulWidget {
  const SoloTiltHomeScreen({super.key});

  @override
  State<SoloTiltHomeScreen> createState() => _SoloTiltHomeScreenState();
}

class _SoloTiltHomeScreenState extends State<SoloTiltHomeScreen>
    with SingleTickerProviderStateMixin {
  late final FoldController _controller;
  late final AnimationController _equalizerAnimController;

  final FoldMode _mode = const SingleHingeFold();

  // Active theme color (defaults to Apple iPhone Midnight Dark)
  final SoloTheme _activeTheme = SoloTheme.midnight;
  bool _isPlayingMusic = true;

  // Real-time wall-clock audio playback tracking for actual 4:03 (243s) duration
  static const int _totalSongSeconds = 243; // 4 minutes 3 seconds
  final Stopwatch _songStopwatch = Stopwatch();
  Duration _seekOffset = Duration.zero;

  @override
  void initState() {
    super.initState();
    _controller = FoldController(
      constraints: const HorizontalFoldConstraints(maxTiltDegrees: 85),
    );
    _controller.useSensor = true;
    _controller.recalibrate();
    _controller.start();
    _controller.effects = const FoldEffects(
      shadowIntensity: 0.35,
      shadowSoftness: 0.65,
      causticIntensity: 0.45,
      chromaticAberration: 0.02,
      lightAngle: 1.25,
    );

    // Smooth, relaxed audio visualizer equalizer and vinyl animation (slowed down)
    _equalizerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    )..repeat();

    // Start real-time audio playback clock
    _songStopwatch.start();
  }

  @override
  void dispose() {
    _songStopwatch.stop();
    _equalizerAnimController.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Calculates actual elapsed song time looping precisely across 4:03 (243 seconds).
  Duration get _currentSongElapsed {
    final totalMillis = _songStopwatch.elapsedMilliseconds + _seekOffset.inMilliseconds;
    const songTotalMillis = _totalSongSeconds * 1000;
    if (songTotalMillis == 0) return Duration.zero;
    final loopedMillis = (totalMillis % songTotalMillis + songTotalMillis) % songTotalMillis;
    return Duration(milliseconds: loopedMillis);
  }

  double get _currentSongProgress {
    final millis = _currentSongElapsed.inMilliseconds;
    return (millis / (_totalSongSeconds * 1000)).clamp(0.0, 1.0);
  }

  String get _currentSongElapsedText {
    final secs = _currentSongElapsed.inSeconds;
    final mins = secs ~/ 60;
    final remSecs = (secs % 60).toString().padLeft(2, '0');
    return '$mins:$remSecs';
  }

  void _seekBySeconds(int deltaSeconds) {
    setState(() {
      final currentMillis = _currentSongElapsed.inMilliseconds;
      const songTotalMillis = _totalSongSeconds * 1000;
      final targetMillis = (currentMillis + deltaSeconds * 1000).clamp(0, songTotalMillis);
      _seekOffset = Duration(milliseconds: targetMillis) - _songStopwatch.elapsed;
    });
    HapticFeedback.lightImpact();
  }

  void _seekToRatio(double ratio) {
    setState(() {
      final targetMillis = (ratio.clamp(0.0, 1.0) * _totalSongSeconds * 1000).toInt();
      _seekOffset = Duration(milliseconds: targetMillis) - _songStopwatch.elapsed;
    });
    HapticFeedback.selectionClick();
  }

  /// Builds optical parameters matching the authentic SoloTilt / iPhone Duo specifications.
  FoldParameters _buildParameters() {
    return FoldParameters(
      surroundColor: Colors.black,
      hazeColor: _activeTheme.hazeColor,
      blurSpread: 0.18,
      darkening: _activeTheme.isDark ? 0.006 : 0.002,
      baseBlurMillimeters: 0.12,
      eyeDistanceMillimeters: 420,
      stretchEdges: false,
    );
  }

  void _toggleMusic() {
    setState(() {
      _isPlayingMusic = !_isPlayingMusic;
      if (_isPlayingMusic) {
        _songStopwatch.start();
        _equalizerAnimController.repeat();
      } else {
        _songStopwatch.stop();
        _equalizerAnimController.stop();
      }
    });
    HapticFeedback.lightImpact();
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

          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onDoubleTap: () {
              _controller.recalibrate();
              HapticFeedback.lightImpact();
            },
            child: DuoFoldMotion(
              controller: _controller,
              mode: _mode,
              parameters: params,
              surroundColor: backdrop,
              effects: _controller.effects,
              child: _buildIosHomeScreenContent(isLandscape: isLandscape),
            ),
          );
        },
      ),
    );
  }

  /// Authentic Apple iOS Home Screen without top notches or titles.
  Widget _buildIosHomeScreenContent({required bool isLandscape}) {
    final t = _activeTheme;

    if (isLandscape) {
      return _buildLandscapeHomeScreen(t);
    }
    return _buildPortraitHomeScreen(t);
  }

  Widget _buildLandscapeHomeScreen(SoloTheme t) {
    return _buildGlassWallpaper(
      t,
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Column: 2 Frosted Widgets (Music Player + Live Audience)
              SizedBox(
                width: 300,
                child: Column(
                  children: [
                    Expanded(
                      child: _buildIosWidgetCard(
                        padding: const EdgeInsets.all(14),
                        child: _buildMusicContent(t),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _buildIosWidgetCard(
                        padding: const EdgeInsets.all(14),
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
                              _buildAppIcon(
                                name: 'Photos',
                                icon: Icons.photo_library_rounded,
                                color: const Color(0xFFFF9500),
                                size: 44,
                              ),
                              _buildAppIcon(
                                name: 'Camera',
                                icon: Icons.camera_alt_rounded,
                                color: const Color(0xFF8E8E93),
                                size: 44,
                              ),
                              _buildAppIcon(
                                name: 'Safari',
                                icon: Icons.explore_rounded,
                                color: const Color(0xFF007AFF),
                                size: 44,
                              ),
                              _buildAppIcon(
                                name: 'Files',
                                icon: Icons.folder_rounded,
                                color: const Color(0xFF007AFF),
                                size: 44,
                              ),
                              _buildAppIcon(
                                name: 'Messages',
                                icon: Icons.chat_bubble_rounded,
                                color: const Color(0xFF34C759),
                                size: 44,
                              ),
                              _buildAppIcon(
                                name: 'Maps',
                                icon: Icons.map_rounded,
                                color: const Color(0xFF30B0C7),
                                size: 44,
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildAppIcon(
                                name: 'Calendar',
                                icon: Icons.calendar_month_rounded,
                                color: const Color(0xFFFF3B30),
                                size: 44,
                              ),
                              _buildAppIcon(
                                name: 'Weather',
                                icon: Icons.cloud_rounded,
                                color: const Color(0xFF32ADE6),
                                size: 44,
                              ),
                              _buildAppIcon(
                                name: 'Clock',
                                icon: Icons.access_time_filled_rounded,
                                color: const Color(0xFF1C1C1E),
                                size: 44,
                              ),
                              _buildAppIcon(
                                name: 'Notes',
                                icon: Icons.sticky_note_2_rounded,
                                color: const Color(0xFFFFCC00),
                                size: 44,
                              ),
                              _buildAppIcon(
                                name: 'Health',
                                icon: Icons.favorite_rounded,
                                color: const Color(0xFFFF2D55),
                                size: 44,
                              ),
                              _buildAppIcon(
                                name: 'App Store',
                                icon: Icons.shopping_bag_rounded,
                                color: const Color(0xFF007AFF),
                                size: 44,
                              ),
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
    return _buildGlassWallpaper(
      t,
      SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Interactive Widgets Row: Live Music Player + Live Audience
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildIosWidgetCard(
                      height: 154,
                      child: _buildMusicContent(t),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildIosWidgetCard(
                      height: 154,
                      child: _buildAudienceContent(t),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

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
                        _buildAppIcon(
                          name: 'Photos',
                          icon: Icons.photo_library_rounded,
                          color: const Color(0xFFFF9500),
                        ),
                        _buildAppIcon(
                          name: 'Camera',
                          icon: Icons.camera_alt_rounded,
                          color: const Color(0xFF8E8E93),
                        ),
                        _buildAppIcon(
                          name: 'Safari',
                          icon: Icons.explore_rounded,
                          color: const Color(0xFF007AFF),
                        ),
                        _buildAppIcon(
                          name: 'Files',
                          icon: Icons.folder_rounded,
                          color: const Color(0xFF007AFF),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildAppIcon(
                          name: 'Messages',
                          icon: Icons.chat_bubble_rounded,
                          color: const Color(0xFF34C759),
                        ),
                        _buildAppIcon(
                          name: 'Maps',
                          icon: Icons.map_rounded,
                          color: const Color(0xFF30B0C7),
                        ),
                        _buildAppIcon(
                          name: 'Calendar',
                          icon: Icons.calendar_month_rounded,
                          color: const Color(0xFFFF3B30),
                        ),
                        _buildAppIcon(
                          name: 'Weather',
                          icon: Icons.cloud_rounded,
                          color: const Color(0xFF32ADE6),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildAppIcon(
                          name: 'Clock',
                          icon: Icons.access_time_filled_rounded,
                          color: const Color(0xFF1C1C1E),
                        ),
                        _buildAppIcon(
                          name: 'Notes',
                          icon: Icons.sticky_note_2_rounded,
                          color: const Color(0xFFFFCC00),
                        ),
                        _buildAppIcon(
                          name: 'Health',
                          icon: Icons.favorite_rounded,
                          color: const Color(0xFFFF2D55),
                        ),
                        _buildAppIcon(
                          name: 'App Store',
                          icon: Icons.shopping_bag_rounded,
                          color: const Color(0xFF007AFF),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Frosted Glass Spotlight Search Pill
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: LinearGradient(
                      colors: t.isDark
                          ? [
                              Colors.white.withValues(alpha: 0.14),
                              const Color(0xFF161C2A).withValues(alpha: 0.50),
                            ]
                          : [
                              Colors.white.withValues(alpha: 0.75),
                              Colors.white.withValues(alpha: 0.45),
                            ],
                    ),
                    border: Border.all(
                      color: t.isDark
                          ? Colors.white.withValues(alpha: 0.18)
                          : Colors.black.withValues(alpha: 0.06),
                      width: 0.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: t.isDark ? 0.25 : 0.04,
                        ),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.search_rounded,
                        size: 13,
                        color: t.subtextColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Search',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: t.subtextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Bottom Frosted Glass Dock
            _buildDock(t, compact: false),
        
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  /// Pure Apple iPhone Dark Midnight Glassmorphism Wallpaper
  Widget _buildGlassWallpaper(SoloTheme t, Widget child) {
    if (!t.isDark) {
      return Container(
        decoration: BoxDecoration(
          color: t.backgroundColor,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              t.backgroundColor,
              Color.lerp(t.backgroundColor, t.cardColor, 0.4)!,
              t.backgroundColor,
            ],
          ),
        ),
        child: child,
      );
    }

    return Container(
      color: const Color(0xFF06080E),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Ambient Indigo / Neon Violet Glow (top right)
          Positioned(
            top: -40,
            right: -40,
            width: 340,
            height: 340,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF381A78).withValues(alpha: 0.55),
                    const Color(0xFF1E0D45).withValues(alpha: 0.22),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),
          // Ambient Electric Sapphire / Azure Glow (center left)
          Positioned(
            top: 220,
            left: -60,
            width: 320,
            height: 320,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF094E8C).withValues(alpha: 0.48),
                    const Color(0xFF042749).withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),
          // Ambient Cyan / Teal Glow (bottom right)
          Positioned(
            bottom: 40,
            right: -40,
            width: 300,
            height: 300,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF08485B).withValues(alpha: 0.40),
                    const Color(0xFF03222C).withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }

  /// Live Music Player Widget with slowed, harmonic equalizer, rotating vinyl disc, and left-to-right progress.
  Widget _buildMusicContent(SoloTheme t) {
    return AnimatedBuilder(
      animation: _equalizerAnimController,
      builder: (context, _) {
        final eqProgress = _equalizerAnimController.value;
        final songProgress = _currentSongProgress;
        final elapsedText = _currentSongElapsedText;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Header Row: Live indicator + dynamic equalizer bars
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFA2D55).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        boxShadow: [
                          if (_isPlayingMusic)
                            BoxShadow(
                              color: const Color(
                                0xFFFA2D55,
                              ).withValues(alpha: 0.4),
                              blurRadius: 6,
                            ),
                        ],
                      ),
                      child: const Icon(
                        Icons.music_note_rounded,
                        color: Color(0xFFFA2D55),
                        size: 13,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isPlayingMusic ? 'NOW PLAYING' : 'PAUSED',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: _isPlayingMusic
                            ? const Color(0xFFFA2D55)
                            : t.subtextColor,
                      ),
                    ),
                  ],
                ),
                // Live animated equalizer bars (slowed down, gentle harmonic waves)
                _buildLiveEqualizerBars(t, eqProgress),
              ],
            ),

            // Middle: Rotating vinyl album artwork + track info
            Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Spinning vinyl disc behind artwork when playing (slow, smooth rotation)
                    if (_isPlayingMusic)
                      Transform.rotate(
                        angle: eqProgress * 2 * math.pi,
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black87,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFFFA2D55,
                                ).withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(2, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFFA2D55),
                              ),
                            ),
                          ),
                        ),
                      ),
                    // Front album cover
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFA2D55), Color(0xFF7A142A)],
                        ),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 0.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.album_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Midnight City',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: t.textColor,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'M83 · Hurry Up',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: t.subtextColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Bottom: Smooth linear progress bar animated from Left to Right & playback controls
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Left-to-Right Animated Progress Bar with scrub / tap-to-seek
                LayoutBuilder(
                  builder: (context, barConstraints) {
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (details) {
                        final width = barConstraints.maxWidth;
                        if (width > 0) {
                          final ratio = (details.localPosition.dx / width).clamp(0.0, 1.0);
                          _seekToRatio(ratio);
                        }
                      },
                      onHorizontalDragUpdate: (details) {
                        final width = barConstraints.maxWidth;
                        if (width > 0) {
                          final ratio = (details.localPosition.dx / width).clamp(0.0, 1.0);
                          _seekToRatio(ratio);
                        }
                      },
                      child: Container(
                        height: 10,
                        alignment: Alignment.center,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: Container(
                            height: 3.5,
                            width: double.infinity,
                            color: t.textColor.withValues(alpha: 0.12),
                            child: Stack(
                              alignment: Alignment.centerLeft,
                              children: [
                                FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: songProgress.clamp(0.005, 1.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        colors: [
                                          Color(0xFFFA2D55),
                                          Color(0xFFFF6482),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFFFA2D55,
                                          ).withValues(alpha: 0.45),
                                          blurRadius: 4,
                                          offset: const Offset(1, 0),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                // Playback control buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      elapsedText,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: t.subtextColor,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () => _seekBySeconds(-15),
                          borderRadius: BorderRadius.circular(12),
                          child: Icon(
                            Icons.skip_previous_rounded,
                            size: 17,
                            color: t.textColor.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(width: 10),
                        InkWell(
                          onTap: _toggleMusic,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFA2D55),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFFA2D55,
                                  ).withValues(alpha: 0.4),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              _isPlayingMusic
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              size: 15,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        InkWell(
                          onTap: () => _seekBySeconds(15),
                          borderRadius: BorderRadius.circular(12),
                          child: Icon(
                            Icons.skip_next_rounded,
                            size: 17,
                            color: t.textColor.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '4:03',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: t.subtextColor,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// Dynamic bouncing audio visualizer bars (calm, slowed-down musical harmonics).
  Widget _buildLiveEqualizerBars(SoloTheme t, double progress) {
    if (!_isPlayingMusic) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          5,
          (i) => Container(
            margin: const EdgeInsets.only(left: 2.5),
            width: 2.5,
            height: 3,
            decoration: BoxDecoration(
              color: t.subtextColor.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
        ),
      );
    }

    // Slowed-down, smooth harmonic wave heights
    final heights = [
      4.0 + 8.0 * (math.sin(progress * 2 * math.pi * 1.0) * 0.5 + 0.5),
      5.0 + 10.0 * (math.sin(progress * 2 * math.pi * 1.25 + 1.2) * 0.5 + 0.5),
      3.0 + 12.0 * (math.sin(progress * 2 * math.pi * 1.1 + 2.4) * 0.5 + 0.5),
      6.0 + 9.0 * (math.sin(progress * 2 * math.pi * 1.35 + 0.8) * 0.5 + 0.5),
      4.0 + 7.0 * (math.sin(progress * 2 * math.pi * 0.95 + 3.0) * 0.5 + 0.5),
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(
        5,
        (i) => Container(
          margin: const EdgeInsets.only(left: 2.5),
          width: 2.5,
          height: heights[i],
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Color(0xFFFA2D55), Color(0xFFFF6482)],
            ),
            borderRadius: BorderRadius.circular(1.5),
          ),
        ),
      ),
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
              style: TextStyle(
                color: Color(0xFF34C759),
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            const Spacer(),
            const Text('🔥', style: TextStyle(fontSize: 13)),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '2,418',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: t.textColor,
                height: 1.0,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'people tilting now',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: t.subtextColor,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: List.generate(
                12,
                (i) => Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    height: (math.sin(i * 0.7) * 4 + 7),
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

  /// Authentic Apple Frosted Glass Dock.
  Widget _buildDock(SoloTheme t, {required bool compact}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8.0 : 20.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(compact ? 100 : 100),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: compact ? 8 : 12,
              horizontal: compact ? 12 : 18,
            ),
            decoration: BoxDecoration(
              color: t.isDark
                  ? const Color(0xFF1A2234).withValues(alpha: 0.48)
                  : Colors.white.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(compact ? 100 : 100),
              border: Border.all(
                color: t.isDark
                    ? Colors.white.withValues(alpha: 0.22)
                    : Colors.white.withValues(alpha: 0.60),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: t.isDark ? 0.55 : 0.10),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                  spreadRadius: -3,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDockIcon(
                  icon: Icons.phone_rounded,
                  color: const Color(0xFF34C759),
                  compact: compact,
                ),
                _buildDockIcon(
                  icon: Icons.mail_rounded,
                  color: const Color(0xFF007AFF),
                  compact: compact,
                ),
                _buildDockIcon(
                  icon: Icons.explore_rounded,
                  color: const Color(0xFF007AFF),
                  compact: compact,
                ),
                _buildDockIcon(
                  icon: Icons.music_note_rounded,
                  color: const Color(0xFFFA2D55),
                  compact: compact,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Authentic Apple Frosted Glass Card.
  Widget _buildIosWidgetCard({
    required Widget child,
    double? height,
    EdgeInsetsGeometry? padding,
  }) {
    final t = _activeTheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: height,
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: t.isDark
                  ? [
                      Colors.white.withValues(alpha: 0.16),
                      const Color(0xFF182030).withValues(alpha: 0.46),
                      const Color(0xFF0B101B).withValues(alpha: 0.68),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.85),
                      Colors.white.withValues(alpha: 0.65),
                    ],
              stops: const [0.0, 0.45, 1.0],
            ),
            border: Border.all(
              color: t.isDark
                  ? Colors.white.withValues(alpha: 0.18)
                  : Colors.white.withValues(alpha: 0.65),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: t.isDark ? 0.42 : 0.06),
                blurRadius: 22,
                offset: const Offset(0, 8),
                spreadRadius: -2,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  List<Color> _getAppIconGradient(String name, Color baseColor) {
    switch (name) {
      case 'Photos':
        return const [Color(0xFFFFB340), Color(0xFFFF5E3A)];
      case 'Camera':
        return const [Color(0xFF98989E), Color(0xFF48484A)];
      case 'Safari':
        return const [Color(0xFF38A1FF), Color(0xFF0066D6)];
      case 'Files':
        return const [Color(0xFF3ED8E8), Color(0xFF007AFF)];
      case 'Messages':
        return const [Color(0xFF4CD964), Color(0xFF28CD41)];
      case 'Maps':
        return const [Color(0xFF30D2BE), Color(0xFF1E9C8D)];
      case 'Calendar':
        return const [Color(0xFFFF453A), Color(0xFFD70015)];
      case 'Weather':
        return const [Color(0xFF40C8E0), Color(0xFF0A84FF)];
      case 'Clock':
        return const [Color(0xFF2C2C2E), Color(0xFF121214)];
      case 'Notes':
        return const [Color(0xFFFFD60A), Color(0xFFFF9F0A)];
      case 'Health':
        return const [Color(0xFFFF375F), Color(0xFFD7003A)];
      case 'App Store':
        return const [Color(0xFF0A84FF), Color(0xFF0056B3)];
      default:
        return [baseColor, Color.lerp(baseColor, Colors.black, 0.25)!];
    }
  }

  Widget _buildAppIcon({
    required String name,
    required IconData icon,
    required Color color,
    double size = 56,
    bool compact = false,
  }) {
    final iconBoxSize = size;
    final gradientColors = _getAppIconGradient(name, color);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: iconBoxSize,
          height: iconBoxSize,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: gradientColors,
            ),
            borderRadius: BorderRadius.circular(iconBoxSize * 0.27),
            border: Border.all(
              color: Colors.white.withValues(
                alpha: _activeTheme.isDark ? 0.18 : 0.25,
              ),
              width: 0.7,
            ),
            boxShadow: [
              BoxShadow(
                color: gradientColors.last.withValues(
                  alpha: _activeTheme.isDark ? 0.40 : 0.28,
                ),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: iconBoxSize * 0.52),
        ),
        const SizedBox(height: 5),
        Text(
          name,
          style: TextStyle(
            fontSize: compact ? 9.5 : 11,
            fontWeight: FontWeight.w600,
            color: _activeTheme.textColor,
            letterSpacing: -0.1,
            shadows: _activeTheme.isDark
                ? [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.8),
                      blurRadius: 6,
                    ),
                  ]
                : null,
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
    final gradient = Color.lerp(color, Colors.black, 0.20)!;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color, gradient],
        ),
        borderRadius: BorderRadius.circular(compact ? 10 : 14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
          width: 0.7,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.38),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: compact ? 20 : 25),
    );
  }
}
