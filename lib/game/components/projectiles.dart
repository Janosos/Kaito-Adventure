import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import '../cartoon_assets.dart';
import '../manga_game.dart';
import '../../ui/comic_theme.dart';
import 'manga_effects.dart';
import 'enemies/enemy_grunt.dart';
import 'enemies/enemy_drone.dart';
import 'bosses/boss_base.dart';

/// Kunai thrown by the player
class InkKunai extends PositionComponent
    with CollisionCallbacks, HasGameReference<MangaGame> {
  final Vector2 velocity;
  final double damage;
  double _lifeTimer = 0.0;
  static const double maxLife = 1.6;
  late final SpriteAnimationTicker _ticker;

  InkKunai({
    required Vector2 position,
    required this.velocity,
    this.damage = 25.0,
  }) : super(
          position: position,
          size: Vector2(36, 18),
          anchor: Anchor.center,
        ) {
    priority = 850;
    angle = atan2(velocity.y, velocity.x);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox());
    _ticker = CartoonAssets.animation(
      game.images,
      'skills/proj_kunai.png',
      frames: 4,
      textureSize: Vector2(96, 48),
      stepTime: 0.06,
    ).createTicker();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _ticker.update(dt);
    position += velocity * dt;
    _lifeTimer += dt;

    if (_lifeTimer >= maxLife) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final sprite = _ticker.getSprite();
    sprite.render(
      canvas,
      position: Vector2.zero(),
      size: size,
    );
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is EnemyGrunt) {
      other.takeDamage(damage);
      _impact(other.position);
    } else if (other is EnemyDrone) {
      other.takeDamage(damage);
      _impact(other.position);
    } else if (other is BossBase) {
      other.takeDamage(damage);
      _impact(other.position);
    }
  }

  void _impact(Vector2 hitPos) {
    game.add(MangaTextEffect(
      position: hitPos.clone(),
      text: 'SHINK!',
      fillColor: ComicTheme.comicYellow,
    ));
    game.add(MangaDustEffect(position: hitPos.clone()));
    removeFromParent();
  }
}

/// Dark Blade Shockwave shot by Boss 1 (Kurokage)
class BossDarkSlashWave extends PositionComponent
    with CollisionCallbacks, HasGameReference<MangaGame> {
  final Vector2 velocity;
  final double damage;
  double _lifeTimer = 0.0;
  static const double maxLife = 2.5;
  late final SpriteAnimationTicker _ticker;

  BossDarkSlashWave({
    required Vector2 position,
    required this.velocity,
    this.damage = 1.0,
  }) : super(
          position: position,
          size: Vector2(44, 54),
          anchor: Anchor.center,
        ) {
    priority = 880;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox());
    _ticker = CartoonAssets.animation(
      game.images,
      'skills/proj_dark_wave.png',
      frames: 4,
      textureSize: Vector2(120, 140),
      stepTime: 0.07,
    ).createTicker();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _ticker.update(dt);
    position += velocity * dt;
    _lifeTimer += dt;
    if (_lifeTimer >= maxLife) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other == game.player) {
      game.player.takeDamage(damage.toInt());
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final direction = velocity.x >= 0 ? 1.0 : -1.0;
    final sprite = _ticker.getSprite();

    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    if (direction < 0) {
      canvas.scale(-1, 1);
    }
    sprite.render(
      canvas,
      position: Vector2(-size.x / 2, -size.y / 2),
      size: size,
    );
    canvas.restore();
  }
}

