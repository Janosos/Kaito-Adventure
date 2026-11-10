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
import '../projectiles.dart';

/// Armored Oni Marksman that fires energy orbs horizontally at Kaito
class EnemyOniArcher extends PositionComponent
    with CollisionCallbacks, HasGameReference<MangaGame> {
  final double patrolRange;
  double maxHp;
  late double hp;

  double _startX = 0.0;
  int _facing = -1;
  double _shootCooldown = 2.0;
  double _shootAnimTimer = 0.0;
  double _hitFlashTimer = 0.0;
  double _knockbackVelX = 0.0;
  bool _isDying = false;

  late final SpriteAnimationTicker _idleTicker;
  late final SpriteAnimationTicker _shootTicker;

  EnemyOniArcher({
    required Vector2 position,
    this.patrolRange = 45.0,
    this.maxHp = 55.0,
  }) : super(
          position: position,
          size: Vector2(36, 50),
          anchor: Anchor.bottomCenter,
        ) {
    hp = maxHp;
    priority = 705;
  }

  @override
  Future<void> onLoad() async {
    _startX = position.x;

    _idleTicker = CartoonAssets.animation(
      game.images,
      'enemies/oni_idle.png',
      frames: 6,
      textureSize: Vector2(128, 128),
      stepTime: 0.1,
    ).createTicker();

    _shootTicker = CartoonAssets.animation(
      game.images,
      'enemies/oni_shoot.png',
      frames: 5,
      textureSize: Vector2(128, 128),
      stepTime: 0.07,
    ).createTicker();

    await super.onLoad();
    add(RectangleHitbox());
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
    final minX = _startX - patrolRange;
    final maxX = _startX + patrolRange;
    position.x = (position.x + pushDir * knockbackForce).clamp(minX, maxX);
    _knockbackVelX = pushDir * 80.0;

    game.add(MangaTextEffect(
      position: Vector2(position.x, position.y - size.y - 10),
      text: hp <= 0 ? 'SHATTER!!' : '-${amount.toInt()}',
      fillColor: ComicTheme.energyCyan,
    ));

    if (hp <= 0) {
      _die();
    }
  }

  void _die() {
    _isDying = true;
    game.addScore(220);
    game.addSpirit(16);
    game.add(MangaDustEffect(position: position.clone()));
    game.add(InkScroll(position: Vector2(position.x, position.y - 22)));
    removeFromParent();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_isDying) return;
    if (!game.isInView(position.x, 760.0)) return;

    if (_hitFlashTimer > 0) _hitFlashTimer -= dt;
    if (_shootAnimTimer > 0) _shootAnimTimer -= dt;

    final minX = _startX - patrolRange;
    final maxX = _startX + patrolRange;
    if (_knockbackVelX.abs() > 5.0) {
      position.x = (position.x + _knockbackVelX * dt).clamp(minX, maxX);
      _knockbackVelX *= pow(0.01, dt).toDouble();
    }

    final player = game.player;
    final dx = player.position.x - position.x;
    final dy = (player.position.y - position.y).abs();
    _facing = dx >= 0 ? 1 : -1;

    _shootCooldown -= dt;
    if (dx.abs() < 320 && dy < 95 && _shootCooldown <= 0 && _hitFlashTimer <= 0) {
      _shootCooldown = 2.3;
      _shootAnimTimer = 0.35;
      _shootTicker.reset();

      game.add(BossEnergyOrb(
        position: Vector2(position.x + _facing * 20, position.y - 28),
        velocity: Vector2(_facing * 270.0, 0),
      ));
      game.add(MangaTextEffect(
        position: Vector2(position.x, position.y - size.y - 8),
        text: 'TWANG!',
        fillColor: ComicTheme.comicYellow,
        initialScale: 0.4,
        targetScale: 0.9,
      ));
    }

    if (_shootAnimTimer > 0) {
      _shootTicker.update(dt);
    } else {
      _idleTicker.update(dt);
    }
  }

  @override
  void render(Canvas canvas) {
    if (!game.isInView(position.x, 600.0)) return;
    final activeTicker = _shootAnimTimer > 0 ? _shootTicker : _idleTicker;
    final sprite = activeTicker.getSprite();

    const renderW = 70.0;
    const renderH = 70.0;

    canvas.save();
    canvas.translate(size.x / 2, size.y + 4);
    if (_facing < 0) {
      canvas.scale(-1, 1);
    }

    final overridePaint = _hitFlashTimer > 0
        ? (Paint()
          ..colorFilter = const ColorFilter.mode(
            Colors.white,
            BlendMode.srcATop,
          ))
        : null;

    sprite.render(
      canvas,
      position: Vector2(-renderW / 2, -renderH),
      size: Vector2(renderW, renderH),
      overridePaint: overridePaint,
    );
    canvas.restore();

    if (hp < maxHp) {
      final barWidth = size.x + 8;
      final hpRatio = (hp / maxHp).clamp(0.0, 1.0);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(-4, -14, barWidth, 6), const Radius.circular(3)),
        Paint()..color = ComicTheme.inkBlack,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(-4, -14, barWidth * hpRatio, 6),
            const Radius.circular(3)),
        Paint()..color = ComicTheme.energyCyan,
      );
    }
  }
}

