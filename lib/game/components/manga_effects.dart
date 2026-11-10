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
