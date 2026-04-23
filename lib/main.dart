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
    return MaterialApp(
      title: 'Arctic Slugger',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F6C88)),
        scaffoldBackgroundColor: const Color(0xFF001A2D),
        useMaterial3: true,
      ),
      home: const PinguThrowGamePage(),
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
  late DateTime _lastTick;
  final _game = ArcticSluggerGame();

  @override
  void initState() {
    super.initState();
    _lastTick = DateTime.now();
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration _) {
    final now = DateTime.now();
    final dt = (now.difference(_lastTick).inMicroseconds / 1000000.0)
        .clamp(0.0, 0.05);
    _lastTick = now;
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
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(_game.handleTap);
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;
          final worldScale = (screenHeight / ArcticSluggerGame.worldHeight)
              .clamp(0.45, 1.15);
          final viewWorldWidth = screenWidth / worldScale;
          _game.viewWorldWidth = viewWorldWidth;

          return Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/arctic_bg.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, _, __) {
                    return CustomPaint(
                      size: Size(screenWidth, screenHeight),
                      painter: ArcticBackgroundPainter(
                        cameraX: _game.cameraX,
                        worldScale: worldScale,
                      ),
                    );
                  },
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.1),
                        Colors.black.withOpacity(0.04),
                        Colors.black.withOpacity(0.22),
                      ],
                    ),
                  ),
                ),
              ),
              ClipRect(
                child: Transform.scale(
                  alignment: Alignment.topLeft,
                  scale: worldScale,
                  child: SizedBox(
                    width: viewWorldWidth,
                    height: ArcticSluggerGame.worldHeight,
                    child: Stack(
                      children: [
                        _buildDistancePosts(
                          startX: _game.cameraX,
                          width: viewWorldWidth,
                        ),
                        _buildGroundShadow(),
                        _buildCliff(),
                        _buildYeti(),
                        if (_game.showPenguin) _buildPenguin(),
                      ],
                    ),
                  ),
                ),
              ),
              _buildTopHud(context),
              _buildBottomPrompt(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDistancePosts({required double startX, required double width}) {
    final minMeter = ((startX / ArcticSluggerGame.pixelsPerMeter) / 25).floor() * 25;
    final maxMeter = (((startX + width) / ArcticSluggerGame.pixelsPerMeter) / 25).ceil() * 25 +
        50;
    final posts = <Widget>[];

    for (int meter = minMeter; meter <= maxMeter; meter += 25) {
      if (meter <= 0) {
        continue;
      }
      final x = meter * ArcticSluggerGame.pixelsPerMeter - _game.cameraX;
      final isMajor = meter % 100 == 0;
      posts.add(
        Positioned(
          left: x,
          top: ArcticSluggerGame.groundY - (isMajor ? 140 : 98),
          child: Column(
            children: [
              Container(
                width: isMajor ? 5 : 3,
                height: isMajor ? 138 : 96,
                decoration: BoxDecoration(
                  color: isMajor
                      ? const Color(0xFFD6F5FF)
                      : const Color(0xFF95D3E6),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              if (isMajor)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xAA002E4A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${meter}m',
                    style: const TextStyle(
                      color: Color(0xFFE0F7FF),
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Stack(children: posts);
  }

  Widget _buildGroundShadow() {
    return Positioned(
      left: -_game.cameraX - 200,
      right: -200,
      top: ArcticSluggerGame.groundY,
      bottom: 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0x66ACD4E8),
              const Color(0xFF325A75),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCliff() {
    return Positioned(
      left: _game.cliffX - _game.cameraX,
      top: _game.cliffY,
      child: _sprite(
        assetPath: 'assets/images/cliff.png',
        width: 190,
        height: 300,
        fallbackColor: const Color(0xFF496274),
        fallbackText: 'CLIFF',
      ),
    );
  }

  Widget _buildYeti() {
    final isSwinging = _game.swingTimer > 0;
    final yetiAsset = isSwinging
        ? 'assets/images/yeti_swing.png'
        : 'assets/images/yeti_idle.png';

    return Positioned(
      left: _game.yetiX - _game.cameraX,
      top: _game.yetiY,
      child: _sprite(
        assetPath: yetiAsset,
        width: 240,
        height: 250,
        fallbackColor: const Color(0xFF5BAEC7),
        fallbackText: isSwinging ? 'SWING' : 'YETI',
      ),
    );
  }

  Widget _buildPenguin() {
    final rotation = _game.penguinRotation;
    return Positioned(
      left: _game.penguinX - _game.cameraX - 42,
      top: _game.penguinY - 42,
      child: Transform.rotate(
        angle: rotation,
        child: _sprite(
          assetPath: 'assets/images/penguin.png',
          width: 84,
          height: 84,
          fallbackColor: const Color(0xFF202B39),
          fallbackText: 'P',
        ),
      ),
    );
  }

  Widget _sprite({
    required String assetPath,
    required double width,
    required double height,
    required Color fallbackColor,
    required String fallbackText,
  }) {
    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, _, __) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: fallbackColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white24),
          ),
          alignment: Alignment.center,
          child: Text(
            fallbackText,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopHud(BuildContext context) {
    final score = _game.currentDistanceMeters;
    final best = _game.bestDistanceMeters;

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: _frostPanel(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _statChip('DIST', '${score.toStringAsFixed(1)} m'),
              const SizedBox(width: 10),
              _statChip('BEST', '${best.toStringAsFixed(1)} m'),
              const SizedBox(width: 10),
              _statChip('WIND', _game.windLabel),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statChip(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF063750),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF8CCFE5),
              fontSize: 10,
              letterSpacing: 0.7,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPrompt(BuildContext context) {
    final prompt = _game.prompt;

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: _frostPanel(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 22),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  prompt,
                  style: const TextStyle(
                    color: Color(0xFFD7F5FF),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: () {
                  setState(_game.forceReset);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0C6B89),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Reset'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _frostPanel({
    required Widget child,
    required EdgeInsetsGeometry margin,
    required EdgeInsetsGeometry padding,
  }) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF356C86)),
        image: const DecorationImage(
          image: AssetImage('assets/images/ui_panel.png'),
          fit: BoxFit.fill,
        ),
        color: const Color(0xCC021B2B),
      ),
      child: child,
    );
  }
}

class ArcticSluggerGame {
  static const double worldHeight = 700;
  static const double groundY = 545;
  static const double pixelsPerMeter = 10;

  final _rng = math.Random();

  RoundPhase phase = RoundPhase.ready;

  double cliffX = 18;
  double cliffY = 212;
  double yetiX = 132;
  double yetiY = 292;

  double penguinX = 115;
  double penguinY = 238;
  double penguinVx = 0;
  double penguinVy = 0;
  double penguinRotation = 0;

  double swingTimer = 0;
  double dropTimer = 0;
  int bounceCount = 0;

  double cameraX = 0;
  double viewWorldWidth = 390;

  double launchX = 0;
  double currentDistanceMeters = 0;
  double bestDistanceMeters = 0;

  double windForce = 0;

  bool get showPenguin =>
      phase != RoundPhase.ready || currentDistanceMeters > 0 || dropTimer > 0;

  String get windLabel {
    if (windForce.abs() < 8) {
      return 'Calm';
    }
    final kmh = (windForce / 9).round().abs();
    if (windForce > 0) {
      return '${kmh} km/h Tail';
    }
    return '${kmh} km/h Head';
  }

  String get prompt {
    switch (phase) {
      case RoundPhase.ready:
        return 'Tap to drop the penguin. Tap again in the hit zone.';
      case RoundPhase.dropping:
        return 'Tap now for the swing. Perfect timing gives better launch.';
      case RoundPhase.flying:
        return 'Flight in progress. Watch distance climb.';
      case RoundPhase.sliding:
        return 'Sliding... friction is eating speed.';
      case RoundPhase.complete:
        return 'Round complete. Tap anywhere to start the next throw.';
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
    penguinX = 115;
    penguinY = 238;
    penguinVx = 0;
    penguinVy = 0;
    penguinRotation = 0;
    swingTimer = 0;
    dropTimer = 0;
    currentDistanceMeters = 0;
    windForce = 0;
  }

  void _startDrop() {
    phase = RoundPhase.dropping;
    dropTimer = 0;
    swingTimer = 0;
    bounceCount = 0;

    // Small per-round wind variation keeps rounds from feeling identical.
    windForce = (_rng.nextDouble() * 2 - 1) * 78;

    penguinX = yetiX + 95;
    penguinY = 80;
    penguinVx = 0;
    penguinVy = 0;
    penguinRotation = 0;

    currentDistanceMeters = 0;
    cameraX = 0;
  }

  void _trySwing() {
    swingTimer = 0.16;

    final targetX = yetiX + 120;
    final targetY = yetiY + 76;

    final offsetX = (penguinX - targetX).abs();
    final offsetY = (penguinY - targetY).abs();

    final xScore = (1 - (offsetX / 80)).clamp(0.0, 1.0);
    final yScore = (1 - (offsetY / 110)).clamp(0.0, 1.0);
    final quality = math.pow(xScore * yScore, 0.75).toDouble();

    final angleDeg = _lerp(26, 56, quality);
    final speed = _lerp(260, 1450, quality);

    final angleRad = angleDeg * math.pi / 180;

    phase = RoundPhase.flying;
    launchX = penguinX;

    penguinVx = speed * math.cos(angleRad);
    penguinVy = -speed * math.sin(angleRad);

    if (quality < 0.12) {
      penguinVx = _lerp(120, 320, quality * 4);
      penguinVy = -_lerp(60, 180, quality * 4);
    }
  }

  void update(double dt) {
    if (dt <= 0) {
      return;
    }

    if (swingTimer > 0) {
      swingTimer = (swingTimer - dt).clamp(0.0, 10.0);
    }

    switch (phase) {
      case RoundPhase.ready:
      case RoundPhase.complete:
        _updateCamera(dt, fixed: true);
        break;
      case RoundPhase.dropping:
        _updateDrop(dt);
        break;
      case RoundPhase.flying:
        _updateFlight(dt);
        break;
      case RoundPhase.sliding:
        _updateSlide(dt);
        break;
    }

    currentDistanceMeters = math.max(0, (penguinX - launchX) / pixelsPerMeter);
  }

  void _updateDrop(double dt) {
    dropTimer += dt;

    penguinVy += 1750 * dt;
    penguinY += penguinVy * dt;

    if (penguinY >= groundY - 36) {
      penguinY = groundY - 36;
      penguinVy = 0;
      phase = RoundPhase.complete;
      currentDistanceMeters = 0;
      bestDistanceMeters = math.max(bestDistanceMeters, currentDistanceMeters);
      return;
    }

    _updateCamera(dt, fixed: true);
  }

  void _updateFlight(double dt) {
    penguinVy += 1960 * dt;
    penguinVx += windForce * dt;

    // Mild aerodynamic drag to avoid extremely long tails.
    final drag = math.pow(0.989, dt * 60).toDouble();
    penguinVx *= drag;

    penguinX += penguinVx * dt;
    penguinY += penguinVy * dt;
    penguinRotation += penguinVx.sign * 5.4 * dt;

    if (penguinY >= groundY - 32) {
      penguinY = groundY - 32;

      if (bounceCount < 1 && penguinVy.abs() > 290) {
        bounceCount += 1;
        penguinVy = -penguinVy * 0.28;
        penguinVx *= 0.86;
      } else {
        penguinVy = 0;
        phase = RoundPhase.sliding;
      }
    }

    _updateCamera(dt);
  }

  void _updateSlide(double dt) {
    final friction = _lerp(150, 250, (windForce.abs() / 90).clamp(0.0, 1.0));

    penguinX += penguinVx * dt;
    penguinRotation += penguinVx.sign * 2.2 * dt;

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
    final target = fixed ? 0.0 : math.max(0, penguinX - (viewWorldWidth * 0.33));
    final follow = fixed ? 0.22 : 0.16;
    cameraX += (target - cameraX) * (1 - math.pow(1 - follow, dt * 60));
  }

  double _lerp(double a, double b, double t) => a + ((b - a) * t);
}

class ArcticBackgroundPainter extends CustomPainter {
  ArcticBackgroundPainter({required this.cameraX, required this.worldScale});

  final double cameraX;
  final double worldScale;

  @override
  void paint(Canvas canvas, Size size) {
    final sky = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF053252),
          Color(0xFF0A5D82),
          Color(0xFF43A8C7),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, sky);

    _drawMountainLayer(
      canvas,
      size,
      parallax: 0.14,
      baseY: size.height * 0.48,
      color: const Color(0xFF1B5878),
      peaks: const [
        _Peak(0.0, 0.12),
        _Peak(0.24, 0.1),
        _Peak(0.58, 0.15),
        _Peak(0.86, 0.11),
      ],
    );

    _drawMountainLayer(
      canvas,
      size,
      parallax: 0.25,
      baseY: size.height * 0.56,
      color: const Color(0xFF2F7DA1),
      peaks: const [
        _Peak(0.02, 0.16),
        _Peak(0.31, 0.12),
        _Peak(0.62, 0.18),
        _Peak(0.88, 0.1),
      ],
    );

    final snow = Paint()..color = const Color(0xFFE5F8FF).withOpacity(0.45);
    final randSeed = (cameraX * 0.16).round();
    for (var i = 0; i < 42; i++) {
      final x = ((i * 127 + randSeed * 13) % (size.width.toInt() + 40)) - 20;
      final y = ((i * 83 + randSeed * 7) % (size.height.toInt() * 3 ~/ 5));
      canvas.drawCircle(Offset(x.toDouble(), y.toDouble()), (i % 3 + 1).toDouble(), snow);
    }

    final ice = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFBFE8F8).withOpacity(0.94),
          const Color(0xFF86C5DD).withOpacity(0.9),
        ],
      ).createShader(
        Rect.fromLTWH(0, size.height * 0.77, size.width, size.height * 0.26),
      );

    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.77, size.width, size.height * 0.26),
      ice,
    );

    final crack = Paint()
      ..color = const Color(0xFF72AFCA).withOpacity(0.54)
      ..strokeWidth = 2.2;
    for (var i = 0; i < 8; i++) {
      final startX = ((i * 180) - (cameraX * worldScale * 0.85) % 180) - 20;
      final path = Path()
        ..moveTo(startX, size.height * 0.86)
        ..lineTo(startX + 90, size.height * 0.83)
        ..lineTo(startX + 180, size.height * 0.88);
      canvas.drawPath(path, crack);
    }
  }

  void _drawMountainLayer(
    Canvas canvas,
    Size size, {
    required double parallax,
    required double baseY,
    required Color color,
    required List<_Peak> peaks,
  }) {
    final shift = -(cameraX * worldScale * parallax) % size.width;
    for (double offset = shift - size.width; offset <= size.width; offset += size.width) {
      final path = Path()..moveTo(offset, size.height);
      for (final peak in peaks) {
        path.lineTo(
          offset + (size.width * peak.xFactor),
          baseY - (size.height * peak.heightFactor),
        );
      }
      path
        ..lineTo(offset + size.width, size.height)
        ..close();

      canvas.drawPath(path, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant ArcticBackgroundPainter oldDelegate) {
    return oldDelegate.cameraX != cameraX || oldDelegate.worldScale != worldScale;
  }
}

class _Peak {
  const _Peak(this.xFactor, this.heightFactor);

  final double xFactor;
  final double heightFactor;
}
