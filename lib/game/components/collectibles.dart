import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import '../cartoon_assets.dart';
import '../manga_game.dart';
import '../services/audio_service.dart';
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
    _basePos = position.clone();
    _ticker = CartoonAssets.animation(
      game.images,
      'environment/item_scroll.png',
      frames: 6,
      textureSize: Vector2(80, 80),
      stepTime: 0.1,
    ).createTicker();
    await super.onLoad();
    add(CircleHitbox(collisionType: CollisionType.passive));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isInView(position.x, 700.0)) return;
    _ticker.update(dt);
    _timer += dt * 3.5;
    position.y = _basePos.y + sin(_timer) * 5;
  }

  void collect() {
    AudioService.playSfx(AudioService.sfxPickupCoin);
    game.addScore(points);
    game.addSpirit(15);
    game.add(MangaTextEffect(
      position: position.clone(),
      text: '+$points!',
      fillColor: ComicTheme.comicYellow,
    ));
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    if (!game.isInView(position.x, 580.0)) return;
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
    _basePos = position.clone();
    _ticker = CartoonAssets.animation(
      game.images,
      'environment/item_ramen.png',
      frames: 6,
      textureSize: Vector2(80, 80),
      stepTime: 0.11,
    ).createTicker();
    await super.onLoad();
    add(CircleHitbox(collisionType: CollisionType.passive));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isInView(position.x, 700.0)) return;
    _ticker.update(dt);
    _timer += dt * 3;
    position.y = _basePos.y + sin(_timer) * 4;
  }

  void collect() {
    AudioService.playSfx(AudioService.sfxPickupCoin);
    game.healPlayer(1);
    game.addSpirit(10);
    game.add(MangaTextEffect(
      position: position.clone(),
      text: 'DELICIOUS! +1 HP',
      fillColor: Colors.lightGreenAccent,
    ));
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    if (!game.isInView(position.x, 580.0)) return;
    final sprite = _ticker.getSprite();
    sprite.render(
      canvas,
      position: Vector2.zero(),
      size: size,
    );
  }
}

/// 2D Cartoon Animated Shinto Torii Gate (Boss Arena Gate)
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
    _ticker = CartoonAssets.animation(
      game.images,
      'environment/prop_torii.png',
      frames: 6,
      textureSize: Vector2(160, 200),
      stepTime: 0.1,
    ).createTicker();
    await super.onLoad();
    add(RectangleHitbox(collisionType: CollisionType.passive));
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
        text: 'BOSS ENCOUNTER!!',
        fillColor: ComicTheme.actionRed,
        targetScale: 1.6,
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

