import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import '../cartoon_assets.dart';
import '../manga_game.dart';
import '../../ui/comic_theme.dart';

/// Floating Manga Onomatopoeia (e.g. BAM!, SLASH!, DODODO, ゴゴゴ)
class MangaTextEffect extends PositionComponent {
  final String text;
  final Color fillColor;
  final Color strokeColor;
  final double maxLifetime;
  final double initialScale;
  final double targetScale;
  final double rotationAngle;

  double _timer = 0.0;
  late final TextPainter _fillPainter;
  late final TextPainter _strokePainter;

  MangaTextEffect({
    required Vector2 position,
    required this.text,
    this.fillColor = ComicTheme.comicYellow,
    this.strokeColor = ComicTheme.inkBlack,
    this.maxLifetime = 0.65,
    this.initialScale = 0.4,
    this.targetScale = 1.25,
    double? rotation,
  })  : rotationAngle = rotation ?? ((Random().nextDouble() - 0.5) * 0.35),
        super(position: position, anchor: Anchor.center) {
    priority = 1000;
  }

  @override
  Future<void> onLoad() async {
    final textSpanFill = TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: 'Bangers',
        fontSize: 32,
        fontWeight: FontWeight.w900,
        color: fillColor,
        letterSpacing: 2.0,
      ),
    );

    final textSpanStroke = TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: 'Bangers',
        fontSize: 32,
        fontWeight: FontWeight.w900,
        letterSpacing: 2.0,
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6.0
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = strokeColor,
      ),
    );

    _fillPainter = TextPainter(
      text: textSpanFill,
      textDirection: TextDirection.ltr,
    )..layout();

    _strokePainter = TextPainter(
      text: textSpanStroke,
      textDirection: TextDirection.ltr,
    )..layout();

    size = Vector2(_fillPainter.width, _fillPainter.height);
    angle = rotationAngle;
    scale = Vector2.all(initialScale);
    await super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;

    final progress = (_timer / maxLifetime).clamp(0.0, 1.0);

    final currentScale = progress < 0.25
        ? initialScale + (targetScale - initialScale) * (progress / 0.25)
        : targetScale * (1.0 - (progress - 0.25) * 0.3);

    scale = Vector2.all(currentScale);
    position.y -= 35 * dt;

    if (progress >= 1.0) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    // Fast direct painting without canvas.saveLayer(null, ...)
    // Eliminates full-screen offscreen FBO allocation on Mali (MediaTek), Adreno (Snapdragon), and Web GPUs!
    canvas.save();
    canvas.translate(-size.x / 2, -size.y / 2);

    _strokePainter.paint(canvas, Offset.zero);
    _fillPainter.paint(canvas, Offset.zero);

    canvas.restore();
  }
}

/// 2D Cartoon Animated Slash Arc Effect
class SlashArcEffect extends PositionComponent
    with HasGameReference<MangaGame> {
  final double maxLifetime;
  final bool slashFlipped;
  final Color slashColor;
  final double radius;

  double _timer = 0.0;
  late final SpriteAnimationTicker _ticker;

  SlashArcEffect({
    required Vector2 position,
    this.maxLifetime = 0.22,
    this.slashFlipped = false,
    this.slashColor = Colors.white,
    this.radius = 45.0,
  }) : super(position: position, anchor: Anchor.center) {
    priority = 900;
  }

  @override
  Future<void> onLoad() async {
    String sheet = 'skills/slash_arc_yellow.png';
    if (slashColor == ComicTheme.energyCyan) {
      sheet = 'skills/slash_arc_cyan.png';
    } else if (slashColor == ComicTheme.actionRed) {
      sheet = 'skills/slash_arc_red.png';
    } else if (slashColor == ComicTheme.darkPurple) {
      sheet = 'skills/slash_arc_purple.png';
    }

    _ticker = CartoonAssets.animation(
      game.images,
      sheet,
      frames: 5,
      textureSize: Vector2(160, 160),
      stepTime: maxLifetime / 5.0,
      loop: false,
    ).createTicker();
    await super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;
    _ticker.update(dt);
    if (_timer >= maxLifetime) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final sprite = _ticker.getSprite();
    final drawSize = radius * 2.1;

    canvas.save();
    if (slashFlipped) {
      canvas.scale(-1, 1);
    }
    sprite.render(
      canvas,
      position: Vector2(-drawSize / 2, -drawSize / 2),
      size: Vector2.all(drawSize),
    );
    canvas.restore();
  }
}

