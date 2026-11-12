import 'dart:math' as math;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import '../cartoon_assets.dart';
import 'manga_effects.dart';
import '../manga_game.dart';
import '../services/lan_multiplayer_service.dart';
import 'player.dart';

class RemotePlayer extends PositionComponent
    with CollisionCallbacks, HasGameReference<MangaGame> {
  final String id;
  final int slot;
  String nickname;
  Color playerColor;
  double hp = LanMultiplayerService.kPvpMaxHp;
  double maxHp = LanMultiplayerService.kPvpMaxHp;
  double ougi = 0.0;

  int facingDirection = -1;
  PlayerAction action = PlayerAction.idle;
  Vector2 targetPosition = Vector2.zero();
  Vector2 networkVelocity = Vector2.zero();

  bool isDying = false;
  bool isCelebrating = false;
  double hitFlashTimer = 0.0;
  double _celebrationTime = 0.0;

  Map<PlayerAction, SpriteAnimationTicker>? _tickers;
  String? _cachedTagName;
  TextPainter? _cachedTagPainter;

  RemotePlayer({
    required this.id,
    required Vector2 position,
    required this.nickname,
    required this.playerColor,
    this.slot = 1,
  }) : super(
          position: position,
          size: Vector2(34, 52),
          anchor: Anchor.bottomCenter,
        ) {
    targetPosition = position.clone();
    priority = 800;
  }

  @override
  Future<void> onLoad() async {
    final imgs = game.images;
    _tickers = {
      PlayerAction.idle: CartoonAssets.animation(
        imgs,
        'characters/kaito_idle.png',
        frames: 6,
        textureSize: Vector2(128, 128),
        stepTime: 0.11,
      ).createTicker(),
      PlayerAction.running: CartoonAssets.animation(
        imgs,
        'characters/kaito_run.png',
        frames: 8,
        textureSize: Vector2(128, 128),
        stepTime: 0.065,
      ).createTicker(),
      PlayerAction.jumping: CartoonAssets.animation(
        imgs,
        'characters/kaito_jump.png',
        frames: 4,
        textureSize: Vector2(128, 128),
        stepTime: 0.09,
        loop: false,
      ).createTicker(),
      PlayerAction.falling: CartoonAssets.animation(
        imgs,
        'characters/kaito_fall.png',
        frames: 4,
        textureSize: Vector2(128, 128),
        stepTime: 0.09,
        loop: false,
      ).createTicker(),
      PlayerAction.dashing: CartoonAssets.animation(
        imgs,
        'characters/kaito_dash.png',
        frames: 4,
        textureSize: Vector2(128, 128),
        stepTime: 0.05,
      ).createTicker(),
      PlayerAction.attack1: CartoonAssets.animation(
        imgs,
        'characters/kaito_attack1.png',
        frames: 5,
        textureSize: Vector2(144, 128),
        stepTime: 0.05,
        loop: false,
      ).createTicker(),
      PlayerAction.attack2: CartoonAssets.animation(
        imgs,
        'characters/kaito_attack2.png',
        frames: 5,
        textureSize: Vector2(144, 128),
        stepTime: 0.05,
        loop: false,
      ).createTicker(),
      PlayerAction.attack3: CartoonAssets.animation(
        imgs,
        'characters/kaito_attack3.png',
        frames: 6,
        textureSize: Vector2(144, 128),
        stepTime: 0.05,
        loop: false,
      ).createTicker(),
      PlayerAction.hurt: CartoonAssets.animation(
        imgs,
        'characters/kaito_hurt.png',
        frames: 3,
        textureSize: Vector2(128, 128),
        stepTime: 0.08,
      ).createTicker(),
      PlayerAction.death: CartoonAssets.animation(
        imgs,
        'characters/kaito_death.png',
        frames: 7,
        textureSize: Vector2(144, 128),
        stepTime: 0.17,
        loop: false,
      ).createTicker(),
    };

    await super.onLoad();

    add(RectangleHitbox(
      position: Vector2(2, 4),
      size: Vector2(30, 48),
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
    if (!x.isFinite || !y.isFinite || !vx.isFinite || !vy.isFinite) return;

    targetPosition.setValues(x, y);
    networkVelocity.setValues(vx, vy);
    facingDirection = facing < 0 ? -1 : 1;

    // Never allow health regeneration or stale higher HP packets in PvP
    if (isDying) {
      hp = 0.0;
      ougi = 0.0;
      return;
    }

    if (remoteHp.isFinite && remoteHp < hp) {
      hp = remoteHp.clamp(0.0, maxHp);
    }
    if (remoteOugi.isFinite) {
      ougi = remoteOugi.clamp(0.0, 100.0);
    }

    if (hp <= 0 && !isDying && !isCelebrating) {
      isDying = true;
      hp = 0.0;
      action = PlayerAction.death;
      _tickers?[action]?.reset();
      return;
    }

    if (isCelebrating) return;

    // Map action string to PlayerAction enum
    for (final a in PlayerAction.values) {
      if (a.name == actionName) {
        if (action != a && !isDying) {
          action = a;
          _tickers?[a]?.reset();
        }
        break;
      }
    }
  }

  void markEliminated() {
    hp = 0.0;
    ougi = 0.0;
    if (!isDying) {
      isDying = true;
      hitFlashTimer = 0.18;
      action = PlayerAction.death;
      _tickers?[action]?.reset();
    }
  }

  void triggerVictoryCelebration() {
    if (isDying || isCelebrating) return;
    isCelebrating = true;
    _celebrationTime = 0.0;
    action = PlayerAction.idle;
    _tickers?[action]?.reset();
    game.add(MangaTextEffect(
      position: Vector2(position.x, position.y - 68),
      text: '¡VICTORIA!',
      fillColor: const Color(0xFFFFD600),
      targetScale: 2.0,
    ));
  }

  void takeDamage(double dmg, {Vector2? knockback}) {
    if (isDying ||
        isCelebrating ||
        LanMultiplayerService.instance.victoryCelebrationNotifier.value != null) {
      return;
    }
    hp = (hp - dmg).clamp(0.0, maxHp);
    hitFlashTimer = 0.18;
    game.add(MangaDustEffect(position: Vector2(position.x, position.y - 30)));
    game.add(MangaTextEffect(
      position: Vector2(position.x, position.y - 50),
      text: '-${dmg.toInt()}',
      fillColor: Colors.redAccent,
      targetScale: 1.6,
    ));

    if (hp <= 0) {
      hp = 0.0;
      isDying = true;
      action = PlayerAction.death;
      _tickers?[action]?.reset();
    }

    if (knockback != null && knockback.x.isFinite && knockback.y.isFinite) {
      position.add(knockback);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (hitFlashTimer > 0) {
      hitFlashTimer -= dt;
    }
    if (isCelebrating) {
      _celebrationTime += dt;
    }

    // Smooth position interpolation
    if (position.distanceTo(targetPosition) > 1.0) {
      position.lerp(targetPosition, (dt * 24.0).clamp(0.0, 1.0));
    }

    final ticker = _tickers?[action] ?? _tickers?[PlayerAction.idle];
    ticker?.update(dt);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final ticker = _tickers?[action] ?? _tickers?[PlayerAction.idle];
    if (ticker == null) {
      _renderNicknameTag(canvas);
      return;
    }
    final sprite = ticker.getSprite();

    final isWideSheet = action == PlayerAction.attack1 ||
        action == PlayerAction.attack2 ||
        action == PlayerAction.attack3 ||
        action == PlayerAction.death;
    final renderW = isWideSheet ? 82.0 : 72.0;
    const renderH = 72.0;
    final celebrationBounce =
        isCelebrating ? math.sin(_celebrationTime * 9.0).abs() * 14.0 : 0.0;

    canvas.save();
    canvas.translate(size.x / 2, size.y + 5 - celebrationBounce);

    if (facingDirection < 0) {
      canvas.scale(-1, 1);
    }

    if (!isDying) {
      // Manga aura ring at opponent's feet
      final auraPaint = Paint()
        ..color = isCelebrating
            ? const Color(0xFFFFD600).withValues(alpha: 0.55)
            : playerColor.withValues(alpha: 0.35)
        ..style = PaintingStyle.fill;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(0, -3 + celebrationBounce),
          width: isCelebrating ? 60 : 50,
          height: 12,
        ),
        auraPaint,
      );
    }

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

    // Floating Nickname Tag above Opponent Head
    _renderNicknameTag(canvas);
  }

  void _renderNicknameTag(Canvas canvas) {
    final displayName = 'P${slot + 1} $nickname';
    if (_cachedTagPainter == null || _cachedTagName != displayName) {
      _cachedTagName = displayName;
      const textStyle = TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.bold,
        fontFamily: 'sans-serif',
        shadows: [
          Shadow(color: Colors.black, offset: Offset(1, 1), blurRadius: 2),
        ],
      );
      _cachedTagPainter = TextPainter(
        text: TextSpan(text: displayName, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
    }
    final textPainter = _cachedTagPainter!;

    final tagW = textPainter.width + 14;
    const tagH = 16.0;
    final tagX = (size.x - tagW) / 2;
    const tagY = -18.0;

    // Manga box background
    final bgPaint = Paint()..color = const Color(0xFF141419);
    final borderPaint = Paint()
      ..color = isDying ? Colors.grey : playerColor
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
      Offset(tagX + 7, tagY + (tagH - textPainter.height) / 2),
    );
  }
}
