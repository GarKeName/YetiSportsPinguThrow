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
    return Scaffold(
      backgroundColor: const Color(0xFF0A1420),
      body: SafeArea(
        child: Center(
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBFD8E8), width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xAA000000),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(_game.handleTap);
                  },
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final screenWidth = constraints.maxWidth;
                      final screenHeight = constraints.maxHeight;
                      final worldScale =
                          (screenHeight / ArcticSluggerGame.worldHeight)
                              .clamp(0.55, 1.6);
                      final viewWorldWidth = screenWidth / worldScale;
                      _game.viewWorldWidth = viewWorldWidth;

                      return Stack(
                        children: [
                          CustomPaint(
                            size: Size(screenWidth, screenHeight),
                            painter: ArcticBackgroundPainter(
                              cameraX: _game.cameraX,
                              worldScale: worldScale,
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
                                    _buildGroundPlane(),
                                    _buildDistancePosts(
                                      startX: _game.cameraX,
                                      width: viewWorldWidth,
                                    ),
                                    _buildDecorationSet(),
                                    _buildCliff(),
                                    _buildYeti(),
                                    _buildPenguin(),
                                    if (_game.phase == RoundPhase.dropping)
                                      _buildHitGuide(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          _buildOverlayUi(),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroundPlane() {
    return Positioned(
      left: -_game.cameraX - 200,
      right: -200,
      top: ArcticSluggerGame.groundY,
      bottom: 0,
      child: const DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0xFFE4F7FF), width: 2),
          ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFD5EBF7),
              Color(0xFFA9D0E8),
              Color(0xFF89BEDD),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDistancePosts({required double startX, required double width}) {
    final minMeter =
        ((startX / ArcticSluggerGame.pixelsPerMeter) / 50).floor() * 50;
    final maxMeter = (((startX + width) / ArcticSluggerGame.pixelsPerMeter) / 50)
            .ceil() *
        50;

    final markers = <Widget>[];
    for (int meter = minMeter; meter <= maxMeter + 100; meter += 50) {
      if (meter <= 0) {
        continue;
      }
      final x = meter * ArcticSluggerGame.pixelsPerMeter - _game.cameraX;
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
                color: const Color(0xE6E8F8FF),
              ),
              if (isMajor)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xA1113044),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF9FDDF6)),
                  ),
                  child: Text(
                    '${meter}m',
                    style: const TextStyle(
                      color: Color(0xFFEAF9FF),
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

  Widget _buildDecorationSet() {
    return Stack(
      children: [
        Positioned(
          left: 260 - _game.cameraX,
          top: ArcticSluggerGame.groundY - 130,
          child: const SizedBox(
            width: 60,
            height: 130,
            child: CustomPaint(painter: PineTreePainter()),
          ),
        ),
        Positioned(
          left: 470 - _game.cameraX,
          top: ArcticSluggerGame.groundY - 115,
          child: const SizedBox(
            width: 50,
            height: 115,
            child: CustomPaint(painter: PineTreePainter()),
          ),
        ),
        Positioned(
          left: 356 - _game.cameraX,
          top: ArcticSluggerGame.groundY - 84,
          child: SizedBox(
            width: 156,
            height: 84,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const CustomPaint(
                  size: Size(156, 84),
                  painter: IceScoreSignPainter(),
                ),
                Positioned(
                  top: 23,
                  child: Text(
                    'TOP: ${_game.bestDistanceMeters.round().toString().padLeft(4, '0')}',
                    style: const TextStyle(
                      color: Color(0xFF11476B),
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 548 - _game.cameraX,
          top: ArcticSluggerGame.groundY - 45,
          child: const SizedBox(
            width: 84,
            height: 52,
            child: CustomPaint(painter: IceRockPainter()),
          ),
        ),
      ],
    );
  }

  Widget _buildHitGuide() {
    return Positioned(
      left: _game.hitTargetX - _game.cameraX - 2,
      top: ArcticSluggerGame.groundY - 150,
      child: Column(
        children: [
          Container(
            width: 4,
            height: 118,
            decoration: BoxDecoration(
              color: const Color(0xCCFFF3A8),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xA0112E3F),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFF7E66E)),
            ),
            child: const Text(
              'HIT',
              style: TextStyle(
                color: Color(0xFFFBEA72),
                fontWeight: FontWeight.w800,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCliff() {
    return Positioned(
      left: _game.cliffX - _game.cameraX,
      top: _game.cliffY,
      child: const SizedBox(
        width: ArcticSluggerGame.cliffWidth,
        height: ArcticSluggerGame.cliffHeight,
        child: CustomPaint(painter: CliffPainter()),
      ),
    );
  }

  Widget _buildYeti() {
    return Positioned(
      left: _game.yetiX - _game.cameraX,
      top: _game.yetiY,
      child: SizedBox(
        width: ArcticSluggerGame.yetiWidth,
        height: ArcticSluggerGame.yetiHeight,
        child: CustomPaint(
          painter: YetiPainter(swingProgress: _game.swingProgress),
        ),
      ),
    );
  }

  Widget _buildPenguin() {
    const d = ArcticSluggerGame.penguinRadius * 2.6;
    return Positioned(
      left: _game.penguinX - _game.cameraX - (d / 2),
      top: _game.penguinY - (d / 2),
      child: Transform.rotate(
        angle: _game.penguinRotation,
        child: const SizedBox(
          width: d,
          height: d,
          child: CustomPaint(painter: PenguinPainter()),
        ),
      ),
    );
  }

  Widget _buildOverlayUi() {
    return SafeArea(
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xAA1D445E),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF9ED7EF)),
              ),
              child: Text(
                'DIST ${_game.currentDistanceMeters.toStringAsFixed(1)} m   BEST ${_game.bestDistanceMeters.toStringAsFixed(1)} m   WIND ${_game.windLabel}',
                style: const TextStyle(
                  color: Color(0xFFEAF9FF),
                  fontSize: 13,
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
                backgroundColor: const Color(0xFF0B668D),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              child: const Text('Reset'),
            ),
          ),
          Positioned(
            left: 12,
            bottom: 10,
            child: Text(
              _game.prompt,
              style: const TextStyle(
                color: Color(0xFFEFFCFF),
                fontWeight: FontWeight.w700,
                fontSize: 16,
                shadows: [
                  Shadow(
                    color: Color(0xCC000000),
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
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
  static const double groundY = 500;
  static const double pixelsPerMeter = 10.5;

  static const double cliffWidth = 176;
  static const double cliffHeight = 310;
  static const double yetiWidth = 92;
  static const double yetiHeight = 132;
  static const double penguinRadius = 14;
  static const double swingDuration = 0.16;

  final _rng = math.Random();

  RoundPhase phase = RoundPhase.ready;

  double cliffX = 54;
  double cliffY = groundY - cliffHeight + 10;
  double yetiX = 168;
  double yetiY = groundY - yetiHeight + 4;

  double penguinX = 0;
  double penguinY = 0;
  double penguinVx = 0;
  double penguinVy = 0;
  double penguinRotation = 0;

  double swingTimer = 0;
  double idleClock = 0;
  int bounceCount = 0;

  double cameraX = 0;
  double viewWorldWidth = 800;

  double launchX = 0;
  double currentDistanceMeters = 0;
  double bestDistanceMeters = 0;

  double windForce = 0;

  bool get showPenguin => true;

  double get perchX => cliffX + 88;
  double get perchY => cliffY - penguinRadius - 4;

  double get hitTargetX => yetiX + 55;
  double get hitTargetY => yetiY + 48;

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
    penguinX = perchX;
    penguinY = perchY;
    penguinVx = 0;
    penguinVy = 0;
    penguinRotation = -0.05;
    swingTimer = 0;
    idleClock = 0;
    bounceCount = 0;
    launchX = hitTargetX;
    currentDistanceMeters = 0;
    windForce = (_rng.nextDouble() * 2 - 1) * 65;
  }

  void _startDrop() {
    phase = RoundPhase.dropping;
    swingTimer = 0;
    bounceCount = 0;
    currentDistanceMeters = 0;

    windForce = (_rng.nextDouble() * 2 - 1) * 70;

    penguinX = perchX;
    penguinY = perchY;
    penguinVx = 0;
    penguinVy = 0;
    penguinRotation = 0;
    launchX = hitTargetX;
  }

  void _trySwing() {
    swingTimer = swingDuration;

    final xScore = (1 - ((penguinX - hitTargetX).abs() / 52)).clamp(0.0, 1.0);
    final yScore = (1 - ((penguinY - hitTargetY).abs() / 122)).clamp(0.0, 1.0);
    final quality = math.pow((xScore * 0.45 + yScore * 0.55), 1.1).toDouble();

    final angleDeg = _lerp(18, 48, quality);
    final speed = _lerp(240, 1540, quality);
    final angleRad = angleDeg * math.pi / 180;

    phase = RoundPhase.flying;
    launchX = penguinX;

    penguinVx = speed * math.cos(angleRad);
    penguinVy = -speed * math.sin(angleRad);

    if (quality < 0.14) {
      penguinVx = _lerp(120, 320, quality * 4.8);
      penguinVy = -_lerp(90, 220, quality * 4.8);
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

    switch (phase) {
      case RoundPhase.ready:
        _updateReady(dt);
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
      case RoundPhase.complete:
        break;
    }

    if (phase == RoundPhase.ready) {
      currentDistanceMeters = 0;
    } else {
      currentDistanceMeters = math.max(0, (penguinX - launchX) / pixelsPerMeter);
    }
  }

  void _updateReady(double dt) {
    penguinX = perchX;
    penguinY = perchY + (math.sin(idleClock * 2.2) * 1.8);
    penguinRotation = -0.05;
    _updateCamera(dt, fixed: true);
  }

  void _updateDrop(double dt) {
    penguinVy += 2050 * dt;
    penguinY += penguinVy * dt;

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
    penguinVy += 1930 * dt;
    penguinVx += windForce * dt;

    final drag = math.pow(0.99, dt * 60).toDouble();
    penguinVx *= drag;

    penguinX += penguinVx * dt;
    penguinY += penguinVy * dt;
    penguinRotation += penguinVx.sign * 5.0 * dt;

    if (penguinY >= groundY - penguinRadius) {
      penguinY = groundY - penguinRadius;
      if (bounceCount < 2 && penguinVy > 280) {
        bounceCount += 1;
        penguinVy = -penguinVy * (bounceCount == 1 ? 0.32 : 0.18);
        penguinVx *= 0.84;
      } else {
        penguinVy = 0;
        phase = RoundPhase.sliding;
      }
    }

    _updateCamera(dt);
  }

  void _updateSlide(double dt) {
    final friction = _lerp(170, 265, (windForce.abs() / 85).clamp(0.0, 1.0));

    penguinX += penguinVx * dt;
    penguinRotation += penguinVx.sign * 2.4 * dt;

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
    final target = fixed
        ? 0.0
        : math.max(0, penguinX - (viewWorldWidth * 0.42));
    final follow = fixed ? 0.22 : 0.14;
    cameraX += (target - cameraX) * (1 - math.pow(1 - follow, dt * 60));
    cameraX = math.max(0, cameraX);
  }

  double _lerp(double a, double b, double t) => a + ((b - a) * t);
}

class ArcticBackgroundPainter extends CustomPainter {
  const ArcticBackgroundPainter({
    required this.cameraX,
    required this.worldScale,
  });

  final double cameraX;
  final double worldScale;

  @override
  void paint(Canvas canvas, Size size) {
    final sky = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF6E7B8A),
          Color(0xFF2B84C2),
          Color(0xFF8EC8EE),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, sky);

    canvas.drawCircle(
      Offset(size.width * 0.74, size.height * 0.18),
      size.width * 0.06,
      Paint()..color = const Color(0x66FFFFFF),
    );

    _drawMountains(
      canvas,
      size,
      baseY: size.height * 0.66,
      parallax: 0.17,
      color: const Color(0xFF9EBED6),
      peaks: const [0.00, 0.16, 0.33, 0.49, 0.66, 0.82, 1.00],
      heights: const [0.16, 0.09, 0.17, 0.10, 0.15, 0.08, 0.14],
    );

    _drawMountains(
      canvas,
      size,
      baseY: size.height * 0.70,
      parallax: 0.29,
      color: const Color(0xFFB9CFDF),
      peaks: const [0.02, 0.22, 0.40, 0.61, 0.80, 0.98],
      heights: const [0.22, 0.15, 0.21, 0.14, 0.23, 0.16],
    );

    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.64, size.width, size.height * 0.34),
      Paint()..color = const Color(0x88E8F6FF),
    );
  }

  void _drawMountains(
    Canvas canvas,
    Size size, {
    required double baseY,
    required double parallax,
    required Color color,
    required List<double> peaks,
    required List<double> heights,
  }) {
    final shift = -(cameraX * worldScale * parallax) % size.width;
    for (double offset = shift - size.width; offset <= size.width; offset += size.width) {
      final path = Path()..moveTo(offset, size.height);
      for (int i = 0; i < peaks.length; i++) {
        final x = offset + (size.width * peaks[i]);
        final y = baseY - (size.height * heights[i]);
        path.lineTo(x, y);
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

class CliffPainter extends CustomPainter {
  const CliffPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cliff = Path()
      ..moveTo(size.width * 0.08, size.height)
      ..lineTo(size.width * 0.16, size.height * 0.20)
      ..lineTo(size.width * 0.26, size.height * 0.10)
      ..lineTo(size.width * 0.33, size.height * 0.05)
      ..lineTo(size.width * 0.40, size.height * 0.00)
      ..lineTo(size.width * 0.47, size.height * 0.03)
      ..lineTo(size.width * 0.56, size.height * 0.10)
      ..lineTo(size.width * 0.64, size.height * 0.22)
      ..lineTo(size.width * 0.82, size.height * 0.82)
      ..lineTo(size.width * 0.92, size.height)
      ..close();

    canvas.drawPath(
      cliff,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFBCC6D2),
            Color(0xFF8E9EAF),
            Color(0xFF738396),
          ],
        ).createShader(Offset.zero & size),
    );

    final shade = Paint()
      ..color = const Color(0x663A4A5C)
      ..style = PaintingStyle.fill;
    final stripes = [
      [0.28, 0.12, 0.22, 0.92],
      [0.46, 0.18, 0.40, 0.97],
      [0.61, 0.24, 0.56, 0.96],
    ];
    for (final s in stripes) {
      canvas.drawLine(
        Offset(size.width * s[0], size.height * s[1]),
        Offset(size.width * s[2], size.height * s[3]),
        shade..strokeWidth = 8,
      );
    }

    final cap = Path()
      ..moveTo(size.width * 0.26, size.height * 0.11)
      ..lineTo(size.width * 0.35, size.height * 0.03)
      ..lineTo(size.width * 0.46, size.height * 0.02)
      ..lineTo(size.width * 0.57, size.height * 0.11)
      ..lineTo(size.width * 0.42, size.height * 0.14)
      ..close();
    canvas.drawPath(cap, Paint()..color = const Color(0xFFEFF8FF));

    canvas.drawPath(
      cliff,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF4B5E72),
    );
  }

  @override
  bool shouldRepaint(covariant CliffPainter oldDelegate) => false;
}

class YetiPainter extends CustomPainter {
  const YetiPainter({required this.swingProgress});

  final double swingProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final body = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFEFF6FB),
          Color(0xFFD7E6F3),
          Color(0xFFC4D6E7),
        ],
      ).createShader(Offset.zero & size);
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = const Color(0xFF2A628F);

    final torso = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.22, size.height * 0.33, size.width * 0.52,
          size.height * 0.52),
      const Radius.circular(24),
    );
    canvas.drawRRect(torso, body);
    canvas.drawRRect(torso, outline);

    final head = Rect.fromLTWH(
      size.width * 0.28,
      size.height * 0.12,
      size.width * 0.36,
      size.height * 0.30,
    );
    canvas.drawOval(head, body);
    canvas.drawOval(head, outline);

    final face = Rect.fromLTWH(
      size.width * 0.36,
      size.height * 0.20,
      size.width * 0.20,
      size.height * 0.16,
    );
    canvas.drawOval(face, Paint()..color = const Color(0xFFA8D0EC));

    final eye = Paint()..color = const Color(0xFF102335);
    canvas.drawCircle(Offset(size.width * 0.43, size.height * 0.26), 2.5, eye);
    canvas.drawCircle(Offset(size.width * 0.53, size.height * 0.26), 2.5, eye);

    final smile = Path()
      ..moveTo(size.width * 0.42, size.height * 0.31)
      ..quadraticBezierTo(size.width * 0.49, size.height * 0.33,
          size.width * 0.56, size.height * 0.31);
    canvas.drawPath(
      smile,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = const Color(0xFF245C87),
    );

    final leftLeg = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.24, size.height * 0.74, size.width * 0.15,
          size.height * 0.22),
      const Radius.circular(20),
    );
    final rightLeg = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.56, size.height * 0.74, size.width * 0.15,
          size.height * 0.22),
      const Radius.circular(20),
    );
    canvas.drawRRect(leftLeg, body);
    canvas.drawRRect(rightLeg, body);
    canvas.drawRRect(leftLeg, outline);
    canvas.drawRRect(rightLeg, outline);

    final t = Curves.easeOut.transform(swingProgress);
    final armY = _lerp(size.height * 0.48, size.height * 0.44, t);
    final arm = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.18, armY, size.width * 0.46, size.height * 0.15),
      const Radius.circular(20),
    );
    canvas.drawRRect(arm, body);
    canvas.drawRRect(arm, outline);

    final pivot = Offset(size.width * 0.58, size.height * 0.57);
    final angle = _lerp(-1.0, 0.2, t);
    canvas.save();
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(angle);
    final batRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-6, -98, 16, 124),
      const Radius.circular(10),
    );
    canvas.drawRRect(batRect, Paint()..color = const Color(0xFF9B6338));
    canvas.drawRRect(
      batRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = const Color(0xFF6E3F1B),
    );
    canvas.restore();

    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.23,
        size.height * 0.94,
        size.width * 0.2,
        size.height * 0.08,
      ),
      Paint()..color = const Color(0xFF244768),
    );
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.53,
        size.height * 0.94,
        size.width * 0.2,
        size.height * 0.08,
      ),
      Paint()..color = const Color(0xFF244768),
    );
  }

  double _lerp(double a, double b, double t) => a + ((b - a) * t);

  @override
  bool shouldRepaint(covariant YetiPainter oldDelegate) {
    return oldDelegate.swingProgress != swingProgress;
  }
}

