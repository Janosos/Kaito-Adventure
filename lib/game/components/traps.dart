import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import '../cartoon_assets.dart';
import '../manga_game.dart';
import '../../ui/comic_theme.dart';
import 'manga_effects.dart';

/// 2D Cartoon Metallic Spikes Trap
class SpikeTrap extends PositionComponent
    with CollisionCallbacks, HasGameReference<MangaGame> {
  final int spikeCount;
  final double spikeHeight;
  late final Sprite _spikePairSprite;

  SpikeTrap({
    required Vector2 position,
    this.spikeCount = 3,
    this.spikeHeight = 24.0,
  }) : super(
          position: position,
          size: Vector2(spikeCount * 16.0, spikeHeight),
          anchor: Anchor.bottomLeft,
        ) {
    priority = 510;
  }

  @override
  Future<void> onLoad() async {
    _spikePairSprite =
        CartoonAssets.sprite(game.images, 'environment/trap_spikes.png');
    await super.onLoad();
    add(RectangleHitbox(collisionType: CollisionType.passive));
  }

  @override
  void render(Canvas canvas) {
    if (!game.isInView(position.x + size.x * 0.5, size.x * 0.5 + 600.0)) {
      return;
    }
    final pairWidth = (size.x / spikeCount) * 2;
    for (double x = 0; x < size.x; x += pairWidth) {
      _spikePairSprite.render(
        canvas,
        position: Vector2(x, 0),
        size: Vector2(pairWidth, size.y),
      );
    }
  }
}

/// 2D Cartoon Animated Rotating Shuriken Saw Blade Hazard
class InkSawBlade extends PositionComponent
    with CollisionCallbacks, HasGameReference<MangaGame> {
  final Vector2? patrolOffset;
  final double patrolSpeed;
  final double radius;

  Vector2 _initialPos = Vector2.zero();
  double _timer = 0.0;
  double _rotation = 0.0;
  late final SpriteAnimationTicker _ticker;

  InkSawBlade({
    required Vector2 position,
    this.radius = 26.0,
    this.patrolOffset,
    this.patrolSpeed = 2.0,
  }) : super(
          position: position,
          size: Vector2.all(radius * 2),
          anchor: Anchor.center,
        ) {
    priority = 515;
  }

  @override
  Future<void> onLoad() async {
    _initialPos = position.clone();
    _ticker = CartoonAssets.animation(
      game.images,
      'environment/trap_saw.png',
      frames: 4,
      textureSize: Vector2(120, 120),
      stepTime: 0.05,
    ).createTicker();
    await super.onLoad();
    add(CircleHitbox(collisionType: CollisionType.passive));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isInView(position.x, 750.0)) return;
    _ticker.update(dt);
    _rotation += 8.0 * dt;

    if (patrolOffset != null) {
      _timer += dt * patrolSpeed;
      final factor = (sin(_timer) + 1.0) / 2.0;
      position = _initialPos + (patrolOffset! * factor);
    }
  }

  @override
  void render(Canvas canvas) {
    if (!game.isInView(position.x, 600.0)) return;
    final sprite = _ticker.getSprite();
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    canvas.rotate(_rotation);
    sprite.render(
      canvas,
      position: Vector2(-size.x / 2, -size.y / 2),
      size: size,
    );
    canvas.restore();
  }
}

