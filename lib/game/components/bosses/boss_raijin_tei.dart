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

enum RaijinState {
  idle,
  lightningBlink,
  thunderSlash,
  skyBolts,
  taikoShockwave,
  thunderAegis,
  recovering,
}

class BossRaijinTei extends BossBase {
  RaijinState state = RaijinState.idle;
  double _stateTimer = 0.0;
  final Random _rnd = Random();
  double _actionInterval = 1.30;
  double _groundY = 0.0;
  bool _phase2Done = false;

  late final SpriteAnimationTicker _idleTicker;
  late final SpriteAnimationTicker _dashTicker;
  late final SpriteAnimationTicker _castTicker;
  late final SpriteAnimationTicker _guardTicker;
  late final SpriteAnimationTicker _stunTicker;

  BossRaijinTei({
    required super.position,
    super.arenaMinX = 4680.0,
    super.arenaMaxX = 5520.0,
  }) : super(
          name: 'RAIJIN-TEI',
          title: 'THE THUNDER EMPEROR',
          maxHp: 2150.0,
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
      'bosses/raijin_idle.png',
      frames: 6,
      textureSize: Vector2(240, 220),
      stepTime: 0.08,
    ).createTicker();

    _dashTicker = CartoonAssets.animation(
      imgs,
      'bosses/raijin_dash.png',
      frames: 4,
      textureSize: Vector2(240, 220),
      stepTime: 0.06,
    ).createTicker();

    _castTicker = CartoonAssets.animation(
      imgs,
      'bosses/raijin_cast.png',
      frames: 5,
      textureSize: Vector2(240, 220),
      stepTime: 0.07,
    ).createTicker();

    _guardTicker = CartoonAssets.animation(
      imgs,
      'bosses/raijin_guard.png',
      frames: 4,
      textureSize: Vector2(240, 220),
      stepTime: 0.08,
    ).createTicker();

    _stunTicker = CartoonAssets.animation(
      imgs,
      'bosses/raijin_stun.png',
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
      _actionInterval = 0.85;
      AudioService.playSfx(AudioService.sfxBossRoar);
      AudioService.heavyHaptic();
      game.add(MangaTextEffect(
        position: Vector2(position.x, position.y - size.y - 25),
        text: 'STORM OVERLORD: TEN THOUSAND VOLTS!!',
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
      state = RaijinState.recovering;
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
    if (state == RaijinState.idle || state == RaijinState.thunderAegis) {
      facing = player.position.x > position.x ? 1 : -1;
    }

    switch (state) {
      case RaijinState.idle:
        if (_stateTimer >= _actionInterval) {
          _decideAction();
        }
        break;

      case RaijinState.thunderAegis:
        if (_stateTimer >= 0.85) {
          isGuarding = false;
          isCounterStance = false;
          state = RaijinState.taikoShockwave;
          _stateTimer = 0.0;
        }
        break;

      case RaijinState.lightningBlink:
        if (_stateTimer >= 0.24) {
          final behind = player.facingDirection == 1 ? -68.0 : 68.0;
          position.x = (player.position.x + behind).clamp(arenaMinX, arenaMaxX);
          position.y = player.position.y.clamp(200.0, _groundY);
          facing = player.position.x > position.x ? 1 : -1;
          game.add(MangaDustEffect(position: position.clone()));
          game.add(MangaTextEffect(
            position: Vector2(position.x, position.y - size.y),
            text: 'RAIJIN FLASH!!',
            fillColor: ComicTheme.comicYellow,
          ));
          state = RaijinState.thunderSlash;
          _stateTimer = 0.0;
        }
        break;

      case RaijinState.thunderSlash:
        if (_stateTimer >= 0.24) {
          game.add(SlashArcEffect(
            position: Vector2(position.x + facing * 40, position.y - 48),
            slashFlipped: facing < 0,
            slashColor: ComicTheme.comicYellow,
            radius: 74,
          ));
          game.add(BossDarkSlashWave(
            position: Vector2(position.x + facing * 32, position.y - 28),
            velocity: Vector2(facing * 440.0, 0),
          ));
          if ((player.position.x - position.x).abs() < 95 &&
              (player.position.y - position.y).abs() < 75) {
            player.takeDamage(1);
          }
          state = RaijinState.recovering;
          _stateTimer = 0.0;
        }
        break;

      case RaijinState.skyBolts:
        if (_stateTimer >= 0.32) {
          final targetY = player.position.y.clamp(200.0, _groundY);
          for (final off in [-190.0, -65.0, 65.0, 190.0]) {
            game.add(BossFlamePillar(
              position: Vector2(
                (player.position.x + off).clamp(arenaMinX, arenaMaxX),
                targetY,
              ),
              eruptDelay: 0.48,
            ));
          }
          state = RaijinState.recovering;
          _stateTimer = 0.0;
        }
        break;

      case RaijinState.taikoShockwave:
        if (_stateTimer >= 0.34) {
          final dy = player.position.y - (position.y - 52);
          final baseA = atan2(dy, (player.position.x - position.x).abs() * facing);
          for (final a in [-0.50, -0.25, 0.0, 0.25, 0.50]) {
            final ang = baseA + a;
            game.add(BossEnergyOrb(
              position: Vector2(position.x + facing * 28, position.y - 52),
              velocity: Vector2(facing * cos(ang) * 380, sin(ang) * 380),
            ));
          }
          state = RaijinState.recovering;
          _stateTimer = 0.0;
        }
        break;

      case RaijinState.recovering:
        if (position.y < _groundY && player.position.y >= _groundY - 30) {
          position.y = (position.y + 440.0 * dt).clamp(0.0, _groundY);
        }
        if (_stateTimer >= (currentPhase == 2 ? 0.34 : 0.52)) {
          state = RaijinState.idle;
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
      state = RaijinState.lightningBlink;
      return;
    }
    final r = _rnd.nextDouble();
    if (r < 0.30) {
      state = RaijinState.lightningBlink;
    } else if (r < 0.55) {
      state = RaijinState.skyBolts;
    } else if (r < 0.80) {
      state = RaijinState.taikoShockwave;
    } else {
      isGuarding = true;
      isCounterStance = true;
      state = RaijinState.thunderAegis;
      game.add(MangaTextEffect(
        position: Vector2(position.x, position.y - size.y - 12),
        text: 'THUNDER AEGIS! (DASH BEHIND!)',
        fillColor: ComicTheme.comicYellow,
      ));
    }
  }

  SpriteAnimationTicker get _activeTicker {
    if (isStunned) return _stunTicker;
    if (isGuarding || isCounterStance) return _guardTicker;
    switch (state) {
      case RaijinState.lightningBlink:
      case RaijinState.thunderSlash:
        return _dashTicker;
      case RaijinState.skyBolts:
      case RaijinState.taikoShockwave:
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
      renderW: 152.0,
      renderH: 142.0,
    );
  }
}
