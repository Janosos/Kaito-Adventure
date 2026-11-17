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

enum WadatsumiState {
  idle,
  tidalLeap,
  anchorSlam,
  abyssGeysers,
  vortexBarrage,
  recovering,
}

class BossWadatsumi extends BossBase {
  WadatsumiState state = WadatsumiState.idle;
  double _stateTimer = 0.0;
  final Random _rnd = Random();
  double _actionInterval = 1.40;
  double _groundY = 0.0;
  bool _phase2Done = false;

  late final SpriteAnimationTicker _idleTicker;
  late final SpriteAnimationTicker _chargeTicker;
  late final SpriteAnimationTicker _slamTicker;
  late final SpriteAnimationTicker _stunTicker;

  BossWadatsumi({
    required super.position,
    super.arenaMinX = 4680.0,
    super.arenaMaxX = 5520.0,
  }) : super(
          name: 'WADATSUMI',
          title: 'THE ABYSSAL LEVIATHAN LORD',
          maxHp: 2000.0,
          size: Vector2(76, 98),
        ) {
    maxPhases = 2;
    _groundY = position.y;
  }

  @override
  Future<void> onLoad() async {
    final imgs = game.images;
    _idleTicker = CartoonAssets.animation(
      imgs,
      'bosses/wadatsumi_idle.png',
      frames: 6,
      textureSize: Vector2(240, 220),
      stepTime: 0.09,
    ).createTicker();

    _chargeTicker = CartoonAssets.animation(
      imgs,
      'bosses/wadatsumi_charge.png',
      frames: 4,
      textureSize: Vector2(240, 220),
      stepTime: 0.07,
    ).createTicker();

    _slamTicker = CartoonAssets.animation(
      imgs,
      'bosses/wadatsumi_slam.png',
      frames: 6,
      textureSize: Vector2(240, 220),
      stepTime: 0.07,
    ).createTicker();

    _stunTicker = CartoonAssets.animation(
      imgs,
      'bosses/wadatsumi_stun.png',
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
      _actionInterval = 0.90;
      AudioService.playSfx(AudioService.sfxBossRoar);
      AudioService.heavyHaptic();
      game.add(MangaTextEffect(
        position: Vector2(position.x, position.y - size.y - 25),
        text: 'ABYSSAL MAELSTROM!!',
        fillColor: ComicTheme.energyCyan,
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
      state = WadatsumiState.recovering;
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
    if (state == WadatsumiState.idle) {
      facing = player.position.x > position.x ? 1 : -1;
    }

    switch (state) {
      case WadatsumiState.idle:
        if (_stateTimer >= _actionInterval) {
          _decideAction();
        }
        break;

      case WadatsumiState.tidalLeap:
        if (_stateTimer >= 0.28) {
          position.x = player.position.x.clamp(arenaMinX, arenaMaxX);
          position.y = player.position.y.clamp(200.0, _groundY);
          facing = player.position.x > position.x ? 1 : -1;
          game.add(MangaDustEffect(position: position.clone()));
          state = WadatsumiState.anchorSlam;
          _stateTimer = 0.0;
        }
        break;

      case WadatsumiState.anchorSlam:
        if (_stateTimer >= 0.28) {
          game.add(BossDarkSlashWave(
            position: Vector2(position.x - 28, position.y - 26),
            velocity: Vector2(-420.0, 0),
          ));
          game.add(BossDarkSlashWave(
            position: Vector2(position.x + 28, position.y - 26),
            velocity: Vector2(420.0, 0),
          ));
          if ((player.position.x - position.x).abs() < 95 &&
              (player.position.y - position.y).abs() < 75) {
            player.takeDamage(1);
          }
          state = WadatsumiState.recovering;
          _stateTimer = 0.0;
        }
        break;

      case WadatsumiState.abyssGeysers:
        if (_stateTimer >= 0.34) {
          final targetY = player.position.y.clamp(200.0, _groundY);
          for (final off in [-200.0, -70.0, 70.0, 200.0]) {
            game.add(BossFlamePillar(
              position: Vector2(
                (player.position.x + off).clamp(arenaMinX, arenaMaxX),
                targetY,
              ),
              eruptDelay: 0.50,
            ));
          }
          state = WadatsumiState.recovering;
          _stateTimer = 0.0;
        }
        break;

      case WadatsumiState.vortexBarrage:
        if (_stateTimer >= 0.35) {
          final dy = player.position.y - (position.y - 52);
          final baseA = atan2(dy, (player.position.x - position.x).abs() * facing);
          for (final a in [-0.45, -0.22, 0.0, 0.22, 0.45]) {
            final ang = baseA + a;
            game.add(BossEnergyOrb(
              position: Vector2(position.x + facing * 30, position.y - 52),
              velocity: Vector2(facing * cos(ang) * 370, sin(ang) * 370),
            ));
          }
          state = WadatsumiState.recovering;
          _stateTimer = 0.0;
        }
        break;

      case WadatsumiState.recovering:
        if (position.y < _groundY && player.position.y >= _groundY - 30) {
          position.y = (position.y + 430.0 * dt).clamp(0.0, _groundY);
        }
        if (_stateTimer >= (currentPhase == 2 ? 0.38 : 0.58)) {
          state = WadatsumiState.idle;
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
    final player = game.player;
    if (player.position.y < _groundY - 45.0) {
      state = WadatsumiState.tidalLeap;
      return;
    }
    final r = _rnd.nextDouble();
    if (r < 0.35) {
      state = WadatsumiState.tidalLeap;
    } else if (r < 0.68) {
      state = WadatsumiState.abyssGeysers;
    } else {
      state = WadatsumiState.vortexBarrage;
    }
  }

  SpriteAnimationTicker get _activeTicker {
    if (isStunned) return _stunTicker;
    switch (state) {
      case WadatsumiState.tidalLeap:
        return _chargeTicker;
      case WadatsumiState.anchorSlam:
      case WadatsumiState.abyssGeysers:
      case WadatsumiState.vortexBarrage:
        return _slamTicker;
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