/// Fiery Ink Geyser / Pillar Trap & Boss Attack
class BossFlamePillar extends PositionComponent
    with CollisionCallbacks, HasGameReference<MangaGame> {
  final double eruptDelay;
  final double activeDuration;
  final double damage;

  double _timer = 0.0;
  bool isErupted = false;
  late final RectangleHitbox _hitbox;
  late final SpriteAnimationTicker _ticker;

  BossFlamePillar({
    required Vector2 position,
    this.eruptDelay = 0.75,
    this.activeDuration = 0.9,
    this.damage = 1.0,
  }) : super(
          position: position,
          size: Vector2(54, 160),
          anchor: Anchor.bottomCenter,
        ) {
    priority = 870;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _hitbox = RectangleHitbox()..collisionType = CollisionType.inactive;
    add(_hitbox);
    _ticker = CartoonAssets.animation(
      game.images,
      'skills/proj_flame_pillar.png',
      frames: 6,
      textureSize: Vector2(120, 320),
      stepTime: 0.06,
    ).createTicker();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;

    if (!isErupted && _timer >= eruptDelay) {
      isErupted = true;
      _hitbox.collisionType = CollisionType.active;
      game.add(MangaTextEffect(
        position: Vector2(position.x, position.y - size.y * 0.7),
        text: 'FWOOSH!',
        fillColor: ComicTheme.actionRed,
      ));
    }

    if (isErupted) {
      _ticker.update(dt);
      if (_timer >= (eruptDelay + activeDuration)) {
        removeFromParent();
      }
    }
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (isErupted && other == game.player) {
      game.player.takeDamage(damage.toInt());
    }
  }

  @override
  void render(Canvas canvas) {
    if (!isErupted) {
      final flash = (_timer * 12).toInt() % 2 == 0;
      final markPaint = Paint()
        ..color = flash ? ComicTheme.actionRed : ComicTheme.comicYellow
        ..style = PaintingStyle.fill;

      final groundRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.x / 2, size.y - 4),
          width: size.x * 1.1,
          height: 10,
        ),
        const Radius.circular(5),
      );
      canvas.drawRRect(groundRect, markPaint);
      canvas.drawRRect(
        groundRect,
        Paint()
          ..color = ComicTheme.inkBlack
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );

      final textSpan = TextSpan(
        text: '!',
        style: TextStyle(
          fontFamily: 'Bangers',
          fontSize: 34,
          fontWeight: FontWeight.bold,
          color: flash ? ComicTheme.actionRed : ComicTheme.comicYellow,
          shadows: const [Shadow(offset: Offset(2, 2), color: Colors.black)],
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset((size.x - textPainter.width) / 2, size.y - 54),
      );
    } else {
      final progress =
          ((_timer - eruptDelay) / activeDuration).clamp(0.0, 1.0);
      final heightFactor = progress < 0.2 ? (progress / 0.2) : 1.0;
      final currentHeight = size.y * heightFactor;

      final sprite = _ticker.getSprite();
      sprite.render(
        canvas,
        position: Vector2(-8, size.y - currentHeight),
        size: Vector2(size.x + 16, currentHeight),
      );
    }
  }
}

/// Dragon Shogun Energy Orb
class BossEnergyOrb extends PositionComponent
    with CollisionCallbacks, HasGameReference<MangaGame> {
  final Vector2 velocity;
  final double damage;
  double _lifeTimer = 0.0;
  static const double maxLife = 4.0;
  late final SpriteAnimationTicker _ticker;

  BossEnergyOrb({
    required Vector2 position,
    required this.velocity,
    this.damage = 1.0,
  }) : super(
          position: position,
          size: Vector2(34, 34),
          anchor: Anchor.center,
        ) {
    priority = 875;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());
    _ticker = CartoonAssets.animation(
      game.images,
      'skills/proj_energy_orb.png',
      frames: 6,
      textureSize: Vector2(96, 96),
      stepTime: 0.06,
    ).createTicker();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _ticker.update(dt);
    position += velocity * dt;
    _lifeTimer += dt;
    if (_lifeTimer >= maxLife) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other == game.player) {
      game.player.takeDamage(damage.toInt());
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final sprite = _ticker.getSprite();
    sprite.render(
      canvas,
      position: Vector2.zero(),
      size: size,
    );
  }
}