class PenguinPainter extends CustomPainter {
  const PenguinPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final body = Paint()..color = const Color(0xFF1A2434);
    final belly = Paint()..color = const Color(0xFFF7FCFF);
    final beak = Paint()..color = const Color(0xFFF3A63A);

    final main = Rect.fromLTWH(
      size.width * 0.18,
      size.height * 0.16,
      size.width * 0.62,
      size.height * 0.70,
    );
    canvas.drawOval(main, body);
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.34,
        size.height * 0.34,
        size.width * 0.34,
        size.height * 0.42,
      ),
      belly,
    );

    final beakPath = Path()
      ..moveTo(size.width * 0.69, size.height * 0.42)
      ..lineTo(size.width * 0.92, size.height * 0.49)
      ..lineTo(size.width * 0.70, size.height * 0.54)
      ..close();
    canvas.drawPath(beakPath, beak);

    canvas.drawCircle(
      Offset(size.width * 0.60, size.height * 0.34),
      size.width * 0.05,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(size.width * 0.61, size.height * 0.35),
      size.width * 0.02,
      Paint()..color = const Color(0xFF0B1522),
    );

    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.30,
        size.height * 0.80,
        size.width * 0.16,
        size.height * 0.09,
      ),
      beak,
    );
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.49,
        size.height * 0.80,
        size.width * 0.16,
        size.height * 0.09,
      ),
      beak,
    );

    canvas.drawOval(
      main,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = const Color(0xFF0F1E2D),
    );
  }

  @override
  bool shouldRepaint(covariant PenguinPainter oldDelegate) => false;
}