/// LEVEL 2 SIGNATURE MECHANIC: Periodic Molten Magma Geyser Vent
class MagmaGeyserVent extends PositionComponent
    with HasGameReference<MangaGame> {
  final double cyclePeriod;
  final double activeDuration;
  final double geyserHeight;
  double _timer;
  late final SpriteAnimationTicker _flameTicker;

  static final Paint _ventBasePaint = Paint()..color = const Color(0xFF3E1010);
  static final Paint _lavaGlowPaint = Paint()..color = const Color(0xFFFF5722);
  static final Paint _warnPaint = Paint()..color = ComicTheme.comicYellow;
  static final Paint _borderPaint = Paint()
    ..color = ComicTheme.inkBlack
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.0;

  MagmaGeyserVent({
    required Vector2 position,
    this.cyclePeriod = 3.2,
    this.activeDuration = 1.15,
    this.geyserHeight = 155.0,
    double initialPhase = 0.0,
  })  : _timer = initialPhase,
        super(
          position: position,
          size: Vector2(54, 155),
          anchor: Anchor.bottomCenter,
        ) {
    priority = 518;
  }

  @override
  Future<void> onLoad() async {
    _flameTicker = CartoonAssets.animation(
      game.images,
      'skills/proj_flame_pillar.png',
      frames: 6,
      textureSize: Vector2(120, 320),
      stepTime: 0.06,
    ).createTicker();
    await super.onLoad();
  }

  bool get isErupting => (_timer % cyclePeriod) >= (cyclePeriod - activeDuration);
  bool get isWarning =>
      !isErupting && (_timer % cyclePeriod) >= (cyclePeriod - activeDuration - 0.65);

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;
    if (!game.isInView(position.x, 720.0)) return;

    if (isErupting) {
      _flameTicker.update(dt);
      final p = game.player;
      final dx = (p.position.x - position.x).abs();
      final dy = position.y - p.position.y;
      if (dx < 26 && dy >= -8 && dy <= geyserHeight - 12) {
        p.takeDamage(1);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (!game.isInView(position.x, 600.0)) return;

    // Draw Cartoon Volcanic Nozzle at the base
    final baseRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(2, size.y - 14, size.x - 4, 14),
      const Radius.circular(5),
    );
    canvas.drawRRect(baseRect, _ventBasePaint);
    canvas.drawRect(
      Rect.fromLTWH(8, size.y - 10, size.x - 16, 6),
      isWarning ? _warnPaint : _lavaGlowPaint,
    );
    canvas.drawRRect(baseRect, _borderPaint);

    if (isWarning) {
      final pulse = (sin(_timer * 24) + 1) * 0.5;
      canvas.drawCircle(
        Offset(size.x / 2, size.y - 24 - pulse * 8),
        7 + pulse * 4,
        _lavaGlowPaint,
      );
      canvas.drawCircle(
        Offset(size.x / 2, size.y - 24 - pulse * 8),
        7 + pulse * 4,
        _borderPaint,
      );
    } else if (isErupting) {
      final sprite = _flameTicker.getSprite();
      sprite.render(
        canvas,
        position: Vector2(-6, size.y - geyserHeight),
        size: Vector2(size.x + 12, geyserHeight),
      );
    }
  }
}

/// LEVEL 3 SIGNATURE MECHANIC: Toxic Bamboo Poison Spore Geyser
class PoisonSporeGeyser extends PositionComponent
    with HasGameReference<MangaGame> {
  final double cyclePeriod;
  final double activeDuration;
  final double cloudHeight;
  double _timer;

  static final Paint _podPaint = Paint()..color = const Color(0xFF1B5E20);
  static final Paint _sporeFill = Paint()..color = const Color(0xCC00E676);
  static final Paint _sporeCore = Paint()..color = const Color(0xFFB9F6CA);
  static final Paint _borderPaint = Paint()
    ..color = ComicTheme.inkBlack
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.8;

  PoisonSporeGeyser({
    required Vector2 position,
    this.cyclePeriod = 3.0,
    this.activeDuration = 1.2,
    this.cloudHeight = 115.0,
    double initialPhase = 0.0,
  })  : _timer = initialPhase,
        super(
          position: position,
          size: Vector2(48, 120),
          anchor: Anchor.bottomCenter,
        ) {
    priority = 518;
  }

  bool get isPuffing => (_timer % cyclePeriod) >= (cyclePeriod - activeDuration);

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;
    if (!game.isInView(position.x, 700.0)) return;

    if (isPuffing) {
      final p = game.player;
      final dx = (p.position.x - position.x).abs();
      final dy = position.y - p.position.y;
      if (dx < 26 && dy >= -6 && dy <= cloudHeight - 10) {
        p.takeDamage(1);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (!game.isInView(position.x, 580.0)) return;

    // Toxic Bamboo Pod Base
    final podRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(6, size.y - 16, size.x - 12, 16),
      const Radius.circular(6),
    );
    canvas.drawRRect(podRect, _podPaint);
    canvas.drawRRect(podRect, _borderPaint);

    if (isPuffing) {
      for (int i = 0; i < 4; i++) {
        final wave = sin(_timer * 10 + i * 1.4) * 6.0;
        final cy = size.y - 26.0 - i * 24.0;
        final r = 15.0 - i * 1.5;
        final center = Offset(size.x / 2 + wave, cy);
        canvas.drawCircle(center, r, _sporeFill);
        canvas.drawCircle(center, r * 0.45, _sporeCore);
        canvas.drawCircle(center, r, _borderPaint);
      }
    } else {
      // Bubbling spore indicator
      final r = 4.0 + sin(_timer * 8).abs() * 3.0;
      canvas.drawCircle(Offset(size.x / 2, size.y - 18), r, _sporeFill);
      canvas.drawCircle(Offset(size.x / 2, size.y - 18), r, _borderPaint);
    }
  }
}

