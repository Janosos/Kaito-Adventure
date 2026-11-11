import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:manga_platformer/game/cartoon_assets.dart';
import 'package:manga_platformer/game/services/audio_service.dart';
import 'package:manga_platformer/ui/comic_theme.dart';
import '../manga_effects.dart';
import '../projectiles.dart';
import 'boss_base.dart';

enum KurokageState {
  idle,
  charging,
  cleaving,
  crossDashSlash,
  aerialDivePrep,
  aerialDivePlunge,
  shockwave,
  teleporting,
  counterStance,
  recovering
}

class BossKurokage extends BossBase {
  KurokageState state = KurokageState.idle;
  double _stateTimer = 0.0;
  final Random _rnd = Random();
  double _groundY = 0.0;
  double _actionInterval = 2.0;

  late final SpriteAnimationTicker _idleTicker;
  late final SpriteAnimationTicker _chargeTicker;
  late final SpriteAnimationTicker _cleaveTicker;
  late final SpriteAnimationTicker _guardTicker;
  late final SpriteAnimationTicker _stunTicker;

  BossKurokage({
    required super.position,
    super.arenaMinX = 2540.0,
    super.arenaMaxX = 3340.0,
  }) : super(
          name: 'KUROKAGE',
          title: 'THE SHADOW EXECUTIONER',
          maxHp: 380.0,
          size: Vector2(58, 76),
        ) {
    maxPhases = 2;
    _groundY = position.y;
  }

  @override
  Future<void> onLoad() async {
    final imgs = game.images;
    _idleTicker = CartoonAssets.animation(
      imgs,
      'bosses/kurokage_idle.png',
      frames: 6,
      textureSize: Vector2(200, 180),
      stepTime: 0.1,
    ).createTicker();

    _chargeTicker = CartoonAssets.animation(
      imgs,
      'bosses/kurokage_charge.png',
      frames: 4,
      textureSize: Vector2(200, 180),
      stepTime: 0.08,
    ).createTicker();

    _cleaveTicker = CartoonAssets.animation(
      imgs,
      'bosses/kurokage_cleave.png',
      frames: 5,
      textureSize: Vector2(200, 180),
      stepTime: 0.07,
      loop: false,
    ).createTicker();

    _guardTicker = CartoonAssets.animation(
      imgs,
      'bosses/kurokage_guard.png',
      frames: 4,
      textureSize: Vector2(200, 180),
      stepTime: 0.09,
    ).createTicker();

    _stunTicker = CartoonAssets.animation(
      imgs,
      'bosses/kurokage_stun.png',
      frames: 4,
      textureSize: Vector2(200, 180),
      stepTime: 0.11,
    ).createTicker();

    await super.onLoad();
    add(RectangleHitbox());
  }