/// 2D Cartoon Animated Dust / Smoke Cloud Puff
class MangaDustEffect extends PositionComponent
    with HasGameReference<MangaGame> {
  final double maxLifetime;
  final Color dustColor;
  double _timer = 0.0;
  late final SpriteAnimationTicker _ticker;

  MangaDustEffect({
    required Vector2 position,
    this.maxLifetime = 0.36,
    this.dustColor = ComicTheme.paperWhite,
  }) : super(position: position, anchor: Anchor.bottomCenter) {
    priority = 800;
  }

  @override
  Future<void> onLoad() async {
    _ticker = CartoonAssets.animation(
      game.images,
      'skills/vfx_dust_puff.png',
      frames: 6,
      textureSize: Vector2(120, 90),
      stepTime: maxLifetime / 6.0,
      loop: false,
    ).createTicker();
    await super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;
    _ticker.update(dt);
    if (_timer >= maxLifetime) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final sprite = _ticker.getSprite();
    sprite.render(
      canvas,
      position: Vector2(-36, -48),
      size: Vector2(72, 54),
    );
  }
}

/// Dynamic Speed Line Streaks Component
class SpeedLineStreakComponent extends PositionComponent {
  final double duration;
  final Vector2 direction;
  final Color color;
  double _timer = 0.0;
  final List<double> _yOffsets = [];
  final List<double> _lengths = [];

  SpeedLineStreakComponent({
    required Vector2 position,
    required Vector2 size,
    required this.direction,
    this.duration = 0.25,
    this.color = ComicTheme.energyCyan,
  }) : super(position: position, size: size) {
    priority = 850;
    final rand = Random();
    for (int i = 0; i < 8; i++) {
      _yOffsets.add(rand.nextDouble() * size.y);
      _lengths.add(rand.nextDouble() * 40 + 20);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;
    if (_timer >= duration) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final progress = (_timer / duration).clamp(0.0, 1.0);
    final alpha = (1.0 - progress).clamp(0.0, 1.0);

    final outlinePaint = Paint()
      ..color = ComicTheme.inkBlack.withValues(alpha: alpha)
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;

    final paint = Paint()
      ..color = color.withValues(alpha: alpha)
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < _yOffsets.length; i++) {
      final startX = size.x * (direction.x > 0 ? (1.0 - progress) : progress);
      final y = _yOffsets[i];
      final length = _lengths[i];
      final p1 = Offset(startX, y);
      final p2 = Offset(startX + (direction.x > 0 ? -length : length), y);
      canvas.drawLine(p1, p2, outlinePaint);
      canvas.drawLine(p1, p2, paint);
    }
  }
}

/// Smash Bros-style Directional Blast Zone K.O. Pillar when a fighter falls into the void
class SmashRingOutBlastEffect extends PositionComponent {
  final Color playerColor;
  final double maxLifetime;
  final double tiltAngle;
  double _timer = 0.0;
  final List<_BlastSpark> _sparks = [];

