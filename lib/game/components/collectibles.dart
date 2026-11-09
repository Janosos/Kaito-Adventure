import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import '../cartoon_assets.dart';
import '../manga_game.dart';
import '../../ui/comic_theme.dart';
import 'manga_effects.dart';

/// 2D Cartoon Animated Ink Scroll (Collectible)
class InkScroll extends PositionComponent
    with CollisionCallbacks, HasGameReference<MangaGame> {
  final int points;
  double _timer = 0.0;
  Vector2 _basePos = Vector2.zero();
  late final SpriteAnimationTicker _ticker;

  InkScroll({
    required Vector2 position,
    this.points = 100,
  }) : super(
          position: position,
          size: Vector2(36, 36),
          anchor: Anchor.center,
        ) {
    priority = 600;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _basePos = position.clone();
    add(CircleHitbox(collisionType: CollisionType.passive));
    _ticker = CartoonAssets.animation(
      game.images,
      'environment/item_scroll.png',
      frames: 6,
      textureSize: Vector2(80, 80),
      stepTime: 0.1,
    ).createTicker();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _ticker.update(dt);
    _timer += dt * 3.5;
    position.y = _basePos.y + sin(_timer) * 5;
  }

  void collect() {
    game.addScore(points);
    game.addSpirit(15);
    game.add(MangaTextEffect(
      position: position.clone(),
      text: '+100!',
      fillColor: ComicTheme.comicYellow,
    ));
    removeFromParent();
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

/// 2D Cartoon Animated Ramen Bowl (Health Recovery)
class RamenBowl extends PositionComponent
    with CollisionCallbacks, HasGameReference<MangaGame> {
  double _timer = 0.0;
  Vector2 _basePos = Vector2.zero();
  late final SpriteAnimationTicker _ticker;

  RamenBowl({
    required Vector2 position,
  }) : super(
          position: position,
          size: Vector2(38, 38),
          anchor: Anchor.center,
        ) {
    priority = 600;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _basePos = position.clone();
    add(CircleHitbox(collisionType: CollisionType.passive));
    _ticker = CartoonAssets.animation(
      game.images,
      'environment/item_ramen.png',
      frames: 6,
      textureSize: Vector2(80, 80),
      stepTime: 0.11,
    ).createTicker();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _ticker.update(dt);
    _timer += dt * 3;
    position.y = _basePos.y + sin(_timer) * 4;
  }

  void collect() {
    game.healPlayer(1);
    game.add(MangaTextEffect(
      position: position.clone(),
      text: 'DELICIOUS!',
      fillColor: Colors.lightGreenAccent,
    ));
    removeFromParent();
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

/// 2D Cartoon Animated Shinto Torii Gate (Chapter / Arena Gate)
class ToriiGateExit extends PositionComponent
    with CollisionCallbacks, HasGameReference<MangaGame> {
  final VoidCallback onEnter;
  bool _triggered = false;
  late final SpriteAnimationTicker _ticker;

  ToriiGateExit({
    required Vector2 position,
    required this.onEnter,
  }) : super(
          position: position,
          size: Vector2(88, 110),
          anchor: Anchor.bottomCenter,
        ) {
    priority = 520;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox(collisionType: CollisionType.passive));
    _ticker = CartoonAssets.animation(
      game.images,
      'environment/prop_torii.png',
      frames: 6,
      textureSize: Vector2(160, 200),
      stepTime: 0.1,
    ).createTicker();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _ticker.update(dt);
  }

  void triggerEnter() {
    if (!_triggered) {
      _triggered = true;
      game.add(MangaTextEffect(
        position: Vector2(position.x, position.y - 60),
        text: 'BOSS ENCOUNTER!',
        fillColor: ComicTheme.actionRed,
      ));
      onEnter();
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