class PineTreePainter extends CustomPainter {
  const PineTreePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final trunk = Rect.fromLTWH(
      size.width * 0.44,
      size.height * 0.78,
      size.width * 0.12,
      size.height * 0.20,
    );
    canvas.drawRect(trunk, Paint()..color = const Color(0xFF5B4432));

    final green = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF2E4D47),
          Color(0xFF1A2D2A),
        ],
      ).createShader(Offset.zero & size);

    void layer(double y, double w, double h) {
      final path = Path()
        ..moveTo(size.width * 0.5, y)
        ..lineTo(size.width * 0.5 - w / 2, y + h)
        ..lineTo(size.width * 0.5 + w / 2, y + h)
        ..close();
      canvas.drawPath(path, green);
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1
          ..color = const Color(0xFF1A2D2A),
      );
    }

    layer(size.height * 0.14, size.width * 0.60, size.height * 0.34);
    layer(size.height * 0.33, size.width * 0.76, size.height * 0.36);
    layer(size.height * 0.53, size.width * 0.88, size.height * 0.34);

    final snow = Paint()..color = const Color(0xFFEFF7FD);
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.33,
        size.height * 0.27,
        size.width * 0.34,
        size.height * 0.08,
      ),
      snow,
    );
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.26,
        size.height * 0.48,
        size.width * 0.46,
        size.height * 0.08,
      ),
      snow,
    );
  }

  @override
  bool shouldRepaint(covariant PineTreePainter oldDelegate) => false;
}