/// Interactive Shinto Spirit Lantern Checkpoint
class CheckpointLantern extends PositionComponent
    with CollisionCallbacks, HasGameReference<MangaGame> {
  bool isActivated = false;
  double _animTimer = 0.0;
  late final SpriteSheet _sheet;

  CheckpointLantern({
    required Vector2 position,
  }) : super(
          position: position,
          size: Vector2(44, 62),
          anchor: Anchor.bottomCenter,
        ) {
    priority = 515;
  }

  @override
  Future<void> onLoad() async {
    _sheet = SpriteSheet(
      image: game.images.fromCache('environment/prop_checkpoint.png'),
      srcSize: Vector2(80, 110),
    );
    await super.onLoad();
    add(RectangleHitbox(collisionType: CollisionType.passive));
  }

  void activate() {
    if (isActivated) return;
    isActivated = true;
    game.currentSpawnPoint = Vector2(position.x, position.y - 10);
    game.healPlayer(1);
    game.addSpirit(20);
    game.add(MangaDustEffect(position: position.clone()));
    game.add(MangaTextEffect(
      position: Vector2(position.x, position.y - size.y - 10),
      text: 'CHECKPOINT!',
      fillColor: ComicTheme.energyCyan,
      targetScale: 1.4,
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isActivated) {
      _animTimer += dt * 8;
    }
  }

  @override
  void render(Canvas canvas) {
    int frame = 0;
    if (isActivated) {
      frame = 1 + (_animTimer.toInt() % 3);
    }
    final sprite = _sheet.getSprite(0, frame);
    sprite.render(canvas, position: Vector2.zero(), size: size);
  }
}

/// Interactive Breakable Shinobi Supply Crate (smashable with Slash or Kunai)
class BreakableCrate extends PositionComponent
    with CollisionCallbacks, HasGameReference<MangaGame> {
  final bool dropsRamen;
  int hp = 2;
  double _shakeTimer = 0.0;
  late final SpriteSheet _sheet;

  BreakableCrate({
    required Vector2 position,
    this.dropsRamen = false,
  }) : super(
          position: position,
          size: Vector2(42, 42),
          anchor: Anchor.bottomCenter,
        ) {
    priority = 530;
  }

  @override
  Future<void> onLoad() async {
    _sheet = SpriteSheet(
      image: game.images.fromCache('environment/prop_crate.png'),
      srcSize: Vector2(72, 72),
    );
    await super.onLoad();
    add(RectangleHitbox(collisionType: CollisionType.passive));
  }

  void hit() {
    if (hp <= 0) return;
    hp--;
    _shakeTimer = 0.16;
    if (hp <= 0) {
      game.addScore(75);
      game.addSpirit(10);
      game.add(MangaDustEffect(position: position.clone()));
      game.add(MangaTextEffect(
        position: Vector2(position.x, position.y - 30),
        text: 'SMASH!!',
        fillColor: ComicTheme.comicYellow,
      ));
      if (dropsRamen) {
        game.add(RamenBowl(position: Vector2(position.x, position.y - 22)));
      } else {
        game.add(InkScroll(position: Vector2(position.x, position.y - 22)));
      }
      removeFromParent();
    } else {
      game.add(MangaTextEffect(
        position: Vector2(position.x, position.y - 25),
        text: 'CRACK!',
        fillColor: ComicTheme.paperWhite,
        initialScale: 0.3,
        targetScale: 0.9,
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_shakeTimer > 0) {
      _shakeTimer -= dt;
    }
  }

  @override
  void render(Canvas canvas) {
    final frame = hp == 2 ? 0 : 1;
    final sprite = _sheet.getSprite(0, frame);
    final dx = _shakeTimer > 0 ? (Random().nextDouble() - 0.5) * 5 : 0.0;
    sprite.render(canvas, position: Vector2(dx, 0), size: size);
  }
}

/// Interactive Mid-Air Taiko Spirit Bounce Drum
class TaikoBounceDrum extends PositionComponent
    with CollisionCallbacks, HasGameReference<MangaGame> {
  final double bounceForce;
  double _bounceTimer = 0.0;
  double _hoverTimer = 0.0;
  Vector2 _basePos = Vector2.zero();
  late final SpriteSheet _sheet;

  TaikoBounceDrum({
    required Vector2 position,
    this.bounceForce = 560.0,
  }) : super(
          position: position,
          size: Vector2(52, 52),
          anchor: Anchor.center,
        ) {
    priority = 525;
  }

  @override
  Future<void> onLoad() async {
    _basePos = position.clone();
    _sheet = SpriteSheet(
      image: game.images.fromCache('environment/prop_bounce_drum.png'),
      srcSize: Vector2(88, 88),
    );
    await super.onLoad();
    add(CircleHitbox(collisionType: CollisionType.passive));
  }

  void triggerBounce() {
    if (_bounceTimer > 0.12) return;
    _bounceTimer = 0.25;
    game.player.velocity.y = -bounceForce;
    game.player.isOnGround = false;
    game.player.dashCooldown = 0.0; // Reset dash in mid-air!
    game.addSpirit(5);
    game.add(MangaDustEffect(position: position.clone()));
    game.add(MangaTextEffect(
      position: Vector2(position.x, position.y - 28),
      text: 'DON!!',
      fillColor: ComicTheme.comicYellow,
      targetScale: 1.35,
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _hoverTimer += dt * 3.0;
    position.y = _basePos.y + sin(_hoverTimer) * 4.0;
    if (_bounceTimer > 0) {
      _bounceTimer -= dt;
    }
  }

  @override
  void render(Canvas canvas) {
    int frame = 0;
    if (_bounceTimer > 0.14) {
      frame = 1;
    } else if (_bounceTimer > 0) {
      frame = 2;
    }
    final sprite = _sheet.getSprite(0, frame);
    sprite.render(canvas, position: Vector2.zero(), size: size);
  }
}

/// Interactive Upward Wind Geyser / Fan Vent
class WindUpdraftVent extends PositionComponent
    with CollisionCallbacks, HasGameReference<MangaGame> {
  final double liftHeight;
  final double liftSpeed;
  late final SpriteAnimationTicker _ticker;

  WindUpdraftVent({
    required Vector2 position,
    this.liftHeight = 190.0,
    this.liftSpeed = -390.0,
  }) : super(
          position: position,
          size: Vector2(64, 96),
          anchor: Anchor.bottomCenter,
        ) {
    priority = 512;
  }

  @override
  Future<void> onLoad() async {
    _ticker = CartoonAssets.animation(
      game.images,
      'environment/prop_wind_vent.png',
      frames: 4,
      textureSize: Vector2(96, 128),
      stepTime: 0.07,
    ).createTicker();
    await super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isInView(position.x, 700.0)) return;
    _ticker.update(dt);

    // Check if player is within the vertical wind column
    final p = game.player;
    final dx = (p.position.x - position.x).abs();
    final dy = position.y - p.position.y;
    if (dx < 36 && dy >= -10 && dy <= liftHeight) {
      if (p.velocity.y > liftSpeed) {
        p.velocity.y = (p.velocity.y - 1900 * dt).clamp(liftSpeed, 400.0);
        p.isOnGround = false;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (!game.isInView(position.x, 580.0)) return;
    final sprite = _ticker.getSprite();
    sprite.render(
      canvas,
      position: Vector2(0, size.y - liftHeight),
      size: Vector2(size.x, liftHeight),
    );
  }
}

/// Mechanical Gate Barrier that opens when its linked SwitchOrb is activated
class GateBarrier extends PositionComponent
    with CollisionCallbacks, HasGameReference<MangaGame> {
  bool isOpen = false;
  double _openProgress = 0.0;
  late final RectangleHitbox _hitbox;
  late final SpriteAnimationTicker _ticker;

  GateBarrier({
    required Vector2 position,
    Vector2? size,
  }) : super(
          position: position,
          size: size ?? Vector2(34, 130),
          anchor: Anchor.bottomCenter,
        ) {
    priority = 525;
  }

  @override
  Future<void> onLoad() async {
    _hitbox = RectangleHitbox(collisionType: CollisionType.passive);
    _ticker = CartoonAssets.animation(
      game.images,
      'environment/prop_gate_barrier.png',
      frames: 4,
      textureSize: Vector2(64, 160),
      stepTime: 0.09,
    ).createTicker();
    await super.onLoad();
    add(_hitbox);
  }

  void unlock() {
    if (isOpen) return;
    isOpen = true;
    _hitbox.collisionType = CollisionType.inactive;
    game.add(MangaDustEffect(position: position.clone()));
    game.add(MangaTextEffect(
      position: Vector2(position.x, position.y - size.y),
      text: 'GATE OPEN!!',
      fillColor: ComicTheme.energyCyan,
      targetScale: 1.4,
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _ticker.update(dt);
    if (isOpen && _openProgress < 1.0) {
      _openProgress = (_openProgress + dt * 2.5).clamp(0.0, 1.0);
    }

    // Solid horizontal barrier check for the player while closed
    if (!isOpen) {
      final p = game.player;
      final inY = p.position.y > (position.y - size.y) &&
          (p.position.y - p.size.y) < position.y;
      if (inY && (p.position.x - position.x).abs() < 28) {
        if (p.position.x < position.x) {
          p.position.x = position.x - 28;
        } else {
          p.position.x = position.x + 28;
        }
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (_openProgress >= 1.0) return;
    final currentH = size.y * (1.0 - _openProgress);
    final sprite = _ticker.getSprite();
    sprite.render(
      canvas,
      position: Vector2(0, 0),
      size: Vector2(size.x, currentH),
    );
  }
}

/// Interactive Switch Orb that unlocks a GateBarrier when Slashed, shot with Kunai, or touched
class SwitchOrb extends PositionComponent
    with CollisionCallbacks, HasGameReference<MangaGame> {
  final GateBarrier? targetGate;
  final VoidCallback? onActivate;
  bool isActivated = false;
  late final SpriteSheet _sheet;

  SwitchOrb({
    required Vector2 position,
    this.targetGate,
    this.onActivate,
  }) : super(
          position: position,
          size: Vector2(40, 50),
          anchor: Anchor.bottomCenter,
        ) {
    priority = 525;
  }

  @override
  Future<void> onLoad() async {
    _sheet = SpriteSheet(
      image: game.images.fromCache('environment/prop_switch_orb.png'),
      srcSize: Vector2(64, 80),
    );
    await super.onLoad();
    add(RectangleHitbox(collisionType: CollisionType.passive));
  }

  void triggerSwitch() {
    if (isActivated) return;
    isActivated = true;
    game.addScore(100);
    game.add(MangaTextEffect(
      position: Vector2(position.x, position.y - size.y - 10),
      text: 'CLICK!!',
      fillColor: Colors.greenAccent,
      targetScale: 1.4,
    ));
    targetGate?.unlock();
    onActivate?.call();
  }

  @override
  void render(Canvas canvas) {
    if (!game.isInView(position.x, 580.0)) return;
    final frame = isActivated ? 2 : 0;
    final sprite = _sheet.getSprite(0, frame);
    sprite.render(canvas, position: Vector2.zero(), size: size);
  }
}

/// LEVEL 1 SIGNATURE MECHANIC: Overhead Neon Shinobi Zipline Rail
class ZipLineLanternRail extends PositionComponent
    with HasGameReference<MangaGame> {
  final double endX;
  final double railY;
  final double glideSpeed;
  bool _isRiding = false;
  double _detachCooldown = 0.0;

  static final Paint _cableOutline = Paint()
    ..color = ComicTheme.inkBlack
    ..strokeWidth = 7.0
    ..strokeCap = StrokeCap.round;
  static final Paint _cableCore = Paint()
    ..color = ComicTheme.energyCyan
    ..strokeWidth = 3.2
    ..strokeCap = StrokeCap.round;
  static final Paint _postPaint = Paint()..color = const Color(0xFF263238);
  static final Paint _lanternPaint = Paint()..color = ComicTheme.comicYellow;
  static final Paint _borderPaint = Paint()
    ..color = ComicTheme.inkBlack
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.8;

  ZipLineLanternRail({
    required double startX,
    required this.endX,
    required this.railY,
    this.glideSpeed = 380.0,
  }) : super(
          position: Vector2(startX, railY),
          size: Vector2((endX - startX).abs(), 28),
          anchor: Anchor.topLeft,
        ) {
    priority = 528;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_detachCooldown > 0) _detachCooldown -= dt;
    if (!game.isInView(position.x + size.x * 0.5, size.x * 0.5 + 650.0)) {
      return;
    }

    final p = game.player;
    if (_isRiding) {
      // Allow player to jump off the zipline at any moment
      if (p.velocity.y < -250 || p.isDashing) {
        _isRiding = false;
        _detachCooldown = 0.45;
        return;
      }

      p.position.x += glideSpeed * dt;
      p.position.y = railY + 54.0;
      p.velocity = Vector2(glideSpeed, 0);
      p.isOnGround = true; // Enables mid-ride jump!
      p.facingDirection = 1;

      if (p.position.x >= endX - 10) {
        _isRiding = false;
        _detachCooldown = 0.45;
        p.velocity = Vector2(220, -280);
        p.isOnGround = false;
        game.add(MangaTextEffect(
          position: Vector2(p.position.x, p.position.y - 40),
          text: 'LAUNCH!!',
          fillColor: ComicTheme.energyCyan,
        ));
      }
    } else if (_detachCooldown <= 0) {
      final inX = p.position.x >= position.x - 12 && p.position.x <= endX - 24;
      final headY = p.position.y - p.size.y;
      if (inX && (headY - railY).abs() < 28 && p.velocity.y >= -180) {
        _isRiding = true;
        p.dashCooldown = 0.0;
        game.add(MangaTextEffect(
          position: Vector2(p.position.x, railY - 12),
          text: 'ZIIIIP!!',
          fillColor: ComicTheme.comicYellow,
        ));
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (!game.isInView(position.x + size.x * 0.5, size.x * 0.5 + 620.0)) {
      return;
    }

    // Left and Right Rooftop Anchor Posts
    final leftPost = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-6, -12, 12, 32),
      const Radius.circular(3),
    );
    final rightPost = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.x - 6, -12, 12, 32),
      const Radius.circular(3),
    );
    canvas.drawRRect(leftPost, _postPaint);
    canvas.drawRRect(leftPost, _borderPaint);
    canvas.drawRRect(rightPost, _postPaint);
    canvas.drawRRect(rightPost, _borderPaint);

    // Overhead Neon Cable
    canvas.drawLine(Offset.zero, Offset(size.x, 0), _cableOutline);
    canvas.drawLine(Offset.zero, Offset(size.x, 0), _cableCore);

    // Sliding Pulley Handle
    final pulleyX = _isRiding
        ? (game.player.position.x - position.x).clamp(0.0, size.x)
        : 18.0;
    canvas.drawCircle(Offset(pulleyX, 0), 8, _lanternPaint);
    canvas.drawCircle(Offset(pulleyX, 0), 8, _borderPaint);
  }
}

/// LEVEL 5 SIGNATURE MECHANIC: Dimensional Eclipse Warp Portal
class EclipseWarpPortal extends PositionComponent
    with HasGameReference<MangaGame> {
  final Vector2 targetDestination;
  final Color portalColor;
  double _animTimer = 0.0;
  double _cooldown = 0.0;

  static final Paint _corePaint = Paint()..color = const Color(0xDD140826);
  static final Paint _borderPaint = Paint()
    ..color = ComicTheme.inkBlack
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.2;

  EclipseWarpPortal({
    required Vector2 position,
    required this.targetDestination,
    this.portalColor = ComicTheme.actionRed,
  }) : super(
          position: position,
          size: Vector2(54, 76),
          anchor: Anchor.bottomCenter,
        ) {
    priority = 526;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_cooldown > 0) _cooldown -= dt;
    if (!game.isInView(position.x, 700.0)) return;
    _animTimer += dt * 4.5;

    if (_cooldown <= 0) {
      final p = game.player;
      final dx = (p.position.x - position.x).abs();
      final dy = (p.position.y - position.y).abs();
      if (dx < 28 && dy < 44) {
        _cooldown = 1.4;
        game.add(MangaDustEffect(position: position.clone()));
        p.position = targetDestination.clone();
        p.velocity = Vector2(0, -120);
        p.invulnerableTimer = 0.8;
        p.dashCooldown = 0.0;
        game.add(MangaDustEffect(position: targetDestination.clone()));
        game.add(MangaTextEffect(
          position: Vector2(targetDestination.x, targetDestination.y - 50),
          text: 'ECLIPSE WARP!!',
          fillColor: ComicTheme.comicYellow,
          targetScale: 1.5,
        ));
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (!game.isInView(position.x, 580.0)) return;

    final pulse = sin(_animTimer) * 3.0;
    final outerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        2 - pulse * 0.5,
        2 - pulse * 0.5,
        size.x - 4 + pulse,
        size.y - 4 + pulse,
      ),
      const Radius.circular(28),
    );
    final innerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(10, 10, size.x - 20, size.y - 20),
      const Radius.circular(20),
    );

    canvas.drawRRect(outerRect, Paint()..color = portalColor);
    canvas.drawRRect(innerRect, _corePaint);
    canvas.drawRRect(outerRect, _borderPaint);
    canvas.drawRRect(innerRect, _borderPaint);
  }
}
