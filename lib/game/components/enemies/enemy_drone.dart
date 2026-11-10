import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:manga_platformer/game/cartoon_assets.dart';
import 'package:manga_platformer/game/manga_game.dart';
import 'package:manga_platformer/ui/comic_theme.dart';
import '../manga_effects.dart';
import '../collectibles.dart';

class EnemyDrone extends PositionComponent
    with CollisionCallbacks, HasGameReference<MangaGame> {
  final double flyRange;
  final double flySpeed;
  double hp = 30.0;
  final double maxHp = 30.0;

  Vector2 _basePos = Vector2.zero();
  double _timer = 0.0;
  double _shootCooldown = 1.8;
  double _attackAnimTimer = 0.0;
  double _hitFlashTimer = 0.0;
  bool _isDying = false;

  late final SpriteAnimationTicker _flyTicker;
  late final SpriteAnimationTicker _attackTicker;

  EnemyDrone({
    required Vector2 position,
    this.flyRange = 90.0,
    this.flySpeed = 1.8,
  }) : super(
          position: position,
          size: Vector2(36, 32),
          anchor: Anchor.center,
        ) {
    priority = 710;
  }

  @override
  Future<void> onLoad() async {
    _basePos = position.clone();

    final imgs = game.images;
    _flyTicker = CartoonAssets.animation(
      imgs,
      'enemies/drone_fly.png',
      frames: 6,
      textureSize: Vector2(128, 128),
      stepTime: 0.07,
    ).createTicker();

    _attackTicker = CartoonAssets.animation(
      imgs,
      'enemies/drone_attack.png',
      frames: 4,
      textureSize: Vector2(128, 128),
      stepTime: 0.07,
    ).createTicker();

    await super.onLoad();
    add(CircleHitbox());
  }

  void takeDamage(
    double amount, {
    int knockbackDir = 0,
    double knockbackForce = 10.0,
  }) {
    if (_isDying) return;

    hp -= amount;
    _hitFlashTimer = 0.18;

    final pushDir =
        knockbackDir != 0 ? knockbackDir : (game.player.position.x < position.x ? 1 : -1);
    _basePos.x += pushDir * knockbackForce;
    position.x += pushDir * knockbackForce;

    game.add(MangaTextEffect(
      position: position.clone(),
      text: hp <= 0 ? 'KABOOM!!' : '-${amount.toInt()}',
      fillColor: ComicTheme.comicYellow,
    ));

    if (hp <= 0) {
      _die();
    }
  }

  void _die() {
    _isDying = true;
    game.addScore(200);
    game.addSpirit(14);
    game.add(MangaDustEffect(position: position.clone()));

    if (Random().nextDouble() < 0.45) {
      game.add(RamenBowl(position: position.clone()));
    }
    removeFromParent();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_isDying) return;
    if (!game.isInView(position.x, 760.0)) return;

    if (_hitFlashTimer > 0) _hitFlashTimer -= dt;
    if (_attackAnimTimer > 0) _attackAnimTimer -= dt;

    _timer += dt * flySpeed;
    position.x = _basePos.x + sin(_timer) * flyRange;
    position.y = _basePos.y + cos(_timer * 2.2) * 16;

    final player = game.player;
    final xDiff = (player.position.x - position.x).abs();
    final yDiff = player.position.y - position.y;

    _shootCooldown -= dt;
    if (xDiff < 90 && yDiff > 10 && yDiff < 240 && _shootCooldown <= 0) {
      _shootCooldown = 2.2;
      _attackAnimTimer = 0.35;
      _attackTicker.reset();
      game.add(DroneInkNeedle(
        position: Vector2(position.x, position.y + size.y / 2),
      ));
      game.add(MangaTextEffect(
        position: Vector2(position.x, position.y - 15),
        text: 'PEW!',
        fillColor: ComicTheme.actionRed,
        initialScale: 0.3,
        targetScale: 0.8,
      ));
    }

    if (_attackAnimTimer > 0) {
      _attackTicker.update(dt);
    } else {
      _flyTicker.update(dt);
    }
  }

  @override
  void render(Canvas canvas) {
    if (!game.isInView(position.x, 600.0)) return;
    final activeTicker = _attackAnimTimer > 0 ? _attackTicker : _flyTicker;
    final sprite = activeTicker.getSprite();

    const renderSize = 68.0;
    final overridePaint = _hitFlashTimer > 0
        ? (Paint()
          ..colorFilter = const ColorFilter.mode(
            Colors.white,
            BlendMode.srcATop,
          ))
        : null;

    sprite.render(
      canvas,
      position: Vector2((size.x - renderSize) / 2, (size.y - renderSize) / 2),
      size: Vector2.all(renderSize),
      overridePaint: overridePaint,
    );

    if (hp < maxHp) {
      final barWidth = size.x + 6;
      final hpRatio = (hp / maxHp).clamp(0.0, 1.0);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(-3, -18, barWidth, 5), const Radius.circular(2)),
        Paint()..color = ComicTheme.inkBlack,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(-3, -18, barWidth * hpRatio, 5),
            const Radius.circular(2)),
        Paint()..color = ComicTheme.actionRed,
      );
    }
  }
}

/// Needle projectile dropped by drone
class DroneInkNeedle extends PositionComponent
    with CollisionCallbacks, HasGameReference<MangaGame> {
  final double speed;
  double _lifeTimer = 0.0;
  late final SpriteAnimationTicker _ticker;

  DroneInkNeedle({
    required Vector2 position,
    this.speed = 230.0,
  }) : super(
          position: position,
          size: Vector2(14, 26),
          anchor: Anchor.topCenter,
        ) {
    priority = 720;
  }

  @override
  Future<void> onLoad() async {
    _ticker = CartoonAssets.animation(
      game.images,
      'skills/proj_drone_needle.png',
      frames: 4,
      textureSize: Vector2(48, 80),
      stepTime: 0.07,
    ).createTicker();
    await super.onLoad();
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    _ticker.update(dt);
    position.y += speed * dt;
    _lifeTimer += dt;
    if (_lifeTimer > 2.0) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other == game.player) {
      game.player.takeDamage(1);
      game.add(MangaTextEffect(
        position: position.clone(),
        text: 'OUCH!',
        fillColor: ComicTheme.actionRed,
      ));
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final sprite = _ticker.getSprite();
    sprite.render(
      canvas,
      position: Vector2(-4, -2),
      size: Vector2(22, 32),
    );
  }
}
