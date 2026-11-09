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

class EnemyGrunt extends PositionComponent
    with CollisionCallbacks, HasGameReference<MangaGame> {
  final double patrolDistance;
  final double speed;
  double maxHp = 40.0;
  double hp = 40.0;

  double _startX = 0.0;
  int _direction = 1; // 1 = right, -1 = left
  bool _isAggro = false;
  double _attackCooldown = 0.0;
  double _attackAnimTimer = 0.0;
  double _hitFlashTimer = 0.0;
  bool _isDying = false;

  late final SpriteAnimationTicker _walkTicker;
  late final SpriteAnimationTicker _aggroTicker;
  late final SpriteAnimationTicker _attackTicker;

  EnemyGrunt({
    required Vector2 position,
    this.patrolDistance = 140.0,
    this.speed = 65.0,
  }) : super(
          position: position,
          size: Vector2(34, 46),
          anchor: Anchor.bottomCenter,
        ) {
    priority = 700;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _startX = position.x;
    add(RectangleHitbox());

    final imgs = game.images;
    _walkTicker = CartoonAssets.animation(
      imgs,
      'enemies/grunt_walk.png',
      frames: 6,
      textureSize: Vector2(128, 128),
      stepTime: 0.1,
    ).createTicker();

    _aggroTicker = CartoonAssets.animation(
      imgs,
      'enemies/grunt_aggro.png',
      frames: 6,
      textureSize: Vector2(128, 128),
      stepTime: 0.07,
    ).createTicker();

    _attackTicker = CartoonAssets.animation(
      imgs,
      'enemies/grunt_attack.png',
      frames: 4,
      textureSize: Vector2(128, 128),
      stepTime: 0.06,
      loop: false,
    ).createTicker();
  }

  void takeDamage(double amount) {
    if (_isDying) return;

    hp -= amount;
    _hitFlashTimer = 0.15;

    position.x -= _direction * 18;

    game.add(MangaTextEffect(
      position: Vector2(position.x, position.y - size.y - 10),
      text: hp <= 0 ? 'CRITICAL!!' : 'BAM!',
      fillColor: ComicTheme.actionRed,
    ));

    if (hp <= 0) {
      _die();
    }
  }

  void _die() {
    _isDying = true;
    game.addScore(150);
    game.addSpirit(10);
    game.add(MangaDustEffect(position: position.clone()));

    if (Random().nextBool()) {
      game.add(InkScroll(position: Vector2(position.x, position.y - 20)));
    }

    removeFromParent();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_isDying) return;

    if (_hitFlashTimer > 0) _hitFlashTimer -= dt;
    if (_attackCooldown > 0) _attackCooldown -= dt;
    if (_attackAnimTimer > 0) _attackAnimTimer -= dt;

    final player = game.player;
    final distToPlayer = (player.position.x - position.x).abs();
    final yDiff = (player.position.y - position.y).abs();

    if (distToPlayer < 180 && yDiff < 60) {
      if (!_isAggro) {
        _isAggro = true;
        game.add(MangaTextEffect(
          position: Vector2(position.x, position.y - size.y - 12),
          text: '!',
          fillColor: ComicTheme.actionRed,
          targetScale: 1.5,
        ));
      }
      _direction = player.position.x > position.x ? 1 : -1;
      position.x += _direction * (speed * 1.6) * dt;

      if (distToPlayer < 36 && _attackCooldown <= 0) {
        _attackCooldown = 1.4;
        _attackAnimTimer = 0.28;
        _attackTicker.reset();
        player.takeDamage(1);
        game.add(SlashArcEffect(
          position: Vector2(position.x + _direction * 20, position.y - 24),
          slashFlipped: _direction < 0,
          slashColor: ComicTheme.actionRed,
          radius: 34,
        ));
        game.add(MangaTextEffect(
          position: player.position.clone(),
          text: 'SLASH!',
          fillColor: ComicTheme.actionRed,
        ));
      }
    } else {
      _isAggro = false;
      position.x += _direction * speed * dt;
      if ((position.x - _startX).abs() >= patrolDistance) {
        _direction *= -1;
      }
    }

    if (_attackAnimTimer > 0) {
      _attackTicker.update(dt);
    } else if (_isAggro) {
      _aggroTicker.update(dt);
    } else {
      _walkTicker.update(dt);
    }
  }

  @override
  void render(Canvas canvas) {
    final SpriteAnimationTicker activeTicker = _attackAnimTimer > 0
        ? _attackTicker
        : (_isAggro ? _aggroTicker : _walkTicker);
    final sprite = activeTicker.getSprite();

    const renderW = 68.0;
    const renderH = 68.0;

    canvas.save();
    canvas.translate(size.x / 2, size.y + 4);
    if (_direction < 0) {
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

    // Mini Cartoon HP bar above enemy
    if (hp < maxHp) {
      final barWidth = size.x + 8;
      final hpRatio = (hp / maxHp).clamp(0.0, 1.0);
      final bgBar = Rect.fromLTWH(-4, -14, barWidth, 6);
      final fillBar = Rect.fromLTWH(-4, -14, barWidth * hpRatio, 6);

      canvas.drawRRect(
        RRect.fromRectAndRadius(bgBar, const Radius.circular(3)),
        Paint()..color = ComicTheme.inkBlack,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(fillBar, const Radius.circular(3)),
        Paint()..color = ComicTheme.actionRed,
      );
    }
  }
}
