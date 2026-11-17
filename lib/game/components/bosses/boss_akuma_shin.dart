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

enum AkumaState {
  idle,
  cosmicWarpStrike,
  supernovaSlash,
  dimensionCutChain,
  primordialPillars,
  astralBarrage,
  voidMirrorCounter,
  recovering,
}

class BossAkumaShin extends BossBase {
  AkumaState state = AkumaState.idle;
  double _stateTimer = 0.0;
  final Random _rnd = Random();
  double _actionInterval = 1.35;
  double _groundY = 0.0;
  int _chainBlinksRemaining = 0;
  bool _phase2Done = false;
  bool _phase3Done = false;

  late final SpriteAnimationTicker _idleTicker;
  late final SpriteAnimationTicker _slashTicker;
  late final SpriteAnimationTicker _castTicker;
  late final SpriteAnimationTicker _guardTicker;
  late final SpriteAnimationTicker _stunTicker;

  BossAkumaShin({
    required super.position,
    super.arenaMinX = 4880.0,
    super.arenaMaxX = 5760.0,
  }) : super(
          name: 'AKUMA-SHIN',
          title: 'THE PRIMORDIAL INK GOD',
          maxHp: 2400.0,
          size: Vector2(78, 102),
        ) {
    maxPhases = 3;
    _groundY = position.y;
  }

  @override
  Future<void> onLoad() async {
    final imgs = game.images;
    _idleTicker = CartoonAssets.animation(
      imgs,
      'bosses/akuma_idle.png',
      frames: 6,
      textureSize: Vector2(240, 220),
      stepTime: 0.08,
    ).createTicker();

    _slashTicker = CartoonAssets.animation(
      imgs,
      'bosses/akuma_slash.png',
      frames: 5,
      textureSize: Vector2(240, 220),
      stepTime: 0.06,
    ).createTicker();

    _castTicker = CartoonAssets.animation(
      imgs,
      'bosses/akuma_cast.png',
      frames: 5,
      textureSize: Vector2(240, 220),
      stepTime: 0.07,
    ).createTicker();

    _guardTicker = CartoonAssets.animation(
      imgs,
      'bosses/akuma_guard.png',
      frames: 4,
      textureSize: Vector2(240, 220),
      stepTime: 0.08,
    ).createTicker();

    _stunTicker = CartoonAssets.animation(
      imgs,
      'bosses/akuma_stun.png',
      frames: 4,
      textureSize: Vector2(240, 220),
      stepTime: 0.09,
    ).createTicker();

    await super.onLoad();
    add(RectangleHitbox());
  }

  @override
  void onCounterTriggered() {
    super.onCounterTriggered();
    final behind = game.player.facingDirection == 1 ? -70.0 : 70.0;
    position.x = (game.player.position.x + behind).clamp(arenaMinX, arenaMaxX);
    position.y = game.player.position.y.clamp(190.0, _groundY);
    facing = game.player.position.x > position.x ? 1 : -1;
    state = AkumaState.supernovaSlash;
    _stateTimer = 0.0;
  }

