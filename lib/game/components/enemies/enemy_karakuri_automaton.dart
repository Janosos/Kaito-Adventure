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
import '../player.dart';

/// Clockwork Karakuri Automaton that marches along platforms and charges
/// with whirling dual buzzsaw blades when Kaito enters its line of sight.
class EnemyKarakuriAutomaton extends PositionComponent
    with CollisionCallbacks, HasGameReference<MangaGame> {
  final double minXBound;
  final double maxXBound;
  double maxHp;
  late double hp;

  int _facing = 1;
  bool _isSpinCharging = false;
  double _spinTimer = 0.0;
  double _spinCooldown = 1.4;
  double _hitFlashTimer = 0.0;
  double _knockbackVelX = 0.0;
  bool _isDying = false;

  late final SpriteAnimationTicker _marchTicker;
  late final SpriteAnimationTicker _spinTicker;

  EnemyKarakuriAutomaton({
    required Vector2 position,
    required this.minXBound,
    required this.maxXBound,
    this.maxHp = 130.0,
  }) : super(
          position: position,
          size: Vector2(36, 50),
          anchor: Anchor.bottomCenter,
        ) {
    hp = maxHp;
    priority = 706;
  }

  @override
  Future<void> onLoad() async {
    _marchTicker = CartoonAssets.animation(
      game.images,
      'enemies/karakuri_march.png',
      frames: 6,
      textureSize: Vector2(128, 128),
      stepTime: 0.08,
    ).createTicker();

    _spinTicker = CartoonAssets.animation(
      game.images,
      'enemies/karakuri_spin.png',
      frames: 5,
      textureSize: Vector2(128, 128),
      stepTime: 0.05,
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
    _hitFlashTimer = 0.16;

    final pushDir =
        knockbackDir != 0 ? knockbackDir : (game.player.position.x < position.x ? 1 : -1);
    position.x =
        (position.x + pushDir * knockbackForce).clamp(minXBound, maxXBound);
    _knockbackVelX = pushDir * 85.0;

    game.add(MangaTextEffect(
      position: Vector2(position.x, position.y - size.y - 10),
      text: hp <= 0 ? 'CLANG-BOOM!!' : '-${amount.toInt()}',
      fillColor: ComicTheme.comicYellow,
    ));

    if (hp <= 0) {
      _die();
    }
  }

  void _die() {
    _isDying = true;
    game.addScore(250);
    game.addSpirit(16);
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
    if (_spinCooldown > 0) _spinCooldown -= dt;

    if (_knockbackVelX.abs() > 5.0) {
      position.x =
          (position.x + _knockbackVelX * dt).clamp(minXBound, maxXBound);
      _knockbackVelX *= pow(0.01, dt).toDouble();
    }

    final player = game.player;
    final dx = player.position.x - position.x;
    final dy = (player.position.y - position.y).abs();

    if (_isSpinCharging) {
      _spinTimer -= dt;
      position.x += _facing * 235.0 * dt;
      if (position.x <= minXBound) {
        position.x = minXBound;
        _facing = 1;
      } else if (position.x >= maxXBound) {
        position.x = maxXBound;
        _facing = -1;
      }
      if (_spinTimer <= 0) {
        _isSpinCharging = false;
        _spinCooldown = 1.6;
      }
      _spinTicker.update(dt);
    } else {
      if (dx.abs() < 240 && dy < 72 && _spinCooldown <= 0) {
        _facing = dx >= 0 ? 1 : -1;
        _isSpinCharging = true;
        _spinTimer = 0.85;
        _spinTicker.reset();
        game.add(MangaTextEffect(
          position: Vector2(position.x, position.y - size.y - 10),
          text: 'WHIRRRR!!',
          fillColor: Colors.orangeAccent,
          initialScale: 0.4,
          targetScale: 1.0,
        ));
      } else {
        position.x += _facing * 85.0 * dt;
        if (position.x <= minXBound) {
          position.x = minXBound;
          _facing = 1;
        } else if (position.x >= maxXBound) {
          position.x = maxXBound;
          _facing = -1;
        }
      }
      _marchTicker.update(dt);
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
    final ticker = _isSpinCharging ? _spinTicker : _marchTicker;
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
        Paint()..color = Colors.orangeAccent,
      );
    }
  }
}
