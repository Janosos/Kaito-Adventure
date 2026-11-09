import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import '../cartoon_assets.dart';
import '../manga_game.dart';

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
    await super.onLoad();
    add(RectangleHitbox(collisionType: CollisionType.passive));
    _spikePairSprite =
        CartoonAssets.sprite(game.images, 'environment/trap_spikes.png');
  }

  @override
  void render(Canvas canvas) {
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
    await super.onLoad();
    _initialPos = position.clone();
    add(CircleHitbox(collisionType: CollisionType.passive));
    _ticker = CartoonAssets.animation(
      game.images,
      'environment/trap_saw.png',
      frames: 4,
      textureSize: Vector2(120, 120),
      stepTime: 0.05,
    ).createTicker();
  }

  @override
  void update(double dt) {
    super.update(dt);
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
