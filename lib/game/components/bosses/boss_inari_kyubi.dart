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

enum InariState {
  idle,
  kitsuneBlink,
  foxfireRing,
  spiritDash,
  wisteriaPillars,
  recovering,
}

class BossInariKyubi extends BossBase {
  InariState state = InariState.idle;
  double _stateTimer = 0.0;
  final Random _rnd = Random();
  double _actionInterval = 1.38;
  double _groundY = 0.0;
  bool _phase2Done = false;

  late final SpriteAnimationTicker _idleTicker;
  late final SpriteAnimationTicker _dashTicker;
  late final SpriteAnimationTicker _castTicker;
  late final SpriteAnimationTicker _stunTicker;

  BossInariKyubi({
    required super.position,
    super.arenaMinX = 4680.0,
    super.arenaMaxX = 5520.0,
  }) : super(
          name: 'INARI-KYUBI',
          title: 'THE NINE-TAIL ARCHMAGE',
          maxHp: 1850.0,
          size: Vector2(70, 94),
        ) {
    maxPhases = 2;
    _groundY = position.y;
  }

  @override
  Future<void> onLoad() async {
    final imgs = game.images;
    _idleTicker = CartoonAssets.animation(
      imgs,
      'bosses/inari_idle.png',
      frames: 6,
      textureSize: Vector2(240, 220),
      stepTime: 0.09,
    ).createTicker();

    _dashTicker = CartoonAssets.animation(
      imgs,
      'bosses/inari_dash.png',
      frames: 4,
      textureSize: Vector2(240, 220),
      stepTime: 0.07,
    ).createTicker();

    _castTicker = CartoonAssets.animation(
      imgs,
      'bosses/inari_cast.png',
      frames: 5,
      textureSize: Vector2(240, 220),
      stepTime: 0.08,
    ).createTicker();

    _stunTicker = CartoonAssets.animation(
      imgs,
      'bosses/inari_stun.png',
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
      _actionInterval = 0.92;
      AudioService.playSfx(AudioService.sfxBossRoar);
      AudioService.heavyHaptic();
      game.add(MangaTextEffect(
        position: Vector2(position.x, position.y - size.y - 25),
        text: 'NINE-TAIL AWAKENING!!',
        fillColor: const Color(0xFFE040FB),
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
      state = InariState.recovering;
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
    if (state == InariState.idle) {
      facing = player.position.x > position.x ? 1 : -1;
    }

    switch (state) {
      case InariState.idle:
        if (_stateTimer >= _actionInterval) {
          _decideAction();
        }
        break;

      case InariState.kitsuneBlink:
        if (_stateTimer >= 0.25) {
          final behind = player.facingDirection == 1 ? -72.0 : 72.0;
          position.x = (player.position.x + behind).clamp(arenaMinX, arenaMaxX);
          position.y = player.position.y.clamp(200.0, _groundY);
          facing = player.position.x > position.x ? 1 : -1;
          game.add(MangaDustEffect(position: position.clone()));
          game.add(MangaTextEffect(
            position: Vector2(position.x, position.y - size.y),
            text: 'KITSUNE ILLUSION!!',
            fillColor: ComicTheme.energyCyan,
          ));
          state = InariState.spiritDash;
          _stateTimer = 0.0;
        }
        break;

      case InariState.spiritDash:
        position.x =
            (position.x + facing * 470.0 * dt).clamp(arenaMinX, arenaMaxX);
        if ((player.position.x - position.x).abs() < 65 &&
            (player.position.y - position.y).abs() < 65) {
          player.takeDamage(1);
        }
        if (_stateTimer >= 0.34) {
          game.add(BossDarkSlashWave(
            position: Vector2(position.x + facing * 24, position.y - 28),
            velocity: Vector2(facing * 400.0, 0),
          ));
          state = InariState.recovering;
          _stateTimer = 0.0;
        }
        break;

      case InariState.foxfireRing:
        if (_stateTimer >= 0.34) {
          final dy = player.position.y - (position.y - 52);
          final baseA = atan2(dy, (player.position.x - position.x).abs() * facing);
          final angles = currentPhase >= 2
              ? [-0.55, -0.36, -0.18, 0.0, 0.18, 0.36, 0.55]
              : [-0.38, -0.19, 0.0, 0.19, 0.38];
          for (final a in angles) {
            final ang = baseA + a;
            game.add(BossEnergyOrb(
              position: Vector2(position.x + facing * 26, position.y - 52),
              velocity: Vector2(facing * cos(ang) * 365, sin(ang) * 365),
            ));
          }
          state = InariState.recovering;
          _stateTimer = 0.0;
        }
        break;

      case InariState.wisteriaPillars:
        if (_stateTimer >= 0.35) {
          final targetY = player.position.y.clamp(200.0, _groundY);
          for (final off in [-180.0, -60.0, 60.0, 180.0]) {
            game.add(BossFlamePillar(
              position: Vector2(
                (player.position.x + off).clamp(arenaMinX, arenaMaxX),
                targetY,
              ),
              eruptDelay: 0.52,
            ));
          }
          state = InariState.recovering;
          _stateTimer = 0.0;
        }
        break;

      case InariState.recovering:
        if (position.y < _groundY && player.position.y >= _groundY - 30) {
          position.y = (position.y + 420.0 * dt).clamp(0.0, _groundY);
        }
        if (_stateTimer >= (currentPhase == 2 ? 0.38 : 0.58)) {
          state = InariState.idle;
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
      state = InariState.kitsuneBlink;
      return;
    }
    final r = _rnd.nextDouble();
    if (r < 0.34) {
      state = InariState.kitsuneBlink;
    } else if (r < 0.68) {
      state = InariState.foxfireRing;
    } else {
      state = InariState.wisteriaPillars;
    }
  }

  SpriteAnimationTicker get _activeTicker {
    if (isStunned) return _stunTicker;
    switch (state) {
      case InariState.spiritDash:
        return _dashTicker;
      case InariState.foxfireRing:
      case InariState.wisteriaPillars:
      case InariState.kitsuneBlink:
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
      renderW: 150.0,
      renderH: 140.0,
    );
  }
}