  @override
  void checkPhaseTransition() {
    if (!_phase2Done && currentHp <= maxHp * 0.66) {
      _phase2Done = true;
      currentPhase = 2;
      _actionInterval = 0.96;
      AudioService.playSfx(AudioService.sfxBossRoar);
      AudioService.heavyHaptic();
      game.add(MangaTextEffect(
        position: Vector2(position.x, position.y - size.y - 25),
        text: 'PHASE 2: ASTRAL SUPERNOVA!!',
        fillColor: ComicTheme.comicYellow,
        targetScale: 1.95,
      ));
      game.add(MangaDustEffect(position: position.clone()));
    } else if (!_phase3Done && currentHp <= maxHp * 0.33) {
      _phase3Done = true;
      currentPhase = 3;
      _actionInterval = 0.72;
      AudioService.playSfx(AudioService.sfxBossRoar);
      AudioService.heavyHaptic();
      game.add(MangaTextEffect(
        position: Vector2(position.x, position.y - size.y - 25),
        text: 'FINAL PHASE: END OF CREATION!!',
        fillColor: const Color(0xFFD500F9),
        targetScale: 2.15,
      ));
      game.add(MangaDustEffect(position: position.clone()));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isDefeated) return;

    if (isStunned) {
      state = AkumaState.recovering;
      resolveAndUpdateBossTicker(
        dt,
        desiredTicker: _stunTicker,
        idleTicker: _idleTicker,
        stunTicker: _stunTicker,
      );
      return;
    }

    _stateTimer += dt;
    final player = game.player;
    if (state == AkumaState.idle || state == AkumaState.voidMirrorCounter) {
      facing = player.position.x > position.x ? 1 : -1;
    }

    switch (state) {
      case AkumaState.idle:
        if (_stateTimer >= _actionInterval) {
          _decideAction();
        }
        break;

      case AkumaState.voidMirrorCounter:
        if (_stateTimer >= 0.85) {
          isCounterStance = false;
          isGuarding = false;
          state = AkumaState.astralBarrage;
          _stateTimer = 0.0;
        }
        break;

      case AkumaState.cosmicWarpStrike:
        if (_stateTimer >= 0.25) {
          final behind = player.facingDirection == 1 ? -70.0 : 70.0;
          position.x = (player.position.x + behind).clamp(arenaMinX, arenaMaxX);
          position.y = player.position.y.clamp(190.0, _groundY);
          facing = player.position.x > position.x ? 1 : -1;
          game.add(MangaDustEffect(position: position.clone()));
          state = AkumaState.supernovaSlash;
          _stateTimer = 0.0;
        }
        break;

      case AkumaState.supernovaSlash:
        if (_stateTimer >= 0.24) {
          game.add(SlashArcEffect(
            position: Vector2(position.x + facing * 42, position.y - 50),
            slashFlipped: facing < 0,
            slashColor: ComicTheme.darkPurple,
            radius: 78,
          ));
          game.add(BossDarkSlashWave(
            position: Vector2(position.x + facing * 34, position.y - 30),
            velocity: Vector2(facing * 455.0, 0),
          ));
          if ((player.position.x - position.x).abs() < 98 &&
              (player.position.y - position.y).abs() < 78) {
            player.takeDamage(1);
          }
          if (_chainBlinksRemaining > 0) {
            _chainBlinksRemaining--;
            state = AkumaState.dimensionCutChain;
            _stateTimer = 0.0;
          } else {
            state = AkumaState.recovering;
            _stateTimer = 0.0;
          }
        }
        break;

      case AkumaState.dimensionCutChain:
        if (_stateTimer >= 0.22) {
          final side = (_chainBlinksRemaining % 2 == 0) ? 84.0 : -84.0;
          position.x = (player.position.x + side).clamp(arenaMinX, arenaMaxX);
          position.y = player.position.y.clamp(190.0, _groundY);
          facing = player.position.x > position.x ? 1 : -1;
          game.add(MangaDustEffect(position: position.clone()));
          game.add(MangaTextEffect(
            position: Vector2(position.x, position.y - size.y),
            text: 'VOID FLASH!!',
            fillColor: ComicTheme.comicYellow,
          ));
          state = AkumaState.supernovaSlash;
          _stateTimer = 0.0;
        }
        break;

      case AkumaState.primordialPillars:
        if (_stateTimer >= 0.32) {
          final targetY = player.position.y.clamp(190.0, _groundY);
          final offsets = currentPhase >= 2
              ? [-220.0, -110.0, 0.0, 110.0, 220.0]
              : [-160.0, 0.0, 160.0];
          for (final off in offsets) {
            game.add(BossFlamePillar(
              position: Vector2(
                (player.position.x + off).clamp(arenaMinX, arenaMaxX),
                targetY,
              ),
              eruptDelay: 0.48,
            ));
          }
          game.add(BossDarkSlashWave(
            position: Vector2(position.x - 28, position.y - 26),
            velocity: Vector2(-410.0, 0),
          ));
          game.add(BossDarkSlashWave(
            position: Vector2(position.x + 28, position.y - 26),
            velocity: Vector2(410.0, 0),
          ));
          state = AkumaState.recovering;
          _stateTimer = 0.0;
        }
        break;

      case AkumaState.astralBarrage:
        if (_stateTimer >= 0.34) {
          final dy = player.position.y - (position.y - 54);
          final baseA = atan2(dy, (player.position.x - position.x).abs() * facing);
          final angles = currentPhase >= 2
              ? [-0.56, -0.38, -0.19, 0.0, 0.19, 0.38, 0.56]
              : [-0.46, -0.23, 0.0, 0.23, 0.46];
          for (final a in angles) {
            final ang = baseA + a;
            game.add(BossEnergyOrb(
              position: Vector2(position.x + facing * 30, position.y - 54),
              velocity: Vector2(facing * cos(ang) * 395, sin(ang) * 395),
            ));
          }
          state = AkumaState.recovering;
          _stateTimer = 0.0;
        }
        break;

      case AkumaState.recovering:
        if (position.y < _groundY && player.position.y >= _groundY - 30) {
          position.y = (position.y + 460.0 * dt).clamp(0.0, _groundY);
        }
        if (_stateTimer >= (currentPhase == 3 ? 0.28 : 0.48)) {
          state = AkumaState.idle;
          _stateTimer = 0.0;
        }
        break;
    }

    resolveAndUpdateBossTicker(
      dt,
      desiredTicker: _activeTicker,
      idleTicker: _idleTicker,
      stunTicker: _stunTicker,
    );
  }

  void _decideAction() {
    _stateTimer = 0.0;
    isGuarding = false;
    isCounterStance = false;
    final player = game.player;
    if (player.position.y < _groundY - 45.0) {
      _chainBlinksRemaining = currentPhase >= 2 ? 2 : 1;
      state = AkumaState.cosmicWarpStrike;
      return;
    }
    final r = _rnd.nextDouble();
    if (r < 0.30) {
      _chainBlinksRemaining = currentPhase >= 2 ? 2 : 1;
      state = AkumaState.cosmicWarpStrike;
    } else if (r < 0.50) {
      _chainBlinksRemaining = 0;
      state = AkumaState.supernovaSlash;
    } else if (r < 0.70) {
      state = AkumaState.primordialPillars;
    } else if (r < 0.86) {
      state = AkumaState.astralBarrage;
    } else {
      isGuarding = true;
      isCounterStance = true;
      state = AkumaState.voidMirrorCounter;
      game.add(MangaTextEffect(
        position: Vector2(position.x, position.y - size.y - 12),
        text: 'PRIMORDIAL MIRROR! (DASH BEHIND!)',
        fillColor: const Color(0xFFD500F9),
      ));
    }
  }

  SpriteAnimationTicker get _activeTicker {
    if (isStunned) return _stunTicker;
    if (isGuarding || isCounterStance) return _guardTicker;
    switch (state) {
      case AkumaState.supernovaSlash:
        return _slashTicker;
      case AkumaState.primordialPillars:
      case AkumaState.astralBarrage:
      case AkumaState.cosmicWarpStrike:
      case AkumaState.dimensionCutChain:
        return _castTicker;
      default:
        return _idleTicker;
    }
  }

  @override
  void render(Canvas canvas) {
    renderBossAnimated(
      canvas,
      desiredTicker: _activeTicker,
      idleTicker: _idleTicker,
      renderW: 156.0,
      renderH: 146.0,
    );
  }
}