class IceScoreSignPainter extends CustomPainter {
  const IceScoreSignPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final board = RRect.fromRectAndRadius(
      Rect.fromLTWH(10, 10, size.width - 20, size.height - 20),
      const Radius.circular(10),
    );
    canvas.drawRRect(
      board,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFE7F9FF),
            Color(0xFFC5E9F9),
            Color(0xFFA9D9F0),
          ],
        ).createShader(Offset.zero & size),
    );
    canvas.drawRRect(
      board,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF7EB6D4),
    );

    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.48, size.height - 16, 6, 16),
      Paint()..color = const Color(0xFFB8DCEC),
    );

    canvas.drawOval(
      Rect.fromLTWH(18, size.height - 14, size.width - 36, 10),
      Paint()..color = const Color(0x55273F54),
    );
  }

  @override
  bool shouldRepaint(covariant IceScoreSignPainter oldDelegate) => false;
}

class IceRockPainter extends CustomPainter {
  const IceRockPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rock = Path()
      ..moveTo(size.width * 0.02, size.height * 0.74)
      ..lineTo(size.width * 0.18, size.height * 0.22)
      ..lineTo(size.width * 0.62, size.height * 0.08)
      ..lineTo(size.width * 0.92, size.height * 0.36)
      ..lineTo(size.width * 0.98, size.height * 0.78)
      ..close();

    canvas.drawPath(
      rock,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFDCE6EE),
            Color(0xFFAAB8C8),
            Color(0xFF7A889A),
          ],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      rock,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = const Color(0xFF4F5E72),
    );
  }

  @override
  bool shouldRepaint(covariant IceRockPainter oldDelegate) => false;
}