  @override
  void checkPhaseTransition() {
    if (currentPhase == 1 && currentHp <= maxHp * 0.5) {
      currentPhase = 2;
      _actionInterval = 1.15;
      AudioService.playSfx(AudioService.sfxBossRoar);
      AudioService.heavyHaptic();
      game.add(MangaTextEffect(
        position: Vector2(position.x, position.y - size.y - 30),
        text: 'PHASE 2: SHADOW MIRAGE!!',
        fillColor: ComicTheme.actionRed,
        targetScale: 1.8,
      ));
      game.add(MangaDustEffect(position: position.clone()));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isDefeated) return;

    if (isStunned) {
      position.y = _groundY;
      state = KurokageState.recovering;
      _stunTicker.update(dt);
      return;
    }

    _stateTimer += dt;
    final player = game.player;

    if (state == KurokageState.idle || state == KurokageState.counterStance) {
      facing = player.position.x > position.x ? 1 : -1;
    }

    switch (state) {
      case KurokageState.idle:
        if (_stateTimer >= _actionInterval) {
          _decideNextAction();
        }
        break;

      case KurokageState.counterStance:
        if (_stateTimer >= 1.05) {
          isCounterStance = false;
          isGuarding = false;
          state = KurokageState.shockwave;
          _chargeTicker.reset();
          _stateTimer = 0.0;
        }
        break;

      case KurokageState.teleporting:
        if (_stateTimer >= 0.34) {
          final behindOffset = player.facingDirection == 1 ? -68.0 : 68.0;
          position.x =
              (player.position.x + behindOffset).clamp(arenaMinX, arenaMaxX);
          // Seamlessly teleport to player's platform height so safe spots are eliminated!
          position.y = player.position.y.clamp(280.0, _groundY);
          facing = player.position.x > position.x ? 1 : -1;

          game.add(MangaTextEffect(
            position: position.clone(),
            text: 'SHADOW BLINK!',
            fillColor: ComicTheme.energyCyan,
          ));
          game.add(MangaDustEffect(position: position.clone()));

          state = KurokageState.charging;
          _chargeTicker.reset();
          _stateTimer = 0.0;
        }
        break;

      case KurokageState.charging:
        if (_stateTimer >= (currentPhase == 2 ? 0.32 : 0.50)) {
          _executeCleave();
        }
        break;

      case KurokageState.cleaving:
        if (_stateTimer >= 0.36) {
          // In Phase 2, chain a cross-up shadow dash right after cleaving!
          if (currentPhase == 2 && _rnd.nextDouble() < 0.65) {
            state = KurokageState.crossDashSlash;
            facing = player.position.x > position.x ? 1 : -1;
            _stateTimer = 0.0;
            game.add(MangaTextEffect(
              position: Vector2(position.x, position.y - size.y),
              text: 'DOUBLE SHADOW CROSS!!',
              fillColor: ComicTheme.comicYellow,
            ));
          } else {
            state = KurokageState.recovering;
            _stateTimer = 0.0;
          }
        }
        break;

      case KurokageState.crossDashSlash:
        position.x = (position.x + facing * 540.0 * dt)
            .clamp(arenaMinX, arenaMaxX);
        if ((player.position.x - position.x).abs() < 48 &&
            (player.position.y - position.y).abs() < 55) {
          player.takeDamage(1);
        }
        if (_stateTimer >= 0.34) {
          _fireShockwave();
          state = KurokageState.recovering;
          _stateTimer = 0.0;
        }
        break;

      case KurokageState.aerialDivePrep:
        position.y = (_groundY - 165.0 * (_stateTimer / 0.38).clamp(0.0, 1.0));
        position.x +=
            ((player.position.x - position.x).clamp(-220.0, 220.0)) * dt * 2.4;
        position.x = position.x.clamp(arenaMinX, arenaMaxX);
        if (_stateTimer >= 0.42) {
          state = KurokageState.aerialDivePlunge;
          _stateTimer = 0.0;
          game.add(MangaTextEffect(
            position: Vector2(position.x, position.y - 30),
            text: 'GUILLOTINE DROP!!',
            fillColor: ComicTheme.actionRed,
          ));
        }
        break;

      case KurokageState.aerialDivePlunge:
        position.y += 750.0 * dt;
        final targetLandY =
            (player.position.y < _groundY - 40.0) ? player.position.y : _groundY;
        if (position.y >= targetLandY) {
          position.y = targetLandY;
          game.add(MangaDustEffect(position: position.clone()));
          // Twin left & right ground/platform shockwaves on impact!
          game.add(BossDarkSlashWave(
            position: Vector2(position.x - 24, position.y - 26),
            velocity: Vector2(-380.0, 0),
          ));
          game.add(BossDarkSlashWave(
            position: Vector2(position.x + 24, position.y - 26),
            velocity: Vector2(380.0, 0),
          ));
          state = KurokageState.recovering;
          _stateTimer = 0.0;
        }
        break;

      case KurokageState.shockwave:
        if (_stateTimer >= 0.32) {
          _fireShockwave();
          if (currentPhase == 2) {
            // Second high-arcing orb in Phase 2 so player must time their jump
            game.add(BossEnergyOrb(
              position: Vector2(position.x + facing * 30, position.y - 68),
              velocity: Vector2(facing * 320.0, -35.0),
            ));
          }
          state = KurokageState.recovering;
          _stateTimer = 0.0;
        }
        break;

      case KurokageState.recovering:
        // If player drops to floor while boss is on a platform, boss drops down to pursue
        if (position.y < _groundY && player.position.y >= _groundY - 30) {
          position.y = (position.y + 420.0 * dt).clamp(0.0, _groundY);
        }
        if (_stateTimer >= (currentPhase == 2 ? 0.34 : 0.62)) {
          state = KurokageState.idle;
          _stateTimer = 0.0;
        }
        break;
    }

    _activeTicker.update(dt);
  }

