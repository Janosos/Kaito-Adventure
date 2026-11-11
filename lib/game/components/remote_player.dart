import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import '../cartoon_assets.dart';
import 'manga_effects.dart';
import '../manga_game.dart';
import 'player.dart';

class RemotePlayer extends PositionComponent
    with CollisionCallbacks, HasGameReference<MangaGame> {
  String nickname;
  Color playerColor;
  double hp = 100.0;
  double maxHp = 100.0;
  double ougi = 0.0;

  int facingDirection = -1;
  PlayerAction action = PlayerAction.idle;
  Vector2 targetPosition = Vector2.zero();
  Vector2 networkVelocity = Vector2.zero();

  bool isDying = false;
  double hitFlashTimer = 0.0;

  late final Map<PlayerAction, SpriteAnimationTicker> _tickers;

  RemotePlayer({
    required Vector2 position,
    required this.nickname,
    required this.playerColor,
  }) : super(
          position: position,
          size: Vector2(40, 56),
          anchor: Anchor.bottomCenter,
        ) {
    targetPosition = position.clone();
    priority = 800;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final imgs = game.images;
    _tickers = {
      PlayerAction.idle: CartoonAssets.animation(
        imgs,
        'characters/kaito_idle.png',
        frames: 4,
        textureSize: Vector2(180, 180),
        stepTime: 0.12,
      ).createTicker(),
      PlayerAction.running: CartoonAssets.animation(
        imgs,
        'characters/kaito_run.png',
        frames: 6,
        textureSize: Vector2(180, 180),
        stepTime: 0.08,
      ).createTicker(),
      PlayerAction.jumping: CartoonAssets.animation(
        imgs,
        'characters/kaito_jump.png',
        frames: 3,
        textureSize: Vector2(180, 180),
        stepTime: 0.09,
        loop: false,
      ).createTicker(),
      PlayerAction.falling: CartoonAssets.animation(
        imgs,
        'characters/kaito_jump.png',
        frames: 3,
        textureSize: Vector2(180, 180),
        stepTime: 0.09,
        loop: false,
      ).createTicker(),
      PlayerAction.dashing: CartoonAssets.animation(
        imgs,
        'characters/kaito_dash.png',
        frames: 2,
        textureSize: Vector2(180, 180),
        stepTime: 0.1,
      ).createTicker(),
      PlayerAction.attack1: CartoonAssets.animation(
        imgs,
        'characters/kaito_slash_combo.png',
        frames: 6,
        textureSize: Vector2(240, 180),
        stepTime: 0.06,
        loop: false,
      ).createTicker(),
      PlayerAction.attack2: CartoonAssets.animation(
        imgs,
        'characters/kaito_slash_combo.png',
        frames: 6,
        textureSize: Vector2(240, 180),
        stepTime: 0.06,
        loop: false,
      ).createTicker(),
      PlayerAction.attack3: CartoonAssets.animation(
        imgs,
        'characters/kaito_slash_combo.png',
        frames: 6,
        textureSize: Vector2(240, 180),
        stepTime: 0.06,
        loop: false,
      ).createTicker(),
      PlayerAction.hurt: CartoonAssets.animation(
        imgs,
        'characters/kaito_hurt.png',
        frames: 2,
        textureSize: Vector2(180, 180),
        stepTime: 0.12,
      ).createTicker(),
      PlayerAction.death: CartoonAssets.animation(
        imgs,
        'characters/kaito_death.png',
        frames: 6,
        textureSize: Vector2(240, 180),
        stepTime: 0.11,
        loop: false,
      ).createTicker(),
    };

    add(RectangleHitbox(
      position: Vector2(2, 4),
      size: Vector2(36, 52),
    ));
  }

  void updateFromNetwork({
    required double x,
    required double y,
    required double vx,
    required double vy,
    required int facing,
    required String actionName,
    required double remoteHp,
    required double remoteOugi,
  }) {
    targetPosition.setValues(x, y);
    networkVelocity.setValues(vx, vy);
    facingDirection = facing;
    hp = remoteHp;
    ougi = remoteOugi;

    // Map action string to PlayerAction enum
    for (final a in PlayerAction.values) {
      if (a.name == actionName) {
        if (action != a) {
          action = a;
          _tickers[a]?.reset();
        }
        break;
      }
    }
  }

  void takeDamage(double dmg, {Vector2? knockback}) {
    hp = (hp - dmg).clamp(0.0, maxHp);
    hitFlashTimer = 0.18;
    game.add(MangaDustEffect(position: Vector2(position.x, position.y - 30)));
    game.add(MangaTextEffect(
      position: Vector2(position.x, position.y - 50),
      text: '-${dmg.toInt()}',
      fillColor: Colors.redAccent,
      targetScale: 1.6,
    ));

    if (knockback != null) {
      position.add(knockback);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (hitFlashTimer > 0) {
      hitFlashTimer -= dt;
    }

    // Smooth position interpolation
    if (position.distanceTo(targetPosition) > 1.0) {
      position.lerp(targetPosition, (dt * 24.0).clamp(0.0, 1.0));
    }

    final ticker = _tickers[action] ?? _tickers[PlayerAction.idle]!;
    ticker.update(dt);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final ticker = _tickers[action] ?? _tickers[PlayerAction.idle]!;
    final sprite = ticker.getSprite();

    final isWideSheet = action == PlayerAction.attack1 ||
        action == PlayerAction.attack2 ||
        action == PlayerAction.attack3 ||
        action == PlayerAction.death;
    final renderW = isWideSheet ? 82.0 : 72.0;
    const renderH = 72.0;

    canvas.save();
    canvas.translate(size.x / 2, size.y + 5);

    if (facingDirection < 0) {
      canvas.scale(-1, 1);
    }

    // Manga aura ring at opponent's feet
    final auraPaint = Paint()
      ..color = playerColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, -3), width: 50, height: 12),
      auraPaint,
    );

    final overridePaint = hitFlashTimer > 0
        ? (Paint()
          ..colorFilter = const ColorFilter.mode(Colors.white, BlendMode.srcATop))
        : (Paint()
          ..colorFilter = ColorFilter.mode(
              playerColor.withValues(alpha: 0.50),
              BlendMode.srcATop,
            ));

    sprite.render(
      canvas,
      position: Vector2(-renderW / 2, -renderH),
      size: Vector2(renderW, renderH),
      overridePaint: overridePaint,
    );

    canvas.restore();

    // Floating Nickname Banner above Opponent Head
    _renderNicknameTag(canvas);
  }

  void _renderNicknameTag(Canvas canvas) {
    const textStyle = TextStyle(
      color: Colors.white,
      fontSize: 10,
      fontWeight: FontWeight.bold,
      fontFamily: 'sans-serif',
      shadows: [
        Shadow(color: Colors.black, offset: Offset(1, 1), blurRadius: 2),
      ],
    );

    final textSpan = TextSpan(text: nickname, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    final tagW = textPainter.width + 12;
    const tagH = 16.0;
    final tagX = (size.x - tagW) / 2;
    const tagY = -18.0;

    // Manga box background
    final bgPaint = Paint()..color = const Color(0xFF141419);
    final borderPaint = Paint()
      ..color = playerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(tagX, tagY, tagW, tagH),
      const Radius.circular(4),
    );
    canvas.drawRRect(rrect, bgPaint);
    canvas.drawRRect(rrect, borderPaint);

    textPainter.paint(
      canvas,
      Offset(tagX + 6, tagY + (tagH - textPainter.height) / 2),
    );
  }
}

