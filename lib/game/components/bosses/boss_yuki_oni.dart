import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:manga_platformer/game/cartoon_assets.dart';
import 'package:manga_platformer/ui/comic_theme.dart';
import '../manga_effects.dart';
import '../projectiles.dart';
import 'boss_base.dart';

enum YukiState { idle, charging, bullRush, glacierSlam, blizzardOrbs, recovering }

class BossYukiOni extends BossBase {
  YukiState state = YukiState.idle;
  double _stateTimer = 0.0;
  int _facing = -1;
  final Random _rnd = Random();
  double _actionInterval = 2.2;
  double _groundY = 0.0;
  bool _phase2Done = false;
  bool _phase3Done = false;

  late final SpriteAnimationTicker _idleTicker;
  late final SpriteAnimationTicker _chargeTicker;
  late final SpriteAnimationTicker _slamTicker;
  late final SpriteAnimationTicker _stunTicker;

  BossYukiOni({
    required super.position,
    super.arenaMinX = 2540.0,
    super.arenaMaxX = 3340.0,
  }) : super(
          name: 'YUKI-ONI',
          title: 'THE FROST TITAN',
          maxHp: 440.0,
          size: Vector2(78, 98),
        ) {
    maxPhases = 3;
    _groundY = position.y;
  }

  @override
  Future<void> onLoad() async {
    final imgs = game.images;
    _idleTicker = CartoonAssets.animation(
      imgs,
      'bosses/yuki_idle.png',
      frames: 6,
      textureSize: Vector2(240, 220),
      stepTime: 0.1,
    ).createTicker();

    _chargeTicker = CartoonAssets.animation(
      imgs,
      'bosses/yuki_charge.png',
      frames: 4,
      textureSize: Vector2(240, 220),
      stepTime: 0.08,
    ).createTicker();

    _slamTicker = CartoonAssets.animation(
      imgs,
      'bosses/yuki_slam.png',
      frames: 6,
      textureSize: Vector2(240, 220),
      stepTime: 0.08,
    ).createTicker();

    _stunTicker = CartoonAssets.animation(
      imgs,
      'bosses/yuki_stun.png',
      frames: 4,
      textureSize: Vector2(240, 220),
      stepTime: 0.1,
    ).createTicker();

    await super.onLoad();
    add(RectangleHitbox());
  }

  @override
  void checkPhaseTransition() {
    if (!_phase2Done && currentHp <= maxHp * 0.66) {
      _phase2Done = true;
      currentPhase = 2;
      _actionInterval = 1.75;
      game.triggerBossCutIn(
        bossName: 'YUKI-ONI',
        quote: 'MY KANABO SHALL SHATTER BONE AND FREEZE YOUR SOUL!!',
        portraitColor: ComicTheme.energyCyan,
        portraitAsset: CartoonAssets.portraitYukiOni,
      );
      game.add(MangaTextEffect(
        position: Vector2(position.x, position.y - size.y - 25),
        text: 'PHASE 2: AVALANCHE RAGE!!',
        fillColor: ComicTheme.energyCyan,
        targetScale: 1.8,
      ));
    } else if (!_phase3Done && currentHp <= maxHp * 0.33) {
      _phase3Done = true;
      currentPhase = 3;
      _actionInterval = 1.3;
      game.triggerBossCutIn(
        bossName: 'YUKI-ONI',
        quote: 'ABSOLUTE ZERO OVERDRIVE!! ROOOAAAR!!',
        portraitColor: Colors.lightBlueAccent,
        portraitAsset: CartoonAssets.portraitYukiOni,
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isDefeated) return;

    if (isStunned) {
      state = YukiState.recovering;
      _stunTicker.update(dt);
      return;
    }

    _stateTimer += dt;
    final player = game.player;
    if (state == YukiState.idle) {
      _facing = player.position.x > position.x ? 1 : -1;
    }

    switch (state) {
      case YukiState.idle:
        if (_stateTimer >= _actionInterval) {
          _decideAction();
        }
        break;

      case YukiState.charging:
        if (_stateTimer >= 0.45) {
          state = YukiState.bullRush;
          _stateTimer = 0.0;
          game.add(MangaTextEffect(
            position: position.clone(),
            text: 'DOGOOOON!!',
            fillColor: ComicTheme.energyCyan,
          ));
        }
        break;

      case YukiState.bullRush:
        position.x += _facing * 490.0 * dt;
        if ((player.position.x - position.x).abs() < 55 &&
            (player.position.y - position.y).abs() < 58) {
          player.takeDamage(1);
        }
        if (_stateTimer >= 0.5 ||
            position.x <= arenaMinX ||
            position.x >= arenaMaxX) {
          position.x = position.x.clamp(arenaMinX, arenaMaxX);
          state = YukiState.recovering;
          _stateTimer = 0.0;
        }
        break;

      case YukiState.glacierSlam:
        if (_stateTimer >= 0.42) {
          game.add(MangaDustEffect(position: position.clone()));
          game.add(BossDarkSlashWave(
            position: Vector2(position.x - 30, _groundY - 24),
            velocity: Vector2(-360, 0),
          ));
          game.add(BossDarkSlashWave(
            position: Vector2(position.x + 30, _groundY - 24),
            velocity: Vector2(360, 0),
          ));
          if (currentPhase >= 2) {
            game.add(BossFlamePillar(
              position: Vector2(player.position.x, _groundY),
              eruptDelay: 0.65,
            ));
          }
          state = YukiState.recovering;
          _stateTimer = 0.0;
        }
        break;

      case YukiState.blizzardOrbs:
        if (_stateTimer >= 0.45) {
          for (final a in [-0.4, -0.15, 0.1, 0.35]) {
            game.add(BossEnergyOrb(
              position: Vector2(position.x + _facing * 34, position.y - 52),
              velocity: Vector2(_facing * cos(a) * 340, sin(a) * 340),
            ));
          }
          state = YukiState.recovering;
          _stateTimer = 0.0;
        }
        break;

      case YukiState.recovering:
        if (_stateTimer >= (currentPhase == 3 ? 0.4 : 0.75)) {
          state = YukiState.idle;
          _stateTimer = 0.0;
        }
        break;
    }

    _activeTicker.update(dt);
  }

  void _decideAction() {
    _stateTimer = 0.0;
    final r = _rnd.nextDouble();
    if (r < 0.38) {
      state = YukiState.charging;
    } else if (r < 0.72) {
      state = YukiState.glacierSlam;
    } else {
      state = YukiState.blizzardOrbs;
    }
  }

  SpriteAnimationTicker get _activeTicker {
    if (isStunned) return _stunTicker;
    switch (state) {
      case YukiState.charging:
      case YukiState.bullRush:
        return _chargeTicker;
      case YukiState.glacierSlam:
      case YukiState.blizzardOrbs:
        return _slamTicker;
      default:
        return _idleTicker;
    }
  }

  @override
  void render(Canvas canvas) {
    if (isDefeated) return;
    final sprite = _activeTicker.getSprite();
    const renderW = 152.0;
    const renderH = 140.0;

    canvas.save();
    canvas.translate(size.x / 2, size.y + 6);
    if (_facing < 0) {
      canvas.scale(-1, 1);
    }

    final overridePaint = hitFlashTimer > 0
        ? (Paint()
          ..colorFilter =
              const ColorFilter.mode(Colors.white, BlendMode.srcATop))
        : null;

    sprite.render(
      canvas,
      position: Vector2(-renderW * 0.45, -renderH),
      size: Vector2(renderW, renderH),
      overridePaint: overridePaint,
    );
    canvas.restore();
  }
}

