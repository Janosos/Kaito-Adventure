import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:manga_platformer/game/cartoon_assets.dart';
import 'package:manga_platformer/game/manga_game.dart';
import 'package:manga_platformer/ui/comic_theme.dart';
import '../collectibles.dart';
import '../manga_effects.dart';
import '../projectiles.dart';

/// Mystical Kitsune Spirit Mage that hovers, blinks between patrol points,
/// and casts twin foxfire spirit orbs toward Kaito.
class EnemyKitsuneMage extends PositionComponent
    with CollisionCallbacks, HasGameReference<MangaGame> {
  final double patrolRange;
  double maxHp;
  late double hp;

  double _originX = 0.0;
  double _originY = 0.0;
  double _hoverTime = 0.0;
  int _facing = -1;
  double _castCooldown = 2.1;
  double _castAnimTimer = 0.0;
  double _hitFlashTimer = 0.0;
  bool _isDying = false;

  late final SpriteAnimationTicker _floatTicker;
  late final SpriteAnimationTicker _castTicker;

  EnemyKitsuneMage({
    required Vector2 position,
    this.patrolRange = 90.0,
    this.maxHp = 115.0,
  }) : super(
          position: position,
          size: Vector2(36, 52),
          anchor: Anchor.bottomCenter,
        ) {
    hp = maxHp;
    priority = 710;
  }

  @override
  Future<void> onLoad() async {
    _originX = position.x;
    _originY = position.y;

    _floatTicker = CartoonAssets.animation(
      game.images,
      'enemies/kitsune_float.png',
      frames: 6,
      textureSize: Vector2(128, 128),
      stepTime: 0.09,
    ).createTicker();

    _castTicker = CartoonAssets.animation(
      game.images,
      'enemies/kitsune_cast.png',
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

    game.add(MangaTextEffect(
      position: Vector2(position.x, position.y - size.y - 10),
      text: hp <= 0 ? 'VANISH!!' : '-${amount.toInt()}',
      fillColor: const Color(0xFFE040FB),
    ));

    if (hp <= 0) {
      _die();
    } else if (hp <= maxHp * 0.55 && _castAnimTimer <= 0) {
      // Phase blink away when struck hard
      game.add(MangaDustEffect(position: position.clone()));
      final offset = (position.x <= _originX) ? patrolRange : -patrolRange;
      position.x = (_originX + offset).clamp(40.0, game.currentLevelWidth - 40.0);
      game.add(MangaDustEffect(position: position.clone()));
    }
  }

  void _die() {
    _isDying = true;
    game.addScore(260);
    game.addSpirit(18);
    game.add(MangaDustEffect(position: position.clone()));
    game.add(InkScroll(position: Vector2(position.x, position.y - 24)));
    removeFromParent();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_isDying) return;
    if (!game.isInView(position.x, 760.0)) return;

    _hoverTime += dt;
    if (_hitFlashTimer > 0) _hitFlashTimer -= dt;
    if (_castAnimTimer > 0) _castAnimTimer -= dt;

    position.y = _originY + sin(_hoverTime * 3.2) * 10.0;

    final player = game.player;
    final dx = player.position.x - position.x;
    final dy = (player.position.y - position.y).abs();
    _facing = dx >= 0 ? 1 : -1;

    _castCooldown -= dt;
    if (dx.abs() < 360 && dy < 140 && _castCooldown <= 0) {
      _castCooldown = 2.25;
      _castAnimTimer = 0.38;
      _castTicker.reset();

      for (final vy in [-38.0, 38.0]) {
        game.add(BossEnergyOrb(
          position: Vector2(position.x + _facing * 20, position.y - 30),
          velocity: Vector2(_facing * 265.0, vy),
        ));
      }
      game.add(MangaTextEffect(
        position: Vector2(position.x, position.y - size.y - 10),
        text: 'FOXFIRE!!',
        fillColor: ComicTheme.energyCyan,
        initialScale: 0.4,
        targetScale: 0.95,
      ));
    }

    if (_castAnimTimer > 0) {
      _castTicker.update(dt);
    } else {
      _floatTicker.update(dt);
    }
  }

  @override
  void render(Canvas canvas) {
    if (!game.isInView(position.x, 600.0)) return;
    final ticker = _castAnimTimer > 0 ? _castTicker : _floatTicker;
    final sprite = ticker.getSprite();

    const renderW = 72.0;
    const renderH = 72.0;

    canvas.save();
    canvas.translate(size.x / 2, size.y + 4);
    if (_facing < 0) {
      canvas.scale(-1, 1);
    }

    final overridePaint = _hitFlashTimer > 0
        ? (Paint()
          ..colorFilter = const ColorFilter.mode(Colors.white, BlendMode.srcATop))
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
          Rect.fromLTWH(-4, -14, barWidth, 6),
          const Radius.circular(3),
        ),
        Paint()..color = ComicTheme.inkBlack,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-4, -14, barWidth * hpRatio, 6),
          const Radius.circular(3),
        ),
        Paint()..color = const Color(0xFFE040FB),
      );
    }
  }
}
