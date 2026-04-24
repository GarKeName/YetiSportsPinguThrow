import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

void main() {
  runApp(const ArcticSluggerApp());
}

class ArcticSluggerApp extends StatelessWidget {
  const ArcticSluggerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Pingu Throw Mobile',
      debugShowCheckedModeBanner: false,
      home: PinguThrowGamePage(),
    );
  }
}

enum RoundPhase {
  ready,
  dropping,
  flying,
  sliding,
  complete,
}

class PinguThrowGamePage extends StatefulWidget {
  const PinguThrowGamePage({super.key});

  @override
  State<PinguThrowGamePage> createState() => _PinguThrowGamePageState();
}

class _PinguThrowGamePageState extends State<PinguThrowGamePage>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastTickElapsed = Duration.zero;
  bool _assetsPrecached = false;
  final _game = ArcticSluggerGame();
  static const _stageAsset = 'assets/images/v2/stage_bg_classic.png';
  static const _flightAsset = 'assets/images/v2/flight_bg_classic.png';
  static const _yetiIdleAsset = 'assets/images/v2/yeti_idle.png';
  static const _yetiSwingAsset = 'assets/images/v2/yeti_swing_lr.png';
  static const _penguinAsset = 'assets/images/v2/penguin.png';
  static const _backgroundFilterQuality = FilterQuality.low;
  static const _spriteFilterQuality = FilterQuality.medium;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_assetsPrecached) {
      return;
    }
    _assetsPrecached = true;
    final preload = <String>[
      _stageAsset,
      _flightAsset,
      _yetiIdleAsset,
      _yetiSwingAsset,
      _penguinAsset,
    ];
    for (final path in preload) {
      precacheImage(AssetImage(path), context);
    }
  }

  void _onTick(Duration elapsed) {
    if (_lastTickElapsed == Duration.zero) {
      _lastTickElapsed = elapsed;
      return;
    }
    final rawDt = (elapsed - _lastTickElapsed).inMicroseconds / 1000000.0;
    _lastTickElapsed = elapsed;
    final dt = rawDt.clamp(1 / 240, 1 / 30);
    setState(() {
      _game.update(dt);
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF02101A),
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            setState(_game.handleTap);
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = constraints.maxWidth;
              final screenHeight = constraints.maxHeight;
              if (screenWidth <= 0 || screenHeight <= 0) {
                return const SizedBox.expand();
              }
              final isPortrait = screenHeight > screenWidth;
              if (isPortrait) {
                return _buildPortraitLayout(
                  screenWidth: screenWidth,
                  screenHeight: screenHeight,
                );
              }
              return _buildLandscapeLayout(
                screenWidth: screenWidth,
                screenHeight: screenHeight,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLandscapeLayout({
    required double screenWidth,
    required double screenHeight,
  }) {
    final worldScale = math.min(
      screenHeight / ArcticSluggerGame.worldHeight,
      screenWidth / ArcticSluggerGame.stageWidth,
    );
    final viewWorldWidth = screenWidth / worldScale;
    final gamePixelHeight = ArcticSluggerGame.worldHeight * worldScale;
    final gameTop = (screenHeight - gamePixelHeight) / 2;
    _game.portraitMode = false;
    _game.viewWorldWidth = viewWorldWidth;

    return Stack(
      children: [
        _buildSkyBackdrop(),
        Positioned(
          left: 0,
          right: 0,
          top: gameTop,
          height: gamePixelHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildScaledWorld(viewWorldWidth: viewWorldWidth),
              _buildOverlayUi(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPortraitLayout({
    required double screenWidth,
    required double screenHeight,
  }) {
    final targetGameHeight = (screenHeight * 0.72).clamp(
      420.0,
      screenHeight - 150.0,
    );
    final worldScale =
        (targetGameHeight / ArcticSluggerGame.worldHeight).clamp(0.72, 0.92);
    final viewWorldWidth = screenWidth / worldScale;
    final gamePixelHeight = ArcticSluggerGame.worldHeight * worldScale;
    _game.portraitMode = true;
    _game.viewWorldWidth = viewWorldWidth;

    return Stack(
      children: [
        _buildSkyBackdrop(),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: gamePixelHeight,
          child: _buildScaledWorld(
            viewWorldWidth: viewWorldWidth,
            showStageTopScore: false,
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: gamePixelHeight,
          bottom: 0,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFB7D9EC),
                  Color(0xFF97C5E0),
                  Color(0xFF78AFD3),
                ],
              ),
              border: Border(
                top: BorderSide(color: Color(0xBFEAF8FF), width: 2),
              ),
            ),
          ),
        ),
        _buildPortraitOverlayUi(gamePixelHeight: gamePixelHeight),
      ],
    );
  }

  Widget _buildScaledWorld({
    required double viewWorldWidth,
    bool showStageTopScore = true,
  }) {
    return ClipRect(
      child: RepaintBoundary(
        child: FittedBox(
          alignment: Alignment.topLeft,
          fit: BoxFit.fitWidth,
          child: SizedBox(
            width: viewWorldWidth,
            height: ArcticSluggerGame.worldHeight,
            child: Stack(
              children: [
                _buildFlightBackdropTiles(),
                _buildStartStageBackdrop(),
                _buildGroundPlane(),
                _buildDistancePosts(
                  startX: _game.cameraX,
                  width: viewWorldWidth,
                ),
                if (showStageTopScore) _buildStageTopScore(),
                _buildYeti(),
                _buildPenguin(),
                if (_game.phase == RoundPhase.dropping) _buildHitGuide(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkyBackdrop() =>
      const Positioned.fill(child: ColoredBox(color: Color(0xFF6EB9E5)));

  Widget _buildFlightBackdropTiles() {
    final tiles = <Widget>[];
    const tileWidth = ArcticSluggerGame.stageWidth;
    final shift = -(_game.cameraX % tileWidth);
    final tileCount = (_game.viewWorldWidth / tileWidth).ceil() + 3;

    for (int i = -1; i < tileCount - 1; i++) {
      tiles.add(
        Positioned(
          left: shift + (i * tileWidth),
          top: 0,
          child: Image.asset(
            _flightAsset,
            width: tileWidth,
            height: ArcticSluggerGame.worldHeight,
            fit: BoxFit.fill,
            filterQuality: _backgroundFilterQuality,
          ),
        ),
      );
    }
    return Stack(children: tiles);
  }

  Widget _buildStartStageBackdrop() {
    final fade =
        ((ArcticSluggerGame.stageWidth - _game.cameraX) / 220).clamp(0.0, 1.0);
    if (fade <= 0.0) {
      return const SizedBox.shrink();
    }
    final stageCoverWidth = math.max(
      ArcticSluggerGame.stageWidth,
      _game.cameraX + _game.viewWorldWidth + 2,
    );
    return Positioned(
      left: -_game.cameraX,
      top: 0,
      child: Opacity(
        opacity: fade,
        child: Image.asset(
          _stageAsset,
          width: stageCoverWidth,
          height: ArcticSluggerGame.worldHeight,
          fit: BoxFit.fill,
          filterQuality: _backgroundFilterQuality,
        ),
      ),
    );
  }

  Widget _buildStageTopScore() {
    return Positioned(
      left: 250 - _game.cameraX,
      top: 395,
      child: Text(
        'TOP: ${_game.bestDistanceMeters.round().toString().padLeft(5, '0')}',
        style: const TextStyle(
          color: Color(0xFF0FAF36),
          fontSize: 8,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.2,
          shadows: [
            Shadow(
              color: Color(0xB2FFFFFF),
              blurRadius: 1,
              offset: Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroundPlane() {
    return Positioned(
      left: ArcticSluggerGame.stageWidth - _game.cameraX - 1,
      right: -200,
      top: ArcticSluggerGame.groundY,
      bottom: 0,
      child: const DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0xE8F4FDFF), width: 2),
          ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE5F2F8),
              Color(0xFFC7DFED),
              Color(0xFFA4CCE2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDistancePosts({required double startX, required double width}) {
    final originX = _game.distanceMarkerOriginX;
    final minMeter =
        ((((startX - originX) / ArcticSluggerGame.pixelsPerMeter) / 50)
                .floor() *
            50);
    final maxMeter =
        (((((startX + width) - originX) / ArcticSluggerGame.pixelsPerMeter) /
                    50)
                .ceil() *
            50);

    final markers = <Widget>[];
    for (int meter = minMeter; meter <= maxMeter + 100; meter += 50) {
      if (meter < 100) {
        continue;
      }
      final x =
          originX + (meter * ArcticSluggerGame.pixelsPerMeter) - _game.cameraX;
      final isMajor = meter % 100 == 0;
      markers.add(
        Positioned(
          left: x,
          top: ArcticSluggerGame.groundY - (isMajor ? 76 : 52),
          child: Column(
            children: [
              Container(
                width: isMajor ? 3 : 2,
                height: isMajor ? 76 : 52,
                color: const Color(0xB5F1FAFF),
              ),
              if (isMajor)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xA9295474),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2F7FF)),
                  ),
                  child: Text(
                    '${meter}m',
                    style: const TextStyle(
                      color: Color(0xFFF6FDFF),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }
    return Stack(children: markers);
  }

  Widget _buildHitGuide() {
    return Positioned(
      left: _game.hitTargetX - _game.cameraX - 16,
      top: ArcticSluggerGame.groundY - 92,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xB92A4E6B),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xC7D5EEFA)),
        ),
        child: const Text(
          'HIT',
          style: TextStyle(
            color: Color(0xFFEFFCFF),
            fontWeight: FontWeight.w800,
            fontSize: 10,
          ),
        ),
      ),
    );
  }

  Widget _buildYeti() {
    final yetiAsset =
        _game.swingProgress > 0.0 ? _yetiSwingAsset : _yetiIdleAsset;
    return Positioned(
      left: _game.yetiX - _game.cameraX,
      top: _game.yetiY,
      child: SizedBox(
        width: ArcticSluggerGame.yetiWidth,
        height: ArcticSluggerGame.yetiHeight,
        child: Image.asset(
          yetiAsset,
          fit: BoxFit.contain,
          filterQuality: _spriteFilterQuality,
        ),
      ),
    );
  }

  Widget _buildPenguin() {
    const d = ArcticSluggerGame.penguinRenderSize;
    return Positioned(
      left: _game.penguinX - _game.cameraX - (d / 2),
      top: _game.penguinY - (d / 2),
      child: Transform.rotate(
        angle: _game.penguinRotation,
        child: SizedBox(
          width: d,
          height: d,
          child: Image.asset(
            _penguinAsset,
            fit: BoxFit.contain,
            filterQuality: _spriteFilterQuality,
          ),
        ),
      ),
    );
  }

  Widget _buildOverlayUi() {
    return Stack(
      children: [
        Align(
          alignment: Alignment.topLeft,
          child: Container(
            margin: const EdgeInsets.only(top: 8, left: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xA52C4D6A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBCE8FA)),
            ),
            child: Text(
              'DIST ${_game.currentDistanceMeters.toStringAsFixed(1)}m   BEST ${_game.bestDistanceMeters.toStringAsFixed(1)}m   WIND ${_game.windLabel}',
              style: const TextStyle(
                color: Color(0xFFEAF9FF),
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: FilledButton(
            onPressed: () {
              setState(_game.forceReset);
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xD0285D82),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: const Text('Reset'),
          ),
        ),
        Positioned(
          left: 10,
          right: 10,
          bottom: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xA5294E6A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0x9EE0F5FF)),
            ),
            child: Text(
              _game.prompt,
              style: const TextStyle(
                color: Color(0xFFEFFCFF),
                fontWeight: FontWeight.w700,
                fontSize: 15,
                shadows: [
                  Shadow(
                    color: Color(0xCC000000),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPortraitOverlayUi({required double gamePixelHeight}) {
    return Stack(
      children: [
        Align(
          alignment: Alignment.topLeft,
          child: Container(
            margin: const EdgeInsets.only(top: 8, left: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xA52C4D6A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBCE8FA)),
            ),
            child: Text(
              'DIST ${_game.currentDistanceMeters.toStringAsFixed(1)}m   BEST ${_game.bestDistanceMeters.toStringAsFixed(1)}m   WIND ${_game.windLabel}',
              style: const TextStyle(
                color: Color(0xFFEAF9FF),
                fontSize: 8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: FilledButton(
            onPressed: () {
              setState(_game.forceReset);
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xD0285D82),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: const Text('Reset'),
          ),
        ),
        Positioned(
          left: 10,
          right: 10,
          top: gamePixelHeight + 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xB02A4E6B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xAAE0F5FF)),
            ),
            child: Text(
              _game.prompt,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFEFFCFF),
                fontWeight: FontWeight.w700,
                fontSize: 17,
                shadows: [
                  Shadow(
                    color: Color(0xCC000000),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 10,
          right: 10,
          bottom: 12,
          child: Row(
            children: [
              Expanded(
                child: _buildPortraitStatChip(
                  label: 'DIST',
                  value: '${_game.currentDistanceMeters.toStringAsFixed(1)}m',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPortraitStatChip(
                  label: 'BEST',
                  value: '${_game.bestDistanceMeters.toStringAsFixed(1)}m',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPortraitStatChip(
                  label: 'WIND',
                  value: _game.windLabel,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPortraitStatChip({
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xBB2D5B7D),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xA8E3F6FF)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFD3EDFB),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: const TextStyle(
              color: Color(0xFFF6FDFF),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class ArcticSluggerGame {
  ArcticSluggerGame() {
    forceReset();
  }

  static const double worldHeight = 600;
  static const double stageWidth = 800;
  static const double groundY = 510;
  static const double pixelsPerMeter = 7.2;

  static const double cliffWidth = 220;
  static const double cliffHeight = 420;
  static const double yetiWidth = 220;
  static const double yetiHeight = 220;
  static const double penguinRadius = 17;
  static const double penguinRenderSize = 68;
  static const double swingDuration = 0.46;

  static const double dropGravity = 820;
  static const double flightGravity = 920;
  static const double dragPerFrame = 0.9987;
  static const double minLaunchAngleDeg = 20;
  static const double maxLaunchAngleDeg = 56;
  static const double minLaunchSpeed = 350;
  static const double maxLaunchSpeed = 1940;
  static const double arcLiftDuration = 0.42;
  static const double arcLiftBase = 0.22;
  static const double arcLiftQualityBoost = 0.18;

  final _rng = math.Random();

  RoundPhase phase = RoundPhase.ready;

  double cliffX = stageWidth - cliffWidth - 8;
  double cliffY = groundY - cliffHeight + 8;
  double yetiX = stageWidth - yetiWidth - 8;
  double yetiY = groundY - yetiHeight + 8;

  double penguinX = 0;
  double penguinY = 0;
  double penguinVx = 0;
  double penguinVy = 0;
  double penguinRotation = 0;
  double flightClock = 0;
  double launchQuality = 0;

  double swingTimer = 0;
  double idleClock = 0;
  int bounceCount = 0;

  double cameraX = 0;
  double viewWorldWidth = 800;
  bool portraitMode = false;

  double distanceMarkerOriginX = 0;
  double launchX = 0;
  double currentDistanceMeters = 0;
  double bestDistanceMeters = 0;

  double windForce = 0;

  bool get showPenguin => true;

  double get perchX => cliffX + 132;
  double get perchY => cliffY - penguinRadius - 6;

  double get hitTargetX => yetiX + 88;
  double get hitTargetY => yetiY + 86;

  double get swingProgress {
    if (swingTimer <= 0) {
      return 0;
    }
    return (1 - (swingTimer / swingDuration)).clamp(0.0, 1.0);
  }

  String get windLabel {
    if (windForce.abs() < 8) {
      return 'Calm';
    }
    final kmh = (windForce / 8).round().abs();
    if (windForce > 0) {
      return '$kmh km/h Tail';
    }
    return '$kmh km/h Head';
  }

  String get prompt {
    switch (phase) {
      case RoundPhase.ready:
        return 'Tap to drop the penguin. Tap again in the hit zone.';
      case RoundPhase.dropping:
        return 'Tap now for the swing. Perfect timing gives better launch.';
      case RoundPhase.flying:
        return 'Flight in progress.';
      case RoundPhase.sliding:
        return 'Sliding...';
      case RoundPhase.complete:
        return 'Round complete. Tap anywhere for the next throw.';
    }
  }

  void handleTap() {
    switch (phase) {
      case RoundPhase.ready:
      case RoundPhase.complete:
        _startDrop();
        break;
      case RoundPhase.dropping:
        _trySwing();
        break;
      case RoundPhase.flying:
      case RoundPhase.sliding:
        break;
    }
  }

  void forceReset() {
    phase = RoundPhase.ready;
    cameraX = 0;
    penguinX = perchX;
    penguinY = perchY;
    penguinVx = 0;
    penguinVy = 0;
    penguinRotation = -0.05;
    swingTimer = 0;
    idleClock = 0;
    bounceCount = 0;
    flightClock = 0;
    launchQuality = 0;
    distanceMarkerOriginX = hitTargetX;
    launchX = distanceMarkerOriginX;
    currentDistanceMeters = 0;
    windForce = (_rng.nextDouble() * 2 - 1) * 40;
  }

  void _startDrop() {
    phase = RoundPhase.dropping;
    cameraX = 0;
    swingTimer = 0;
    bounceCount = 0;
    flightClock = 0;
    launchQuality = 0;
    currentDistanceMeters = 0;

    windForce = (_rng.nextDouble() * 2 - 1) * 40;

    penguinX = perchX;
    penguinY = perchY;
    penguinVx = 0;
    penguinVy = 0;
    penguinRotation = 0;
    distanceMarkerOriginX = hitTargetX;
    launchX = distanceMarkerOriginX;
  }

  void _trySwing() {
    swingTimer = swingDuration;

    final xScore = (1 - ((penguinX - hitTargetX).abs() / 220)).clamp(0.0, 1.0);
    final yScore = (1 - ((penguinY - hitTargetY).abs() / 122)).clamp(0.0, 1.0);
    final quality = math
        .pow((xScore * 0.15 + yScore * 0.85), 0.90)
        .toDouble()
        .clamp(0.0, 1.0)
        .toDouble();

    final angleDeg = _lerp(minLaunchAngleDeg, maxLaunchAngleDeg, quality);
    final speed = _lerp(minLaunchSpeed, maxLaunchSpeed, quality);
    final angleRad = angleDeg * math.pi / 180;

    phase = RoundPhase.flying;
    launchX = distanceMarkerOriginX;
    flightClock = 0;
    launchQuality = quality;

    penguinVx = speed * math.cos(angleRad);
    penguinVy = -speed * math.sin(angleRad);

    if (quality < 0.14) {
      penguinVx = _lerp(140, 360, quality * 4.8);
      penguinVy = -_lerp(100, 280, quality * 4.8);
    }
  }

  void update(double dt) {
    if (dt <= 0) {
      return;
    }

    idleClock += dt;

    if (swingTimer > 0) {
      swingTimer = (swingTimer - dt).clamp(0.0, swingDuration);
    }

    var remaining = dt;
    const maxStep = 1 / 120;
    while (remaining > 0) {
      final step = math.min(remaining, maxStep);
      switch (phase) {
        case RoundPhase.ready:
          _updateReady(step);
          break;
        case RoundPhase.dropping:
          _updateDrop(step);
          break;
        case RoundPhase.flying:
          _updateFlight(step);
          break;
        case RoundPhase.sliding:
          _updateSlide(step);
          break;
        case RoundPhase.complete:
          break;
      }
      remaining -= step;
    }

    if (phase == RoundPhase.ready) {
      currentDistanceMeters = 0;
    } else {
      currentDistanceMeters =
          math.max(0, (penguinX - launchX) / pixelsPerMeter);
    }
  }

  void _updateReady(double dt) {
    penguinX = perchX;
    penguinY = perchY + (math.sin(idleClock * 2.2) * 1.8);
    penguinRotation = -0.04;
    _updateCamera(dt, fixed: true);
  }

  void _updateDrop(double dt) {
    penguinVy += dropGravity * dt;
    penguinY += penguinVy * dt;
    penguinRotation = math.min(0.55, penguinRotation + (2.2 * dt));

    if (penguinY >= groundY - penguinRadius) {
      penguinY = groundY - penguinRadius;
      penguinVy = 0;
      phase = RoundPhase.complete;
      currentDistanceMeters = 0;
      return;
    }

    _updateCamera(dt, fixed: true);
  }

  void _updateFlight(double dt) {
    flightClock += dt;
    final liftPhase = (1 - (flightClock / arcLiftDuration)).clamp(0.0, 1.0);
    final liftFactor = (arcLiftBase + (launchQuality * arcLiftQualityBoost)) *
        liftPhase.toDouble();
    final effectiveGravity = flightGravity * (1 - liftFactor);
    penguinVy += effectiveGravity * dt;
    penguinVx += windForce * dt;

    final drag = math.pow(dragPerFrame, dt * 60).toDouble();
    penguinVx *= drag;

    penguinX += penguinVx * dt;
    penguinY += penguinVy * dt;
    final desiredRotation =
        math.atan2(penguinVy, math.max(140.0, penguinVx.abs())) * 0.64;
    final turnBlend = math.min(1.0, dt * 6.2);
    penguinRotation += (desiredRotation - penguinRotation) * turnBlend;

    if (penguinY >= groundY - penguinRadius) {
      penguinY = groundY - penguinRadius;
      if (bounceCount < 1 && penguinVy > 220) {
        bounceCount += 1;
        penguinVy = -penguinVy * 0.22;
        penguinVx *= 0.93;
      } else {
        penguinVy = 0;
        phase = RoundPhase.sliding;
      }
    }

    _updateCamera(dt);
  }

  void _updateSlide(double dt) {
    final friction = _lerp(150, 232, (windForce.abs() / 70).clamp(0.0, 1.0));

    penguinX += penguinVx * dt;
    penguinRotation += (penguinVx / 620) * dt;
    penguinRotation *= math.pow(0.984, dt * 60).toDouble();

    if (penguinVx > 0) {
      penguinVx = math.max(0, penguinVx - friction * dt);
    } else {
      penguinVx = math.min(0, penguinVx + friction * dt);
    }

    if (penguinVx.abs() < 8) {
      penguinVx = 0;
      phase = RoundPhase.complete;
      bestDistanceMeters = math.max(bestDistanceMeters, currentDistanceMeters);
    }

    _updateCamera(dt);
  }

  void _updateCamera(double dt, {bool fixed = false}) {
    if (portraitMode) {
      final minCamera = math.min(0.0, stageWidth - viewWorldWidth);
      final fixedTarget = penguinX - (viewWorldWidth * 0.28);
      final target =
          fixed ? fixedTarget : penguinX - (viewWorldWidth * 0.38);
      final follow = fixed ? 0.28 : 0.13;
      cameraX += (target - cameraX) * (1 - math.pow(1 - follow, dt * 60));
      final maxCamera = fixed
          ? math.max(minCamera, stageWidth - viewWorldWidth + 32)
          : math.max(
              minCamera,
              penguinX + math.max(220.0, viewWorldWidth * 0.72) - viewWorldWidth,
            );
      cameraX = cameraX.clamp(minCamera, maxCamera).toDouble();
      return;
    }

    final isNarrowViewport = viewWorldWidth < stageWidth * 0.75;
    final portraitOffset =
        isNarrowViewport ? math.min(110.0, viewWorldWidth * 0.28) : 0.0;
    final fixedTarget =
        math.max(0, stageWidth - viewWorldWidth - portraitOffset);
    final leadDistance = math.max(0.0, penguinVx) * 0.08;
    final followTarget = math.max(
      0,
      penguinX + leadDistance - (viewWorldWidth * 0.38),
    );
    final target = fixed ? fixedTarget : followTarget;
    final follow = fixed ? 0.26 : 0.16;
    cameraX += (target - cameraX) * (1 - math.pow(1 - follow, dt * 60));
    cameraX = math.max(0, cameraX);
  }

  double _lerp(double a, double b, double t) => a + ((b - a) * t);
}
