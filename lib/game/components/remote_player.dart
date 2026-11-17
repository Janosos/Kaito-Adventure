import 'dart:math' as math;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import '../../ui/comic_theme.dart';
import '../cartoon_assets.dart';
import 'manga_effects.dart';
import '../manga_game.dart';
import '../services/audio_service.dart';
import '../services/lan_multiplayer_service.dart';
import 'player.dart';

class RemotePlayer extends PositionComponent
    with CollisionCallbacks, HasGameReference<MangaGame> {
  final String id;
  final int slot;
  String nickname;
  Color playerColor;
  int colorIndex;
  double hp;
  double maxHp;
  int lives;
  int maxLives;
  double ougi = 0.0;

  int facingDirection = -1;
  PlayerAction action = PlayerAction.idle;
  Vector2 targetPosition = Vector2.zero();
  Vector2 networkVelocity = Vector2.zero();

  bool isDying = false;
  bool isCelebrating = false;
  double hitFlashTimer = 0.0;
  double _celebrationTime = 0.0;
  double _attackAnimLockTimer = 0.0;
  double _lastSlashFxCooldown = 0.0;
  double _lastOugiFxCooldown = 0.0;

  Map<PlayerAction, SpriteAnimationTicker>? _tickers;
  String? _cachedTagName;
  TextPainter? _cachedTagPainter;

  RemotePlayer({
    required this.id,
    required Vector2 position,
    required this.nickname,
    required this.playerColor,
    this.colorIndex = 0,
    this.slot = 1,
    double? initialHp,
    int? initialLives,
  })  : hp = initialHp ?? LanMultiplayerService.instance.configuredMaxHp,
        maxHp = initialHp ?? LanMultiplayerService.instance.configuredMaxHp,
        lives = initialLives ?? LanMultiplayerService.instance.configuredLives,
        maxLives =
            initialLives ?? LanMultiplayerService.instance.configuredLives,
        super(
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
      PlayerAction.ougi: CartoonAssets.animation(
        imgs,
        'characters/kaito_ougi.png',
        frames: 8,
        textureSize: Vector2(160, 144),
        stepTime: 0.08,
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
        final isIncomingAttack = a == PlayerAction.attack1 ||
            a == PlayerAction.attack2 ||
            a == PlayerAction.attack3 ||
            a == PlayerAction.ougi;
        final isPassiveMovement = a == PlayerAction.idle ||
            a == PlayerAction.running ||
            a == PlayerAction.jumping ||
            a == PlayerAction.falling;

        // Do not let passive movement state packets cut off an active attack swing mid-animation!
        if (_attackAnimLockTimer > 0 && isPassiveMovement) {
          break;
        }

        if (action != a && !isDying) {
          action = a;
          _tickers?[a]?.reset();
          if (a == PlayerAction.ougi) {
            _attackAnimLockTimer = 0.68;
            _spawnRemoteOugiVisuals();
          } else if (isIncomingAttack) {
            _attackAnimLockTimer = 0.28;
            final comboIdx = a == PlayerAction.attack1
                ? 0
                : (a == PlayerAction.attack2 ? 1 : 2);
            _spawnRemoteSlashVisuals(comboIdx);
          }
        }
        break;
      }
    }
  }

  void _spawnRemoteSlashVisuals(int comboIndex) {
    if (_lastSlashFxCooldown > 0) return;
    _lastSlashFxCooldown = 0.16;

    final idx = comboIndex.clamp(0, 2);
    final texts = ['SLASH!', 'SHING!!', 'ZUBATTO!!!'];
    final colors = [
      ComicTheme.comicYellow,
      ComicTheme.energyCyan,
      ComicTheme.actionRed,
    ];

    AudioService.playSfx(
      idx == 2 ? AudioService.sfxSlashHeavy : AudioService.sfxSlash,
      volume: 0.75,
    );

    game.add(SlashArcEffect(
      position: Vector2(
        position.x + facingDirection * 28,
        position.y - size.y * 0.5,
      ),
      slashFlipped: facingDirection < 0,
      slashColor: colors[idx],
      radius: 48.0 + idx * 6,
    ));

    game.add(MangaTextEffect(
      position: Vector2(
        position.x + facingDirection * 35,
        position.y - size.y * 0.7,
      ),
      text: texts[idx],
      fillColor: colors[idx],
      targetScale: 1.1 + idx * 0.25,
    ));
  }

  void _spawnRemoteOugiVisuals() {
    if (_lastOugiFxCooldown > 0) return;
    _lastOugiFxCooldown = 0.62;

    AudioService.playSfx(AudioService.sfxOugiRelease, volume: 0.85);
    game.add(OugiCelestialFlurryEffect(
      position: Vector2(position.x, position.y - size.y * 0.5),
      facingDirection: facingDirection,
    ));
    game.add(MangaTextEffect(
      position: Vector2(position.x, position.y - size.y - 32),
      text: 'OUGI: CELESTIAL BLADE FLURRY!!',
      fillColor: ComicTheme.comicYellow,
      initialScale: 0.55,
      targetScale: 1.5,
      maxLifetime: 1.1,
    ));
    game.add(MangaDustEffect(position: Vector2(position.x - 38, position.y)));
    game.add(MangaDustEffect(position: Vector2(position.x + 38, position.y)));

    final arcColors = [
      ComicTheme.energyCyan,
      ComicTheme.comicYellow,
      ComicTheme.actionRed,
      ComicTheme.energyCyan,
      ComicTheme.comicYellow,
      ComicTheme.actionRed,
    ];
    for (int i = 0; i < 6; i++) {
      final xOffset = (i - 2.5) * 48.0;
      final yOffset = (i.isEven ? -22.0 : 8.0);
      game.add(SlashArcEffect(
        position: Vector2(
          position.x + xOffset,
          position.y - size.y * 0.5 + yOffset,
        ),
        slashColor: arcColors[i],
        slashFlipped: i.isOdd,
        radius: 64,
      ));
    }
  }

  /// Immediately plays attack/dash/ougi animation and spawns comic VFX when remote player acts
  void triggerRemoteAction({
    required String actionType,
    int comboIndex = 0,
    double? x,
    double? y,
    int? facing,
  }) {
    if (isDying || isCelebrating) return;
    if (x != null && y != null && x.isFinite && y.isFinite) {
      targetPosition.setValues(x, y);
      if (actionType == 'ougi' || position.distanceTo(targetPosition) < 140) {
        position.setValues(x, y);
      }
    }
    if (facing != null) {
      facingDirection = facing < 0 ? -1 : 1;
    }

    if (actionType == 'slash') {
      final idx = comboIndex.clamp(0, 2);
      final attackActions = [
        PlayerAction.attack1,
        PlayerAction.attack2,
        PlayerAction.attack3,
      ];
      action = attackActions[idx];
      _tickers?[action]?.reset();
      _attackAnimLockTimer = 0.28;
      _spawnRemoteSlashVisuals(idx);
    } else if (actionType == 'kunai') {
      action = PlayerAction.attack1;
      _tickers?[action]?.reset();
      _attackAnimLockTimer = 0.22;
      game.add(MangaTextEffect(
        position: Vector2(
          position.x + facingDirection * 24,
          position.y - size.y * 0.75,
        ),
        text: 'KUNAI!!',
        fillColor: ComicTheme.energyCyan,
        initialScale: 0.4,
        targetScale: 0.95,
      ));
    } else if (actionType == 'dash') {
      action = PlayerAction.dashing;
      _tickers?[action]?.reset();
      _attackAnimLockTimer = 0.22;
      AudioService.playSfx(AudioService.sfxDash, volume: 0.75);
      game.add(MangaTextEffect(
        position: Vector2(position.x, position.y - size.y * 0.5),
        text: 'DODODO!',
        fillColor: ComicTheme.energyCyan,
        targetScale: 1.2,
      ));
      game.add(SpeedLineStreakComponent(
        position: Vector2(position.x - 40, position.y - size.y),
        size: Vector2(80, size.y),
        direction: Vector2(facingDirection.toDouble(), 0),
      ));
    } else if (actionType == 'ougi') {
      action = PlayerAction.ougi;
      _tickers?[action]?.reset();
      _attackAnimLockTimer = 0.68;
      _spawnRemoteOugiVisuals();
    }
  }

  void resetForRespawn({
    required double fullHp,
    required int remainingLives,
    Vector2? spawnPos,
  }) {
    isDying = false;
    maxHp = fullHp;
    hp = fullHp;
    lives = remainingLives;
    hitFlashTimer = 0.35;
    _attackAnimLockTimer = 0.0;
    action = PlayerAction.jumping;
    _tickers?[action]?.reset();
    if (spawnPos != null) {
      position.setFrom(spawnPos);
      targetPosition.setFrom(spawnPos);
    }
    game.add(MangaDustEffect(position: position.clone()));
    game.add(MangaTextEffect(
      position: Vector2(position.x, position.y - 64),
      text: '¡$remainingLives ${remainingLives == 1 ? "VIDA" : "VIDAS"}!',
      fillColor: ComicTheme.energyCyan,
      targetScale: 1.5,
    ));
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
      if (lives > 1) {
        lives--;
        hp = maxHp;
      } else {
        lives = 0;
        hp = 0.0;
        isDying = true;
        action = PlayerAction.death;
        _tickers?[action]?.reset();
      }
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
    if (_attackAnimLockTimer > 0) {
      _attackAnimLockTimer -= dt;
    }
    if (_lastSlashFxCooldown > 0) {
      _lastSlashFxCooldown -= dt;
    }
    if (_lastOugiFxCooldown > 0) {
      _lastOugiFxCooldown -= dt;
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

    final isOugi = action == PlayerAction.ougi;
    final isWideSheet = action == PlayerAction.attack1 ||
        action == PlayerAction.attack2 ||
        action == PlayerAction.attack3 ||
        action == PlayerAction.death;
    final renderW = isOugi ? 96.0 : (isWideSheet ? 82.0 : 72.0);
    final renderH = isOugi ? 86.0 : 72.0;
    final celebrationBounce =
        isCelebrating ? math.sin(_celebrationTime * 9.0).abs() * 14.0 : 0.0;

    canvas.save();
    canvas.translate(size.x / 2, size.y + 5 - celebrationBounce);

    if (facingDirection < 0) {
      canvas.scale(-1, 1);
    }

    if (!isDying) {
      if (isOugi) {
        final auraPaint = Paint()
          ..color = ComicTheme.energyCyan.withValues(alpha: 0.42)
          ..style = PaintingStyle.fill;
        canvas.drawOval(
          Rect.fromCenter(center: const Offset(0, -4), width: 78, height: 18),
          auraPaint,
        );
        canvas.drawOval(
          Rect.fromCenter(center: const Offset(0, -4), width: 78, height: 18),
          Paint()
            ..color = ComicTheme.comicYellow
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5,
        );
      } else {
        // Natural dark ground shadow under Kaito's feet (never tinted by skin color!)
        final shadowPaint = Paint()
          ..color = isCelebrating
              ? const Color(0xFFFFD600).withValues(alpha: 0.50)
              : Colors.black.withValues(alpha: 0.38)
          ..style = PaintingStyle.fill;
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(0, -3 + celebrationBounce),
            width: isCelebrating ? 60 : 46,
            height: 11,
          ),
          shadowPaint,
        );
      }
    }

    Paint? overridePaint;
    if (hitFlashTimer > 0) {
      overridePaint = Paint()
        ..colorFilter = const ColorFilter.mode(Colors.white, BlendMode.srcATop);
    } else {
      final skinFilter = MultiplayerColor.createSkinColorFilter(
        playerColor,
        colorIndex: colorIndex,
      );
      if (skinFilter != null) {
        overridePaint = Paint()..colorFilter = skinFilter;
      }
    }

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
