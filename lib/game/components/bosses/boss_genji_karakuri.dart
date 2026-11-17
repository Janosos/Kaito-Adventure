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

enum GenjiState {
  idle,
  rocketLeap,
  sawCleave,
  gearBarrage,
  steamEruption,
  brassAegis,
  recovering,
}

class BossGenjiKarakuri extends BossBase {
  GenjiState state = GenjiState.idle;
  double _stateTimer = 0.0;
  final Random _rnd = Random();
  double _actionInterval = 1.45;
  double _groundY = 0.0;
  bool _phase2Done = false;

  late final SpriteAnimationTicker _idleTicker;
  late final SpriteAnimationTicker _chargeTicker;
  late final SpriteAnimationTicker _cleaveTicker;
  late final SpriteAnimationTicker _guardTicker;
  late final SpriteAnimationTicker _stunTicker;

  BossGenjiKarakuri({
    required super.position,
    super.arenaMinX = 4680.0,
    super.arenaMaxX = 5520.0,
  }) : super(
          name: 'GENJI-KARAKURI',
          title: 'THE CLOCKWORK SHOGUN',
          maxHp: 1700.0,
          size: Vector2(74, 96),
        ) {
    maxPhases = 2;
    _groundY = position.y;
  }

  @override
  Future<void> onLoad() async {
    final imgs = game.images;
    _idleTicker = CartoonAssets.animation(
      imgs,
      'bosses/genji_idle.png',
      frames: 6,
      textureSize: Vector2(240, 220),
      stepTime: 0.09,
    ).createTicker();

    _chargeTicker = CartoonAssets.animation(
      imgs,
      'bosses/genji_charge.png',
      frames: 4,
      textureSize: Vector2(240, 220),
      stepTime: 0.07,
    ).createTicker();

    _cleaveTicker = CartoonAssets.animation(
      imgs,
      'bosses/genji_cleave.png',
      frames: 5,
      textureSize: Vector2(240, 220),
      stepTime: 0.07,
    ).createTicker();

    _guardTicker = CartoonAssets.animation(
      imgs,
      'bosses/genji_guard.png',
      frames: 4,
      textureSize: Vector2(240, 220),
      stepTime: 0.09,
    ).createTicker();

    _stunTicker = CartoonAssets.animation(
      imgs,
      'bosses/genji_stun.png',
      frames: 4,
      textureSize: Vector2(240, 220),
      stepTime: 0.10,
    ).createTicker();

    await super.onLoad();
    add(RectangleHitbox());
  }