/// LEVEL 4 SIGNATURE MECHANIC: Falling Ceiling Icicle Trap
class FallingIcicleTrap extends PositionComponent
    with HasGameReference<MangaGame> {
  Vector2 _startPos = Vector2.zero();
  int _state = 0; // 0 = hanging, 1 = shaking, 2 = falling, 3 = respawning
  double _timer = 0.0;
  double _fallSpeed = 0.0;
  final double maxFallY;

  static final Paint _iceFill = Paint()..color = const Color(0xFF40C4FF);
  static final Paint _iceHighlight = Paint()..color = const Color(0xFFE1F5FE);
  static final Paint _borderPaint = Paint()
    ..color = ComicTheme.inkBlack
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.8;

  FallingIcicleTrap({
    required Vector2 position,
    this.maxFallY = 485.0,
  }) : super(
          position: position,
          size: Vector2(28, 54),
          anchor: Anchor.topCenter,
        ) {
    priority = 522;
  }

  @override
  Future<void> onLoad() async {
    _startPos = position.clone();
    await super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isInView(position.x, 720.0)) return;

    final p = game.player;
    if (_state == 0) {
      // Trigger shake when player passes underneath
      if ((p.position.x - position.x).abs() < 95 &&
          p.position.y > position.y &&
          (p.position.y - position.y) < 380) {
        _state = 1;
        _timer = 0.36;
      }
    } else if (_state == 1) {
      _timer -= dt;
      if (_timer <= 0) {
        _state = 2;
        _fallSpeed = 120.0;
      }
    } else if (_state == 2) {
      _fallSpeed += 980.0 * dt;
      position.y += _fallSpeed * dt;

      // Hit check against player
      final dx = (p.position.x - position.x).abs();
      final icicleTipY = position.y + size.y;
      if (dx < 22 &&
          icicleTipY >= (p.position.y - p.size.y) &&
          position.y <= p.position.y) {
        p.takeDamage(1);
        _shatter();
        return;
      }

      if (icicleTipY >= maxFallY) {
        _shatter();
      }
    } else if (_state == 3) {
      _timer -= dt;
      if (_timer <= 0) {
        position = _startPos.clone();
        _state = 0;
        _fallSpeed = 0.0;
      }
    }
  }

  void _shatter() {
    _state = 3;
    _timer = 2.8;
    game.add(MangaDustEffect(position: Vector2(position.x, position.y + size.y)));
  }

  @override
  void render(Canvas canvas) {
    if (_state == 3 || !game.isInView(position.x, 580.0)) return;

    final shakeX = _state == 1 ? sin(_timer * 55) * 3.5 : 0.0;
    canvas.save();
    canvas.translate(shakeX, 0);

    final path = Path()
      ..moveTo(2, 0)
      ..lineTo(size.x - 2, 0)
      ..lineTo(size.x * 0.5, size.y)
      ..close();

    final innerPath = Path()
      ..moveTo(7, 4)
      ..lineTo(size.x * 0.52, 4)
      ..lineTo(size.x * 0.5, size.y - 10)
      ..close();

    canvas.drawPath(path, _iceFill);
    canvas.drawPath(innerPath, _iceHighlight);
    canvas.drawPath(path, _borderPaint);
    canvas.restore();
  }
}

/// LEVEL 4 SIGNATURE MECHANIC: Howling Blizzard Crosswind Zone
class BlizzardWindZone extends PositionComponent
    with HasGameReference<MangaGame> {
  final double windSpeedX; // Negative = headwind pushing left, Positive = tailwind
  double _animTimer = 0.0;

  static final Paint _streakPaint = Paint()
    ..color = const Color(0x9980D8FF)
    ..strokeWidth = 3.0
    ..strokeCap = StrokeCap.round;
  static final Paint _flakePaint = Paint()
    ..color = const Color(0xCCFFFFFF)
    ..style = PaintingStyle.fill;

  BlizzardWindZone({
    required Vector2 position,
    required Vector2 size,
    this.windSpeedX = -95.0,
  }) : super(
          position: position,
          size: size,
          anchor: Anchor.topLeft,
        ) {
    priority = 514;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isInView(position.x + size.x * 0.5, size.x * 0.5 + 650.0)) {
      return;
    }
    _animTimer += dt;

    final p = game.player;
    if (p.position.x >= position.x &&
        p.position.x <= position.x + size.x &&
        p.position.y >= position.y &&
        p.position.y <= position.y + size.y + 30) {
      p.externalWindX = windSpeedX;
    }
  }

  @override
  void render(Canvas canvas) {
    if (!game.isInView(position.x + size.x * 0.5, size.x * 0.5 + 600.0)) {
      return;
    }
    final dir = windSpeedX >= 0 ? 1.0 : -1.0;
    for (int i = 0; i < 6; i++) {
      final progress = ((_animTimer * 1.4 + i * 0.17) % 1.0);
      final lx = dir > 0 ? progress * size.x : (1.0 - progress) * size.x;
      final ly = (i + 0.5) * (size.y / 6.0);
      final endX = (lx + dir * 48.0).clamp(0.0, size.x);
      canvas.drawLine(Offset(lx, ly), Offset(endX, ly), _streakPaint);
      canvas.drawCircle(Offset(lx, ly - 6), 3.0, _flakePaint);
    }
  }
}