  SpriteAnimationTicker get _activeTicker {
    if (isStunned) return _stunTicker;
    if (isGuarding || isCounterStance) return _guardTicker;
    switch (state) {
      case KurokageState.charging:
      case KurokageState.shockwave:
      case KurokageState.aerialDivePrep:
        return _chargeTicker;
      case KurokageState.cleaving:
      case KurokageState.crossDashSlash:
      case KurokageState.aerialDivePlunge:
        return _cleaveTicker;
      default:
        return _idleTicker;
    }
  }

  void _decideNextAction() {
    _stateTimer = 0.0;
    isGuarding = false;
    isCounterStance = false;

    final player = game.player;
    final dist = (player.position.x - position.x).abs();
    final isPlayerElevated = player.position.y < _groundY - 45.0;
    final r = _rnd.nextDouble();

    // If player is camping on elevated platforms, relentlessly pursue onto the platform!
    if (isPlayerElevated) {
      if (r < 0.55) {
        state = KurokageState.teleporting;
        game.add(MangaDustEffect(position: position.clone()));
      } else {
        state = KurokageState.aerialDivePrep;
        game.add(MangaDustEffect(position: position.clone()));
      }
      return;
    }

    if (dist > 175 || r < 0.35) {
      if (r < 0.18) {
        state = KurokageState.aerialDivePrep;
        game.add(MangaDustEffect(position: position.clone()));
      } else if (_rnd.nextBool()) {
        state = KurokageState.teleporting;
        game.add(MangaDustEffect(position: position.clone()));
      } else {
        state = KurokageState.shockwave;
        _chargeTicker.reset();
      }
    } else {
      if (r < 0.28) {
        isCounterStance = true;
        isGuarding = true;
        state = KurokageState.counterStance;
        game.add(MangaTextEffect(
          position: Vector2(position.x, position.y - size.y - 10),
          text: 'SHADOW PARRY! (DASH BEHIND!)',
          fillColor: ComicTheme.comicYellow,
          initialScale: 0.6,
        ));
      } else if (r < 0.55) {
        state = KurokageState.aerialDivePrep;
      } else {
        state = KurokageState.charging;
        _chargeTicker.reset();
      }
    }
  }

  void _executeCleave() {
    state = KurokageState.cleaving;
    _cleaveTicker.reset();
    _stateTimer = 0.0;

    game.add(SlashArcEffect(
      position: Vector2(position.x + facing * 35, position.y - size.y * 0.5),
      slashFlipped: facing < 0,
      radius: 68,
      slashColor: ComicTheme.darkPurple,
    ));

    game.add(MangaTextEffect(
      position: Vector2(position.x + facing * 40, position.y - size.y * 0.7),
      text: 'ZUBATTO!!',
      fillColor: ComicTheme.actionRed,
      targetScale: 1.5,
    ));

    final player = game.player;
    final dx = player.position.x - position.x;
    final inFront = (facing > 0 && dx > 0) || (facing < 0 && dx < 0);
    if (inFront &&
        dx.abs() < 96 &&
        (player.position.y - position.y).abs() < 85) {
      player.takeDamage(1);
    }
  }

  void _fireShockwave() {
    game.add(BossDarkSlashWave(
      position: Vector2(position.x + facing * 25, position.y - 26),
      velocity: Vector2(facing * 390.0, 0),
    ));

    game.add(MangaTextEffect(
      position: Vector2(position.x, position.y - size.y * 0.8),
      text: 'DODODO!',
      fillColor: ComicTheme.actionRed,
    ));
  }

  @override
  void render(Canvas canvas) {
    if (isDefeated) return;

    final sprite = _activeTicker.getSprite();
    const renderW = 120.0;
    const renderH = 108.0;

    canvas.save();
    canvas.translate(size.x / 2, size.y + 6);
    if (facing < 0) {
      canvas.scale(-1, 1);
    }

    final overridePaint = hitFlashTimer > 0
        ? (Paint()
          ..colorFilter = const ColorFilter.mode(
            Colors.white,
            BlendMode.srcATop,
          ))
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