  @override
  void checkPhaseTransition() {
    if (!_phase2Done && currentHp <= maxHp * 0.55) {
      _phase2Done = true;
      currentPhase = 2;
      _actionInterval = 0.98;
      AudioService.playSfx(AudioService.sfxBossRoar);
      AudioService.heavyHaptic();
      game.add(MangaTextEffect(
        position: Vector2(position.x, position.y - size.y - 25),
        text: 'OVERDRIVE: FULL STEAM!!',
        fillColor: ComicTheme.comicYellow,
        targetScale: 1.9,
      ));
      game.add(MangaDustEffect(position: position.clone()));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isDefeated) return;

    if (isStunned) {
      state = GenjiState.recovering;
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
    if (state == GenjiState.idle || state == GenjiState.brassAegis) {
      facing = player.position.x > position.x ? 1 : -1;
    }

    switch (state) {
      case GenjiState.idle:
        if (_stateTimer >= _actionInterval) {
          _decideAction();
        }
        break;

      case GenjiState.brassAegis:
        if (_stateTimer >= 0.90) {
          isGuarding = false;
          isCounterStance = false;
          state = GenjiState.gearBarrage;
          _stateTimer = 0.0;
        }
        break;

      case GenjiState.rocketLeap:
        if (_stateTimer >= 0.28) {
          final offset = player.facingDirection == 1 ? -65.0 : 65.0;
          position.x = (player.position.x + offset).clamp(arenaMinX, arenaMaxX);
          position.y = player.position.y.clamp(200.0, _groundY);
          facing = player.position.x > position.x ? 1 : -1;
          game.add(MangaDustEffect(position: position.clone()));
          game.add(MangaTextEffect(
            position: Vector2(position.x, position.y - size.y),
            text: 'STEAM BOOST!!',
            fillColor: Colors.orangeAccent,
          ));
          state = GenjiState.sawCleave;
          _stateTimer = 0.0;
        }
        break;

      case GenjiState.sawCleave:
        if (_stateTimer >= 0.26) {
          game.add(SlashArcEffect(
            position: Vector2(position.x + facing * 42, position.y - 46),
            slashFlipped: facing < 0,
            slashColor: ComicTheme.comicYellow,
            radius: 72,
          ));
          game.add(BossDarkSlashWave(
            position: Vector2(position.x + facing * 30, position.y - 28),
            velocity: Vector2(facing * 410.0, 0),
          ));
          if ((player.position.x - position.x).abs() < 92 &&
              (player.position.y - position.y).abs() < 70) {
            player.takeDamage(1);
          }
          state = GenjiState.recovering;
          _stateTimer = 0.0;
        }
        break;

      case GenjiState.gearBarrage:
        if (_stateTimer >= 0.34) {
          final dy = player.position.y - (position.y - 50);
          final baseA = atan2(dy, (player.position.x - position.x).abs() * facing);
          final spread = currentPhase >= 2
              ? [-0.42, -0.21, 0.0, 0.21, 0.42]
              : [-0.30, 0.0, 0.30];
          for (final a in spread) {
            final ang = baseA + a;
            game.add(BossEnergyOrb(
              position: Vector2(position.x + facing * 28, position.y - 50),
              velocity: Vector2(facing * cos(ang) * 355, sin(ang) * 355),
            ));
          }
          state = GenjiState.recovering;
          _stateTimer = 0.0;
        }
        break;

      case GenjiState.steamEruption:
        if (_stateTimer >= 0.35) {
          final targetY = player.position.y.clamp(200.0, _groundY);
          for (final off in [-170.0, 0.0, 170.0]) {
            game.add(BossFlamePillar(
              position: Vector2(
                (player.position.x + off).clamp(arenaMinX, arenaMaxX),
                targetY,
              ),
              eruptDelay: 0.55,
            ));
          }
          state = GenjiState.recovering;
          _stateTimer = 0.0;
        }
        break;

      case GenjiState.recovering:
        if (position.y < _groundY && player.position.y >= _groundY - 30) {
          position.y = (position.y + 420.0 * dt).clamp(0.0, _groundY);
        }
        if (_stateTimer >= (currentPhase == 2 ? 0.42 : 0.65)) {
          state = GenjiState.idle;
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
      state = GenjiState.rocketLeap;
      return;
    }
    final r = _rnd.nextDouble();
    if (r < 0.28) {
      state = GenjiState.rocketLeap;
    } else if (r < 0.52) {
      state = GenjiState.gearBarrage;
    } else if (r < 0.76) {
      state = GenjiState.steamEruption;
    } else {
      isGuarding = true;
      isCounterStance = true;
      state = GenjiState.brassAegis;
      game.add(MangaTextEffect(
        position: Vector2(position.x, position.y - size.y - 12),
        text: 'BRASS AEGIS! (DASH BEHIND!)',
        fillColor: ComicTheme.comicYellow,
      ));
    }
  }

  SpriteAnimationTicker get _activeTicker {
    if (isStunned) return _stunTicker;
    if (isGuarding || isCounterStance) return _guardTicker;
    switch (state) {
      case GenjiState.rocketLeap:
        return _chargeTicker;
      case GenjiState.sawCleave:
      case GenjiState.gearBarrage:
      case GenjiState.steamEruption:
        return _cleaveTicker;
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
      renderW: 150.0,
      renderH: 140.0,
    );
  }
}
