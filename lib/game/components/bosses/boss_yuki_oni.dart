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

enum YukiState {
  idle,
  charging,
  bullRush,
  glacierSlam,
  blizzardVortex,
  frostArmorGuard,
  blizzardOrbs,
  recovering
}

class BossYukiOni extends BossBase {
  YukiState state = YukiState.idle;
  double _stateTimer = 0.0;
  final Random _rnd = Random();
  double _actionInterval = 1.9;
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
          maxHp: 660.0,
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
      _actionInterval = 1.5;
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
      _actionInterval = 1.15;
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
    if (state == YukiState.idle || state == YukiState.frostArmorGuard) {
      facing = player.position.x > position.x ? 1 : -1;
    }

    switch (state) {
      case YukiState.idle:
        if (_stateTimer >= _actionInterval) {
          _decideAction();
        }
        break;

      case YukiState.frostArmorGuard:
        if (_stateTimer >= 1.05) {
          isGuarding = false;
          isCounterStance = false;
          state = YukiState.glacierSlam;
          _stateTimer = 0.0;
        }
        break;

      case YukiState.charging:
        if (_stateTimer >= 0.40) {
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
        position.x += facing * 530.0 * dt;
        if ((player.position.x - position.x).abs() < 56 &&
            (player.position.y - position.y).abs() < 58) {
          player.takeDamage(1);
        }
        if (_stateTimer >= 0.46 ||
            position.x <= arenaMinX ||
            position.x >= arenaMaxX) {
          position.x = position.x.clamp(arenaMinX, arenaMaxX);
          // Chain into a Kanabo shockwave slam at the end of the bull rush!
          game.add(BossDarkSlashWave(
            position: Vector2(position.x + facing * 28, _groundY - 24),
            velocity: Vector2(facing * 390.0, 0),
          ));
          state = YukiState.recovering;
          _stateTimer = 0.0;
        }
        break;

      case YukiState.glacierSlam:
        if (_stateTimer >= 0.38) {
          game.add(MangaDustEffect(position: position.clone()));
          game.add(BossDarkSlashWave(
            position: Vector2(position.x - 30, _groundY - 24),
            velocity: Vector2(-390, 0),
          ));
          game.add(BossDarkSlashWave(
            position: Vector2(position.x + 30, _groundY - 24),
            velocity: Vector2(390, 0),
          ));
          // Sequential marching glacier pillars toward Kaito!
          for (int step = 1; step <= (currentPhase >= 2 ? 3 : 2); step++) {
            final pillarX =
                (position.x + facing * step * 115.0).clamp(arenaMinX, arenaMaxX);
            game.add(BossFlamePillar(
              position: Vector2(pillarX, _groundY),
              eruptDelay: 0.40 + step * 0.16,
            ));
          }
          state = YukiState.recovering;
          _stateTimer = 0.0;
        }
        break;

      case YukiState.blizzardVortex:
        // Pushes Kaito back with a freezing blizzard crosswind while firing ice orbs!
        player.externalWindX = facing * 135.0;
        if (_stateTimer >= 0.55) {
          for (final a in [-0.30, 0.0, 0.30]) {
            game.add(BossEnergyOrb(
              position: Vector2(position.x + facing * 34, position.y - 46),
              velocity: Vector2(facing * cos(a) * 350, sin(a) * 350),
            ));
          }
          state = YukiState.recovering;
          _stateTimer = 0.0;
        }
        break;

      case YukiState.blizzardOrbs:
        if (_stateTimer >= 0.40) {
          for (final a in [-0.42, -0.18, 0.05, 0.28, 0.45]) {
            game.add(BossEnergyOrb(
              position: Vector2(position.x + facing * 34, position.y - 52),
              velocity: Vector2(facing * cos(a) * 355, sin(a) * 355),
            ));
          }
          state = YukiState.recovering;
          _stateTimer = 0.0;
        }
        break;

      case YukiState.recovering:
        if (_stateTimer >= (currentPhase == 3 ? 0.36 : 0.68)) {
          state = YukiState.idle;
          _stateTimer = 0.0;
        }
        break;
    }

    _activeTicker.update(dt);
  }

  void _decideAction() {
    _stateTimer = 0.0;
    isGuarding = false;
    isCounterStance = false;
    final r = _rnd.nextDouble();
    if (r < 0.24) {
      state = YukiState.charging;
    } else if (r < 0.50) {
      state = YukiState.glacierSlam;
    } else if (r < 0.72) {
      state = YukiState.blizzardVortex;
      game.add(MangaTextEffect(
        position: Vector2(position.x, position.y - size.y - 10),
        text: 'BLIZZARD GALE!!',
        fillColor: ComicTheme.energyCyan,
      ));
    } else if (r < 0.86) {
      state = YukiState.blizzardOrbs;
    } else {
      isGuarding = true;
      isCounterStance = true;
      state = YukiState.frostArmorGuard;
      game.add(MangaTextEffect(
        position: Vector2(position.x, position.y - size.y - 10),
        text: 'FROST ARMOR! (BACKSTAB!)',
        fillColor: Colors.lightBlueAccent,
      ));
    }
  }

  SpriteAnimationTicker get _activeTicker {
    if (isStunned) return _stunTicker;
    switch (state) {
      case YukiState.charging:
      case YukiState.bullRush:
      case YukiState.frostArmorGuard:
        return _chargeTicker;
      case YukiState.glacierSlam:
      case YukiState.blizzardOrbs:
      case YukiState.blizzardVortex:
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
    if (facing < 0) {
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
