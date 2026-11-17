import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:manga_platformer/game/cartoon_assets.dart';
import 'package:manga_platformer/game/manga_game.dart';
import 'package:manga_platformer/game/services/audio_service.dart';
import 'package:manga_platformer/ui/comic_theme.dart';
import '../collectibles.dart';
import '../manga_effects.dart';
import '../player.dart';

/// Heavy Armored Ronin that guards frontal attacks with an iron tower shield
/// and cleaves with a naginata polearm. Backstabbing or heavy strikes pierce his guard!
class EnemySamuraiShield extends PositionComponent
    with CollisionCallbacks, HasGameReference<MangaGame> {
  final double minXBound;
  final double maxXBound;
  double maxHp;
  late double hp;

  int _facing = -1;
  double _attackCooldown = 1.6;
  double _attackAnimTimer = 0.0;
  double _hitFlashTimer = 0.0;
  double _knockbackVelX = 0.0;
  bool isGuarding = false;
  bool _isDying = false;

  late final SpriteAnimationTicker _walkTicker;
  late final SpriteAnimationTicker _attackTicker;
  late final SpriteAnimationTicker _guardTicker;

  EnemySamuraiShield({
    required Vector2 position,
    required this.minXBound,
    required this.maxXBound,
    this.maxHp = 150.0,
  }) : super(
          position: position,
          size: Vector2(38, 54),
          anchor: Anchor.bottomCenter,
        ) {
    hp = maxHp;
    priority = 708;
  }

  @override
  Future<void> onLoad() async {
    _walkTicker = CartoonAssets.animation(
      game.images,
      'enemies/samurai_walk.png',
      frames: 6,
      textureSize: Vector2(128, 128),
      stepTime: 0.09,
    ).createTicker();

    _attackTicker = CartoonAssets.animation(
      game.images,
      'enemies/samurai_attack.png',
      frames: 5,
      textureSize: Vector2(128, 128),
      stepTime: 0.07,
    ).createTicker();

    _guardTicker = CartoonAssets.animation(
      game.images,
      'enemies/samurai_guard.png',
      frames: 4,
      textureSize: Vector2(128, 128),
      stepTime: 0.10,
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

    final playerX = game.player.position.x;
    final isBackstab =
        (_facing > 0 && playerX < position.x - 4) ||
        (_facing < 0 && playerX > position.x + 4);

    double actualDamage = amount;
    if (isGuarding && !isBackstab && amount < 38.0) {
      actualDamage = (amount * 0.28).clamp(4.0, amount);
      AudioService.playSfx(AudioService.sfxKunaiHit);
      game.add(MangaTextEffect(
        position: Vector2(position.x, position.y - size.y - 12),
        text: 'GUARD! -${actualDamage.toInt()}',
        fillColor: ComicTheme.halftoneGray,
        targetScale: 0.95,
      ));
    } else if (isBackstab) {
      actualDamage = amount * 1.4;
      isGuarding = false;
      game.add(MangaTextEffect(
        position: Vector2(position.x, position.y - size.y - 14),
        text: 'BACKSTAB! -${actualDamage.toInt()}',
        fillColor: ComicTheme.energyCyan,
        targetScale: 1.35,
      ));
    } else {
      game.add(MangaTextEffect(
        position: Vector2(position.x, position.y - size.y - 10),
        text: '-${actualDamage.toInt()}',
        fillColor: ComicTheme.actionRed,
      ));
    }

    hp -= actualDamage;
    _hitFlashTimer = 0.16;

    final pushDir =
        knockbackDir != 0 ? knockbackDir : (playerX < position.x ? 1 : -1);
    position.x =
        (position.x + pushDir * knockbackForce).clamp(minXBound, maxXBound);
    _knockbackVelX = pushDir * 70.0;

    if (hp <= 0) {
      _die();
    }
  }

  void _die() {
    _isDying = true;
    game.addScore(280);
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

    if (_hitFlashTimer > 0) _hitFlashTimer -= dt;
    if (_attackCooldown > 0) _attackCooldown -= dt;
    if (_attackAnimTimer > 0) _attackAnimTimer -= dt;

    if (_knockbackVelX.abs() > 5.0) {
      position.x =
          (position.x + _knockbackVelX * dt).clamp(minXBound, maxXBound);
      _knockbackVelX *= pow(0.01, dt).toDouble();
    }

    final player = game.player;
    final dx = player.position.x - position.x;
    final dy = (player.position.y - position.y).abs();

    if (dx.abs() < 280 && dy < 85) {
      _facing = dx >= 0 ? 1 : -1;
      if (dx.abs() < 78 && _attackCooldown <= 0) {
        isGuarding = false;
        _attackCooldown = 1.65;
        _attackAnimTimer = 0.35;
        _attackTicker.reset();
        game.add(SlashArcEffect(
          position: Vector2(position.x + _facing * 28, position.y - 28),
          slashFlipped: _facing < 0,
          slashColor: ComicTheme.actionRed,
          radius: 52,
        ));
        if ((player.position.x - position.x).abs() < 78 && dy < 54) {
          player.takeDamage(1);
        }
      } else if (_attackAnimTimer <= 0 && dx.abs() >= 78) {
        isGuarding = true;
        position.x =
            (position.x + _facing * 48.0 * dt).clamp(minXBound, maxXBound);
      }
    } else {
      isGuarding = false;
      position.x += _facing * 68.0 * dt;
      if (position.x <= minXBound) {
        position.x = minXBound;
        _facing = 1;
      } else if (position.x >= maxXBound) {
        position.x = maxXBound;
        _facing = -1;
      }
    }

    if (_attackAnimTimer > 0) {
      _attackTicker.update(dt);
    } else if (isGuarding) {
      _guardTicker.update(dt);
    } else {
      _walkTicker.update(dt);
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is MangaPlayer && !_isDying) {
      other.takeDamage(1);
    }
  }

  @override
  void render(Canvas canvas) {
    if (!game.isInView(position.x, 600.0)) return;
    final ticker = _attackAnimTimer > 0
        ? _attackTicker
        : (isGuarding ? _guardTicker : _walkTicker);
    final sprite = ticker.getSprite();

    const renderW = 74.0;
    const renderH = 74.0;

    canvas.save();
    canvas.translate(size.x / 2, size.y + 4);
    if (_facing > 0) {
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
      final barWidth = size.x + 10;
      final hpRatio = (hp / maxHp).clamp(0.0, 1.0);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-5, -14, barWidth, 6),
          const Radius.circular(3),
        ),
        Paint()..color = ComicTheme.inkBlack,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-5, -14, barWidth * hpRatio, 6),
          const Radius.circular(3),
        ),
        Paint()..color = ComicTheme.comicYellow,
      );
    }
  }
}
