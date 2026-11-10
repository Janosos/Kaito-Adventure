import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import '../cartoon_assets.dart';
import '../manga_game.dart';
import '../../ui/comic_theme.dart';
import 'manga_effects.dart';

/// 2D Cartoon Platform with Tiled Sprite Art, Moving Delta & Crumble Respawn
class ComicPlatform extends PositionComponent
    with CollisionCallbacks, HasGameReference<MangaGame> {
  final bool isMoving;
  final Vector2? moveRange;
  final double moveSpeed;
  final bool isCrumbling;
  final bool isSlipperyIce;
  final Color fillColor;

  static final Paint _shadowPaint = Paint()
    ..color = const Color(0x8C141419)
    ..style = PaintingStyle.fill;
  static final Paint _borderPaint = Paint()
    ..color = ComicTheme.inkBlack
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.0;
  static final Paint _iceSheenPaint = Paint()
    ..color = const Color(0x6680D8FF)
    ..style = PaintingStyle.fill;

  Vector2 _initialPos = Vector2.zero();
  Vector2 frameDelta = Vector2.zero();
  double _moveTimer = 0.0;
  bool _isSteppedOn = false;
  double _crumbleTimer = 0.0;
  bool _isFalling = false;
  double _fallSpeed = 0.0;
  double _respawnTimer = 0.0;
  late final Sprite _platformSprite;
  late final RectangleHitbox _hitbox;
  late final RRect _shadowRRect;
  late final RRect _mainRRect;

  ComicPlatform({
    required Vector2 position,
    required Vector2 size,
    this.isMoving = false,
    this.moveRange,
    this.moveSpeed = 1.5,
    this.isCrumbling = false,
    this.isSlipperyIce = false,
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
    _initialPos = position.clone();
    _hitbox = RectangleHitbox(collisionType: CollisionType.passive);
    _shadowRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(4, 4, size.x, size.y),
      const Radius.circular(6),
    );
    _mainRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y),
      const Radius.circular(6),
    );

    String spritePath = 'environment/platform_rooftop.png';
    if (isCrumbling) {
      spritePath = 'environment/platform_crumbling.png';
    } else if (isMoving) {
      spritePath = 'environment/platform_moving.png';
    } else {
      switch (game.currentLevelIndex) {
        case 2:
          spritePath = 'environment/platform_citadel.png';
          break;
        case 3:
          spritePath = 'environment/platform_bamboo.png';
          break;
        case 4:
          spritePath = 'environment/platform_ice.png';
          break;
        case 5:
          spritePath = 'environment/platform_sanctum.png';
          break;
        default:
          spritePath = 'environment/platform_rooftop.png';
      }
    }
    _platformSprite = CartoonAssets.sprite(game.images, spritePath);
    await super.onLoad();
    add(_hitbox);
  }

  void stepOn() {
    if (isCrumbling && !_isSteppedOn && !_isFalling) {
      _isSteppedOn = true;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    final prevPos = position.clone();

    if (_respawnTimer > 0) {
      _respawnTimer -= dt;
      if (_respawnTimer <= 0) {
        position = _initialPos.clone();
        _isSteppedOn = false;
        _isFalling = false;
        _crumbleTimer = 0.0;
        _fallSpeed = 0.0;
        _hitbox.collisionType = CollisionType.passive;
      }
      frameDelta = Vector2.zero();
      return;
    }

    if (isMoving && moveRange != null && !_isFalling) {
      _moveTimer += dt * moveSpeed;
      final offset = (sin(_moveTimer) + 1.0) / 2.0;
      position = _initialPos + (moveRange! * offset);
    }

    if (_isSteppedOn && !_isFalling) {
      _crumbleTimer += dt;
      position.x = _initialPos.x + (Random().nextDouble() - 0.5) * 4;
      if (_crumbleTimer >= 0.75) {
        _isFalling = true;
        _hitbox.collisionType = CollisionType.inactive;
        game.add(MangaDustEffect(
          position: Vector2(position.x + size.x / 2, position.y + size.y),
        ));
      }
    }

    if (_isFalling) {
      _fallSpeed += 900 * dt;
      position.y += _fallSpeed * dt;
      if (position.y > 750) {
        _respawnTimer = 2.8;
      }
    }

    frameDelta = position - prevPos;
  }

  @override
  void render(Canvas canvas) {
    if (_respawnTimer > 0) return;
    // Camera Frustum Culling for Mali/Adreno/Web GPUs
    if (!game.isInView(position.x + size.x * 0.5, size.x * 0.5 + 620.0)) {
      return;
    }

    // Cartoon drop shadow (pre-allocated Paint & RRect)
    canvas.drawRRect(_shadowRRect, _shadowPaint);

    const tileW = 140.0;
    for (double x = 0; x < size.x; x += tileW) {
      final w = (x + tileW > size.x) ? (size.x - x) : tileW;
      _platformSprite.render(
        canvas,
        position: Vector2(x, 0),
        size: Vector2(w.clamp(16.0, tileW), size.y),
      );
    }

    // Slippery Ice Frost Highlight on top edge
    if (isSlipperyIce) {
      canvas.drawRect(Rect.fromLTWH(2, 2, size.x - 4, 6), _iceSheenPaint);
    }

    // Crisp outer cartoon ink border (pre-allocated Paint & RRect)
    canvas.drawRRect(_mainRRect, _borderPaint);
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
    this.launchPower = 620.0,
  }) : super(
          position: position,
          size: Vector2(48, 28),
          anchor: Anchor.bottomCenter,
        ) {
    priority = 520;
  }

  @override
  Future<void> onLoad() async {
    _sheet = SpriteSheet(
      image: game.images.fromCache('environment/trap_spring.png'),
      srcSize: Vector2(96, 64),
    );
    await super.onLoad();
    add(RectangleHitbox(collisionType: CollisionType.passive));
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
