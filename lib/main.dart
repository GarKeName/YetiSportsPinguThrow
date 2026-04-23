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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0C6B93)),
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
              .clamp(0.72, 1.45);
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
                        _buildHitZone(),
                        _buildCliff(),
                        _buildYeti(),
                        if (_game.showPenguin) _buildPenguin(),
                      ],
                    ),
                  ),
                ),
              ),
              _buildTopHud(),
              _buildBottomPrompt(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGroundPlane() {
    return Positioned(
      left: -_game.cameraX - 300,
      right: -300,
      top: ArcticSluggerGame.groundY,
      bottom: 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: const Border(
            top: BorderSide(color: Color(0xFFDDF7FF), width: 2),
          ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFBEE8FB).withValues(alpha: 0.86),
              const Color(0xFF84C4E0).withValues(alpha: 0.94),
              const Color(0xFF4E8FB1),
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

    final posts = <Widget>[];

    for (int meter = minMeter; meter <= maxMeter + 100; meter += 50) {
      if (meter <= 0) {
        continue;
      }

      final x = meter * ArcticSluggerGame.pixelsPerMeter - _game.cameraX;
      final isMajor = meter % 100 == 0;
      final lineHeight = isMajor ? 82.0 : 52.0;

      posts.add(
        Positioned(
          left: x,
          top: ArcticSluggerGame.groundY - lineHeight,
          child: Column(
            children: [
              Container(
                width: isMajor ? 3 : 2,
                height: lineHeight,
                color: const Color(0xFFE5FAFF)
                    .withValues(alpha: isMajor ? 0.95 : 0.7),
              ),
              if (isMajor)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xAA0D405F),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF84D8F2)),
                  ),
                  child: Text(
                    '${meter}m',
                    style: const TextStyle(
                      color: Color(0xFFE8FBFF),
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
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

  Widget _buildHitZone() {
    return Positioned(
      left: _game.hitTargetX - _game.cameraX - 2,
      top: ArcticSluggerGame.groundY - 145,
      child: Column(
        children: [
          Container(
            width: 4,
            height: 122,
            decoration: BoxDecoration(
              color: const Color(0xFFFAF5A5).withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 5),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xAA112E3D),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFEFE077)),
            ),
            child: const Text(
              'HIT',
              style: TextStyle(
                color: Color(0xFFFFF3A8),
                fontWeight: FontWeight.w800,
                fontSize: 10,
                letterSpacing: 0.6,
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
        child: CustomPaint(
          painter: CliffPainter(),
        ),
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
    const diameter = ArcticSluggerGame.penguinRadius * 2.4;

    return Positioned(
      left: _game.penguinX - _game.cameraX - (diameter / 2),
      top: _game.penguinY - (diameter / 2),
      child: Transform.rotate(
        angle: _game.penguinRotation,
        child: const SizedBox(
          width: diameter,
          height: diameter,
          child: CustomPaint(
            painter: PenguinPainter(),
          ),
        ),
      ),
    );
  }

  Widget _buildTopHud() {
    final score = _game.currentDistanceMeters;
    final best = _game.bestDistanceMeters;

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: const Color(0xAA0A2D42),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF8FD8F2), width: 1.3),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _statChip('DIST', '${score.toStringAsFixed(1)} m'),
              const SizedBox(width: 8),
              _statChip('BEST', '${best.toStringAsFixed(1)} m'),
              const SizedBox(width: 8),
              _statChip('WIND', _game.windLabel),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statChip(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF0E4564),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3FA0C8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF9BE8FF),
              fontWeight: FontWeight.w700,
              fontSize: 10,
              letterSpacing: 0.6,
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

  Widget _buildBottomPrompt() {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: const EdgeInsets.fromLTRB(10, 10, 10, 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xB214354A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF8FD8F2)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _game.prompt,
                  style: const TextStyle(
                    color: Color(0xFFE3F7FF),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: const Text('Reset'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ArcticSluggerGame {
  ArcticSluggerGame() {
    forceReset();
  }

  static const double worldHeight = 520;
  static const double groundY = 392;
  static const double pixelsPerMeter = 12.5;

  static const double cliffWidth = 146;
  static const double cliffHeight = 188;
  static const double yetiWidth = 130;
  static const double yetiHeight = 156;
  static const double penguinRadius = 16;
  static const double swingDuration = 0.18;

  final _rng = math.Random();

  RoundPhase phase = RoundPhase.ready;

  double cliffX = 22;
  double cliffY = groundY - cliffHeight + 6;

  double yetiX = 120;
  double yetiY = groundY - yetiHeight;

  double penguinX = 0;
  double penguinY = 0;
  double penguinVx = 0;
  double penguinVy = 0;
  double penguinRotation = 0;

  double swingTimer = 0;
  double dropTimer = 0;
  double idleClock = 0;
  int bounceCount = 0;

  double cameraX = 0;
  double viewWorldWidth = 390;

  double launchX = 0;
  double currentDistanceMeters = 0;
  double bestDistanceMeters = 0;

  double windForce = 0;

  bool get showPenguin => true;

  double get perchX => cliffX + 44;
  double get perchY => cliffY - penguinRadius - 8;

  double get hitTargetX => yetiX + (yetiWidth * 0.62);
  double get hitTargetY => yetiY + (yetiHeight * 0.44);

  double get swingProgress {
    if (swingTimer <= 0) {
      return 0;
    }
    return (1 - (swingTimer / swingDuration)).clamp(0.0, 1.0);
  }

  String get windLabel {
    if (windForce.abs() < 7) {
      return 'Calm';
    }
    final kmh = (windForce / 8.4).round().abs();
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
    penguinRotation = -0.1;
    swingTimer = 0;
    dropTimer = 0;
    idleClock = 0;
    bounceCount = 0;
    launchX = hitTargetX;
    currentDistanceMeters = 0;
    windForce = (_rng.nextDouble() * 2 - 1) * 56;
  }

  void _startDrop() {
    phase = RoundPhase.dropping;
    dropTimer = 0;
    swingTimer = 0;
    bounceCount = 0;

    windForce = (_rng.nextDouble() * 2 - 1) * 64;

    penguinX = hitTargetX;
    penguinY = 50;
    penguinVx = 0;
    penguinVy = 0;
    penguinRotation = 0;

    launchX = penguinX;
    currentDistanceMeters = 0;
    cameraX = 0;
  }

  void _trySwing() {
    swingTimer = swingDuration;

    final xScore = (1 - ((penguinX - hitTargetX).abs() / 46)).clamp(0.0, 1.0);
    final yScore = (1 - ((penguinY - hitTargetY).abs() / 105)).clamp(0.0, 1.0);
    final quality = math.pow((xScore * 0.35 + yScore * 0.65), 1.05).toDouble();

    final angleDeg = _lerp(18, 47, quality);
    final speed = _lerp(280, 1360, quality);
    final angleRad = angleDeg * math.pi / 180;

    phase = RoundPhase.flying;

    penguinVx = speed * math.cos(angleRad);
    penguinVy = -speed * math.sin(angleRad);

    if (quality < 0.15) {
      penguinVx = _lerp(110, 320, quality * 4.5);
      penguinVy = -_lerp(80, 210, quality * 4.5);
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
    penguinY = perchY + (math.sin(idleClock * 2.2) * 2.3);
    penguinRotation = -0.08;
    _updateCamera(dt, fixed: true);
  }

  void _updateDrop(double dt) {
    dropTimer += dt;

    penguinVy += 1830 * dt;
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
    penguinVy += 1810 * dt;
    penguinVx += windForce * dt;

    final drag = math.pow(0.991, dt * 60).toDouble();
    penguinVx *= drag;

    penguinX += penguinVx * dt;
    penguinY += penguinVy * dt;
    penguinRotation += (penguinVx.sign * 5.2) * dt;

    if (penguinY >= groundY - penguinRadius) {
      penguinY = groundY - penguinRadius;

      if (bounceCount < 2 && penguinVy > 260) {
        bounceCount += 1;
        final damp = bounceCount == 1 ? 0.34 : 0.18;
        penguinVy = -penguinVy * damp;
        penguinVx *= 0.83;
      } else {
        penguinVy = 0;
        phase = RoundPhase.sliding;
      }
    }

    _updateCamera(dt);
  }

  void _updateSlide(double dt) {
    final friction = _lerp(175, 255, (windForce.abs() / 85).clamp(0.0, 1.0));

    penguinX += penguinVx * dt;
    penguinRotation += penguinVx.sign * 2.5 * dt;

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
    final follow = fixed ? 0.23 : 0.14;
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
          Color(0xFF0A72C8),
          Color(0xFF3FA6E3),
          Color(0xFF9BDDF5),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, sky);

    canvas.drawCircle(
      Offset(size.width * 0.79, size.height * 0.16),
      size.width * 0.06,
      Paint()..color = const Color(0x66F4FDFF),
    );

    _drawMountainLayer(
      canvas,
      size,
      color: const Color(0xFF74B6E7),
      snowColor: const Color(0xFFDFF5FF),
      baseY: size.height * 0.58,
      parallax: 0.17,
      peaks: const [
        _Peak(0.00, 0.30),
        _Peak(0.17, 0.24),
        _Peak(0.34, 0.32),
        _Peak(0.54, 0.22),
        _Peak(0.76, 0.29),
        _Peak(0.97, 0.21),
      ],
    );

    _drawMountainLayer(
      canvas,
      size,
      color: const Color(0xFF4E95CF),
      snowColor: const Color(0xFFF2FBFF),
      baseY: size.height * 0.68,
      parallax: 0.28,
      peaks: const [
        _Peak(0.02, 0.38),
        _Peak(0.23, 0.30),
        _Peak(0.45, 0.35),
        _Peak(0.66, 0.28),
        _Peak(0.86, 0.40),
      ],
    );

    final horizonIce = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xCCBEE8FB),
          Color(0xFF9ED3EA),
          Color(0xFF7BB6D3),
        ],
      ).createShader(
        Rect.fromLTWH(0, size.height * 0.72, size.width, size.height * 0.28),
      );

    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.72, size.width, size.height * 0.28),
      horizonIce,
    );

    final crackPaint = Paint()
      ..color = const Color(0xFF5EA0C3).withValues(alpha: 0.66)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < 12; i++) {
      final baseX =
          ((i * 180) - ((cameraX * worldScale * 0.76) % 180)) - 100;
      final path = Path()
        ..moveTo(baseX, size.height * 0.84)
        ..lineTo(baseX + 74, size.height * 0.80)
        ..lineTo(baseX + 154, size.height * 0.86)
        ..lineTo(baseX + 222, size.height * 0.82);
      canvas.drawPath(path, crackPaint);
    }
  }

  void _drawMountainLayer(
    Canvas canvas,
    Size size, {
    required Color color,
    required Color snowColor,
    required double baseY,
    required double parallax,
    required List<_Peak> peaks,
  }) {
    final shift = -(cameraX * worldScale * parallax) % size.width;

    for (double offset = shift - size.width; offset <= size.width; offset += size.width) {
      final body = Path()..moveTo(offset, size.height);
      final ridgePoints = <Offset>[];

      for (final peak in peaks) {
        final p = Offset(
          offset + (size.width * peak.xFactor),
          baseY - (size.height * peak.heightFactor),
        );
        ridgePoints.add(p);
        body.lineTo(p.dx, p.dy);
      }

      body
        ..lineTo(offset + size.width, size.height)
        ..close();

      canvas.drawPath(body, Paint()..color = color);

      final snow = Path();
      for (var i = 0; i < ridgePoints.length; i++) {
        final point = ridgePoints[i];
        final top = Offset(point.dx, point.dy + (size.height * 0.02));
        if (i == 0) {
          snow.moveTo(top.dx, top.dy);
        } else {
          snow.lineTo(top.dx, top.dy);
        }
      }
      snow
        ..lineTo(offset + size.width, baseY + (size.height * 0.01))
        ..lineTo(offset, baseY + (size.height * 0.01))
        ..close();

      canvas.drawPath(snow, Paint()..color = snowColor.withValues(alpha: 0.65));
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
    final iceBody = Path()
      ..moveTo(size.width * 0.08, size.height)
      ..lineTo(size.width * 0.15, size.height * 0.12)
      ..lineTo(size.width * 0.62, size.height * 0.06)
      ..lineTo(size.width * 0.96, size.height * 0.02)
      ..lineTo(size.width * 0.94, size.height * 0.22)
      ..lineTo(size.width * 0.86, size.height)
      ..close();

    final icePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF8CE6FF),
          Color(0xFF4DB7E2),
          Color(0xFF2C86B6),
        ],
      ).createShader(Offset.zero & size);

    canvas.drawPath(iceBody, icePaint);

    final snowCap = Path()
      ..moveTo(size.width * 0.1, size.height * 0.15)
      ..lineTo(size.width * 0.23, size.height * 0.06)
      ..lineTo(size.width * 0.54, size.height * 0.04)
      ..lineTo(size.width * 0.88, size.height * 0.03)
      ..lineTo(size.width * 0.94, size.height * 0.10)
      ..lineTo(size.width * 0.82, size.height * 0.14)
      ..lineTo(size.width * 0.56, size.height * 0.11)
      ..lineTo(size.width * 0.24, size.height * 0.12)
      ..close();

    canvas.drawPath(snowCap, Paint()..color = const Color(0xFFF4FCFF));

    final crack = Paint()
      ..color = const Color(0xFF2D7DAA).withValues(alpha: 0.8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(size.width * 0.28, size.height * 0.18),
      Offset(size.width * 0.22, size.height * 0.88),
      crack,
    );
    canvas.drawLine(
      Offset(size.width * 0.52, size.height * 0.14),
      Offset(size.width * 0.50, size.height * 0.92),
      crack,
    );
    canvas.drawLine(
      Offset(size.width * 0.74, size.height * 0.12),
      Offset(size.width * 0.80, size.height * 0.92),
      crack,
    );

    canvas.drawPath(
      iceBody,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF156087),
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
    final fur = Paint()..color = const Color(0xFFF4FCFF);
    final furShade = Paint()..color = const Color(0xFFD8EEFC);
    final skin = Paint()..color = const Color(0xFF81C6ED);
    final skinDark = Paint()..color = const Color(0xFF4EA2D4);
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = const Color(0xFF1D5E8D);

    final torso = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.2,
        size.height * 0.38,
        size.width * 0.58,
        size.height * 0.50,
      ),
      const Radius.circular(26),
    );
    canvas.drawRRect(torso, fur);

    final belly = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.31,
        size.height * 0.45,
        size.width * 0.35,
        size.height * 0.35,
      ),
      const Radius.circular(18),
    );
    canvas.drawRRect(belly, furShade);

    final head = Rect.fromLTWH(
      size.width * 0.29,
      size.height * 0.15,
      size.width * 0.38,
      size.height * 0.30,
    );
    canvas.drawOval(head, fur);

    final face = Rect.fromLTWH(
      size.width * 0.35,
      size.height * 0.21,
      size.width * 0.26,
      size.height * 0.19,
    );
    canvas.drawOval(face, skin);

    final leftLeg = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.24,
        size.height * 0.72,
        size.width * 0.16,
        size.height * 0.22,
      ),
      const Radius.circular(22),
    );
    final rightLeg = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.55,
        size.height * 0.72,
        size.width * 0.16,
        size.height * 0.22,
      ),
      const Radius.circular(22),
    );
    canvas.drawRRect(leftLeg, fur);
    canvas.drawRRect(rightLeg, fur);

    final leftFoot = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.20,
        size.height * 0.88,
        size.width * 0.22,
        size.height * 0.1,
      ),
      const Radius.circular(16),
    );
    final rightFoot = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.52,
        size.height * 0.88,
        size.width * 0.22,
        size.height * 0.1,
      ),
      const Radius.circular(16),
    );
    canvas.drawRRect(leftFoot, skinDark);
    canvas.drawRRect(rightFoot, skinDark);

    final t = Curves.easeOutCubic.transform(swingProgress.clamp(0.0, 1.0));

    final leftArm = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.13,
        _lerp(size.height * 0.51, size.height * 0.43, t),
        size.width * 0.23,
        size.height * 0.15,
      ),
      const Radius.circular(20),
    );
    final rightArm = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.55,
        _lerp(size.height * 0.48, size.height * 0.54, t),
        size.width * 0.25,
        size.height * 0.15,
      ),
      const Radius.circular(20),
    );
    canvas.drawRRect(leftArm, fur);
    canvas.drawRRect(rightArm, fur);

    final eyeWhite = Paint()..color = Colors.white;
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.40,
        size.height * 0.24,
        size.width * 0.06,
        size.height * 0.05,
      ),
      eyeWhite,
    );
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.52,
        size.height * 0.24,
        size.width * 0.06,
        size.height * 0.05,
      ),
      eyeWhite,
    );

    canvas.drawCircle(
      Offset(size.width * 0.435, size.height * 0.265),
      size.width * 0.012,
      Paint()..color = const Color(0xFF0B2B3E),
    );
    canvas.drawCircle(
      Offset(size.width * 0.555, size.height * 0.265),
      size.width * 0.012,
      Paint()..color = const Color(0xFF0B2B3E),
    );

    final mouthPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFF1D5E8D);
    final mouth = Path()
      ..moveTo(size.width * 0.44, size.height * 0.33)
      ..quadraticBezierTo(
        size.width * 0.49,
        size.height * 0.35,
        size.width * 0.56,
        size.height * 0.33,
      );
    canvas.drawPath(mouth, mouthPaint);

    final pivot = Offset(size.width * 0.58, size.height * 0.56);
    final batAngle = _lerp(-1.02, 0.28, t);

    canvas.save();
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(batAngle);

    final batRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-7, -96, 16, 122),
      const Radius.circular(10),
    );

    canvas.drawRRect(
      batRect,
      Paint()..color = const Color(0xFF996439),
    );
    canvas.drawRRect(
      batRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xFF6F441E),
    );

    canvas.drawCircle(
      const Offset(1, 29),
      7,
      Paint()..color = const Color(0xFF6F441E),
    );

    canvas.restore();

    canvas.drawRRect(torso, outline);
    canvas.drawOval(head, outline);
    canvas.drawRRect(leftLeg, outline);
    canvas.drawRRect(rightLeg, outline);
    canvas.drawRRect(leftArm, outline);
    canvas.drawRRect(rightArm, outline);
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
    final body = Paint()..color = const Color(0xFF1C2638);
    final belly = Paint()..color = const Color(0xFFF9FDFF);
    final wing = Paint()..color = const Color(0xFF131C2B);
    final orange = Paint()..color = const Color(0xFFF59A2F);

    final bodyRect = Rect.fromLTWH(
      size.width * 0.18,
      size.height * 0.15,
      size.width * 0.62,
      size.height * 0.72,
    );
    canvas.drawOval(bodyRect, body);

    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.32,
        size.height * 0.32,
        size.width * 0.38,
        size.height * 0.46,
      ),
      belly,
    );

    final leftWing = Path()
      ..moveTo(size.width * 0.25, size.height * 0.52)
      ..quadraticBezierTo(
        size.width * 0.02,
        size.height * 0.54,
        size.width * 0.19,
        size.height * 0.72,
      )
      ..close();
    canvas.drawPath(leftWing, wing);

    final rightWing = Path()
      ..moveTo(size.width * 0.74, size.height * 0.50)
      ..quadraticBezierTo(
        size.width * 0.97,
        size.height * 0.56,
        size.width * 0.76,
        size.height * 0.73,
      )
      ..close();
    canvas.drawPath(rightWing, wing);

    canvas.drawCircle(
      Offset(size.width * 0.60, size.height * 0.34),
      size.width * 0.05,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(size.width * 0.61, size.height * 0.35),
      size.width * 0.022,
      Paint()..color = const Color(0xFF0A1B2A),
    );

    final beak = Path()
      ..moveTo(size.width * 0.70, size.height * 0.42)
      ..lineTo(size.width * 0.93, size.height * 0.48)
      ..lineTo(size.width * 0.71, size.height * 0.53)
      ..close();
    canvas.drawPath(beak, orange);

    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.33,
        size.height * 0.80,
        size.width * 0.16,
        size.height * 0.09,
      ),
      orange,
    );
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.50,
        size.height * 0.80,
        size.width * 0.16,
        size.height * 0.09,
      ),
      orange,
    );

    canvas.drawOval(
      bodyRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = const Color(0xFF0F1E2D),
    );
  }

  @override
  bool shouldRepaint(covariant PenguinPainter oldDelegate) => false;
}

class _Peak {
  const _Peak(this.xFactor, this.heightFactor);

  final double xFactor;
  final double heightFactor;
}
