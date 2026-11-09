import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import '../cartoon_assets.dart';
import '../manga_game.dart';
import '../../ui/comic_theme.dart';
import 'manga_effects.dart';

/// 2D Cartoon Platform with Tiled Sprite Art
class ComicPlatform extends PositionComponent
    with CollisionCallbacks, HasGameReference<MangaGame> {
  final bool isMoving;
  final Vector2? moveRange;
  final double moveSpeed;
  final bool isCrumbling;
  final Color fillColor;

  Vector2 _initialPos = Vector2.zero();
  double _moveTimer = 0.0;
  bool _isSteppedOn = false;
  double _crumbleTimer = 0.0;
  bool _isFalling = false;
  double _fallSpeed = 0.0;
  late final Sprite _platformSprite;

  ComicPlatform({
    required Vector2 position,
    required Vector2 size,
    this.isMoving = false,
    this.moveRange,
    this.moveSpeed = 1.5,
    this.isCrumbling = false,
    this.fillColor = ComicTheme.paperWhite,
  }) : super(
          position: position,
          size: size,
          anchor: Anchor.topLeft,
        ) {
    priority = 500;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _initialPos = position.clone();
    add(RectangleHitbox(collisionType: CollisionType.passive));

    String spritePath = 'environment/platform_rooftop.png';
    if (isCrumbling) {
      spritePath = 'environment/platform_crumbling.png';
    } else if (isMoving) {
      spritePath = 'environment/platform_moving.png';
    } else if (game.currentLevelIndex == 2) {
      spritePath = 'environment/platform_citadel.png';
    }
    _platformSprite = CartoonAssets.sprite(game.images, spritePath);
  }

  void stepOn() {
    if (isCrumbling && !_isSteppedOn && !_isFalling) {
      _isSteppedOn = true;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (isMoving && moveRange != null && !_isFalling) {
      _moveTimer += dt * moveSpeed;
      final offset = (sin(_moveTimer) + 1.0) / 2.0;
      position = _initialPos + (moveRange! * offset);
    }

    if (_isSteppedOn && !_isFalling) {
      _crumbleTimer += dt;
      position.x += (Random().nextDouble() - 0.5) * 3;
      if (_crumbleTimer >= 0.8) {
        _isFalling = true;
        game.add(MangaDustEffect(
          position: Vector2(position.x + size.x / 2, position.y + size.y),
        ));
      }
    }

    if (_isFalling) {
      _fallSpeed += 900 * dt;
      position.y += _fallSpeed * dt;
      if (position.y > 1500) {
        removeFromParent();
      }
    }
  }

  @override
  void render(Canvas canvas) {
    // Cartoon drop shadow
    final shadowPaint = Paint()
      ..color = ComicTheme.inkBlack.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(4, 4, size.x, size.y),
        const Radius.circular(6),
      ),
      shadowPaint,
    );

    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y),
        const Radius.circular(6),
      ),
    );

    const tileW = 140.0;
    for (double x = 0; x < size.x; x += tileW) {
      final w = (x + tileW > size.x) ? (size.x - x) : tileW;
      _platformSprite.render(
        canvas,
        position: Vector2(x, 0),
        size: Vector2(w.clamp(32.0, tileW), size.y),
      );
    }
    canvas.restore();

    // Crisp outer cartoon ink border
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y),
        const Radius.circular(6),
      ),
      Paint()
        ..color = ComicTheme.inkBlack
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0,
    );
  }
}

/// 2D Cartoon Animated Spring Pad (Launch Trampoline)
class MangaSpringPad extends PositionComponent
    with CollisionCallbacks, HasGameReference<MangaGame> {
  final double launchPower;
  double _compressTimer = 0.0;
  bool _isCompressed = false;
  late final SpriteSheet _sheet;

  MangaSpringPad({
    required Vector2 position,
    this.launchPower = 680.0,
  }) : super(
          position: position,
          size: Vector2(48, 28),
          anchor: Anchor.bottomCenter,
        ) {
    priority = 520;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox(collisionType: CollisionType.passive));
    _sheet = SpriteSheet(
      image: game.images.fromCache('environment/trap_spring.png'),
      srcSize: Vector2(96, 64),
    );
  }

  void triggerSpring() {
    _isCompressed = true;
    _compressTimer = 0.28;
    game.add(MangaTextEffect(
      position: Vector2(position.x, position.y - 30),
      text: 'BOING!!',
      fillColor: ComicTheme.energyCyan,
    ));
    game.add(MangaDustEffect(position: position.clone()));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_isCompressed) {
      _compressTimer -= dt;
      if (_compressTimer <= 0) {
        _isCompressed = false;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    int frame = 0;
    if (_isCompressed) {
      frame = _compressTimer > 0.16 ? 1 : 2;
    }
    final sprite = _sheet.getSprite(0, frame);
    sprite.render(
      canvas,
      position: Vector2.zero(),
      size: size,
    );
  }
}