  SmashRingOutBlastEffect({
    required Vector2 position,
    required this.playerColor,
    this.maxLifetime = 0.82,
    double arenaCenterX = 600.0,
  })  : tiltAngle = ((arenaCenterX - position.x) * 0.00055).clamp(-0.28, 0.28),
        super(position: position, anchor: Anchor.bottomCenter) {
    priority = 980;
    final rand = Random();
    for (int i = 0; i < 20; i++) {
      final spread = (rand.nextDouble() - 0.5) * 1.1;
      final speed = 260.0 + rand.nextDouble() * 420.0;
      _sparks.add(_BlastSpark(
        vx: sin(spread) * speed * 0.55,
        vy: -cos(spread).abs() * speed,
        radius: 4.0 + rand.nextDouble() * 6.5,
        isGold: i.isEven,
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;
    if (_timer >= maxLifetime) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final t = (_timer / maxLifetime).clamp(0.0, 1.0);
    final fade = (1.0 - Curves.easeInCubic.transform(t)).clamp(0.0, 1.0);
    final surge = Curves.easeOutExpo.transform((t * 2.2).clamp(0.0, 1.0));
    final beamHeight = 420.0 * surge;
    final baseHalfW = 28.0 * (1.0 - t * 0.45);
    final topHalfW = (92.0 + 48.0 * surge) * (1.0 - t * 0.55);

    canvas.save();
    canvas.rotate(tiltAngle);

    // 1. Outer Manga Plasma Cone
    final beamPath = Path()
      ..moveTo(-baseHalfW, 18)
      ..lineTo(-topHalfW, -beamHeight)
      ..lineTo(topHalfW, -beamHeight)
      ..lineTo(baseHalfW, 18)
      ..close();

    final borderPaint = Paint()
      ..color = ComicTheme.inkBlack.withValues(alpha: fade)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeJoin = StrokeJoin.round;

    final outerPaint = Paint()
      ..color = playerColor.withValues(alpha: (fade * 0.85).clamp(0.0, 1.0))
      ..style = PaintingStyle.fill;

    canvas.drawPath(beamPath, outerPaint);
    canvas.drawPath(beamPath, borderPaint);

    // 2. Inner High-Voltage Gold & White Core Beam
    final coreHalfBase = baseHalfW * 0.52;
    final coreHalfTop = topHalfW * 0.46;
    final corePath = Path()
      ..moveTo(-coreHalfBase, 18)
      ..lineTo(-coreHalfTop, -beamHeight * 0.96)
      ..lineTo(coreHalfTop, -beamHeight * 0.96)
      ..lineTo(coreHalfBase, 18)
      ..close();

    final goldPaint = Paint()
      ..color = ComicTheme.comicYellow.withValues(alpha: fade)
      ..style = PaintingStyle.fill;
    canvas.drawPath(corePath, goldPaint);

    final whiteCorePath = Path()
      ..moveTo(-coreHalfBase * 0.45, 18)
      ..lineTo(-coreHalfTop * 0.35, -beamHeight * 0.88)
      ..lineTo(coreHalfTop * 0.35, -beamHeight * 0.88)
      ..lineTo(coreHalfBase * 0.45, 18)
      ..close();
    canvas.drawPath(
      whiteCorePath,
      Paint()..color = Colors.white.withValues(alpha: fade),
    );

    // 3. Expanding Blast Zone Shockwave Rings at Bottom Edge
    final ringRadius = 32.0 + 135.0 * Curves.easeOutQuad.transform(t);
    final ringRect = Rect.fromCenter(
      center: const Offset(0, 0),
      width: ringRadius * 2.2,
      height: ringRadius * 0.65,
    );
    canvas.drawOval(
      ringRect,
      Paint()
        ..color = ComicTheme.inkBlack.withValues(alpha: fade)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7.0,
    );
    canvas.drawOval(
      ringRect,
      Paint()
        ..color = ComicTheme.comicYellow.withValues(alpha: fade)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5,
    );

    // 4. Exploding Manga Sparks & Starburst Shards
    final sparkStroke = Paint()
      ..color = ComicTheme.inkBlack.withValues(alpha: fade)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    for (final s in _sparks) {
      final sx = s.vx * _timer;
      final sy = s.vy * _timer + 180.0 * _timer * _timer;
      final r = s.radius * (1.0 - t * 0.65).clamp(0.2, 1.0);
      final fill = Paint()
        ..color = (s.isGold ? ComicTheme.comicYellow : playerColor)
            .withValues(alpha: fade);
      canvas.drawCircle(Offset(sx, sy), r, fill);
      canvas.drawCircle(Offset(sx, sy), r, sparkStroke);
    }

    canvas.restore();
  }
}

class _BlastSpark {
  final double vx;
  final double vy;
  final double radius;
  final bool isGold;

  const _BlastSpark({
    required this.vx,
    required this.vy,
    required this.radius,
    required this.isGold,
  });
}

/// Full-stage anime "Dimensional Blade Flurry" (Ougi) visual effect around Kaito
class OugiCelestialFlurryEffect extends PositionComponent {
  final double maxLifetime;
  final int facingDirection;
  double _timer = 0.0;
  final List<_OugiCutLine> _cuts = [];
  final List<_BlastSpark> _sparks = [];

  OugiCelestialFlurryEffect({
    required Vector2 position,
    this.facingDirection = 1,
    this.maxLifetime = 0.72,
  }) : super(position: position, anchor: Anchor.center) {
    priority = 965;
    final rand = Random(42);
    final palette = [
      ComicTheme.energyCyan,
      ComicTheme.comicYellow,
      ComicTheme.actionRed,
      Colors.white,
    ];
    for (int i = 0; i < 14; i++) {
      final angle = (i * 0.45) + (rand.nextDouble() - 0.5) * 0.35;
      final cx = (rand.nextDouble() - 0.45) * 340.0 * facingDirection;
      final cy = (rand.nextDouble() - 0.5) * 150.0;
      final halfLen = 95.0 + rand.nextDouble() * 115.0;
      _cuts.add(_OugiCutLine(
        cx: cx,
        cy: cy,
        cosA: cos(angle),
        sinA: sin(angle),
        halfLen: halfLen,
        startDelay: (i / 14.0) * 0.34,
        color: palette[i % palette.length],
      ));
    }
    for (int i = 0; i < 24; i++) {
      final a = (i / 24.0) * pi * 2;
      final speed = 180.0 + (i % 5) * 65.0;
      _sparks.add(_BlastSpark(
        vx: cos(a) * speed * 1.35,
        vy: sin(a) * speed * 0.75 - 40.0,
        radius: 3.5 + (i % 3) * 2.0,
        isGold: i.isEven,
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;
    if (_timer >= maxLifetime) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final t = (_timer / maxLifetime).clamp(0.0, 1.0);
    final fade = (1.0 - Curves.easeInCubic.transform(t)).clamp(0.0, 1.0);
    final domeScale = Curves.easeOutQuart.transform((t * 1.45).clamp(0.0, 1.0));

    // 1. Expanding Celestial Spirit Dome & Twin Shockwave Rings
    final domeW = 540.0 * domeScale;
    final domeH = 220.0 * domeScale;
    final domeRect =
        Rect.fromCenter(center: Offset.zero, width: domeW, height: domeH);

    canvas.drawOval(
      domeRect,
      Paint()
        ..color = ComicTheme.energyCyan.withValues(alpha: fade * 0.16)
        ..style = PaintingStyle.fill,
    );
    canvas.drawOval(
      domeRect,
      Paint()
        ..color = ComicTheme.inkBlack.withValues(alpha: fade * 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0,
    );
    canvas.drawOval(
      domeRect,
      Paint()
        ..color = ComicTheme.comicYellow.withValues(alpha: fade)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0,
    );

    final innerRect = Rect.fromCenter(
      center: Offset.zero,
      width: domeW * 0.68,
      height: domeH * 0.68,
    );
    canvas.drawOval(
      innerRect,
      Paint()
        ..color = ComicTheme.energyCyan.withValues(alpha: fade * 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // 2. Criss-Crossing Dimensional Katana Judgment Cuts
    for (final c in _cuts) {
      final localT = ((_timer - c.startDelay) / 0.36).clamp(0.0, 1.0);
      if (localT <= 0.0 || localT >= 1.0) continue;
      final cutAlpha = (1.0 - localT) * fade;
      final reach = Curves.easeOutExpo.transform((localT * 2.2).clamp(0.0, 1.0));
      final len = c.halfLen * reach;
      final p1 = Offset(c.cx - c.cosA * len, c.cy - c.sinA * len);
      final p2 = Offset(c.cx + c.cosA * len, c.cy + c.sinA * len);
      final thickness = (7.5 * (1.0 - localT * 0.65)).clamp(1.8, 8.0);

      // Ink black comic outline
      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..color = ComicTheme.inkBlack.withValues(alpha: cutAlpha)
          ..strokeWidth = thickness + 4.5
          ..strokeCap = StrokeCap.round,
      );
      // Colored blade energy
      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..color = c.color.withValues(alpha: cutAlpha)
          ..strokeWidth = thickness
          ..strokeCap = StrokeCap.round,
      );
      // White-hot katana core
      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..color = Colors.white.withValues(alpha: cutAlpha)
          ..strokeWidth = (thickness * 0.42).clamp(1.0, 3.5)
          ..strokeCap = StrokeCap.round,
      );
    }

    // 3. Radiating Golden & Cyan Spirit Sparks
    final sparkBorder = Paint()
      ..color = ComicTheme.inkBlack.withValues(alpha: fade)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (final s in _sparks) {
      final sx = s.vx * _timer;
      final sy = s.vy * _timer;
      final r = s.radius * (1.0 - t * 0.55).clamp(0.25, 1.0);
      final fill = Paint()
        ..color = (s.isGold ? ComicTheme.comicYellow : ComicTheme.energyCyan)
            .withValues(alpha: fade);
      canvas.drawCircle(Offset(sx, sy), r, fill);
      canvas.drawCircle(Offset(sx, sy), r, sparkBorder);
    }
  }
}

class _OugiCutLine {
  final double cx;
  final double cy;
  final double cosA;
  final double sinA;
  final double halfLen;
  final double startDelay;
  final Color color;

  const _OugiCutLine({
    required this.cx,
    required this.cy,
    required this.cosA,
    required this.sinA,
    required this.halfLen,
    required this.startDelay,
    required this.color,
  });
}
