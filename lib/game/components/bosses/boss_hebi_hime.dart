import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:manga_platformer/game/cartoon_assets.dart';
import '../manga_effects.dart';
import '../projectiles.dart';
import 'boss_base.dart';

enum HebiState { idle, slitherDash, venomBarrage, fangEruption, recovering }

class BossHebiHime extends BossBase {
  HebiState state = HebiState.idle;
  double _stateTimer = 0.0;
  int _facing = -1;
  final Random _rnd = Random();
  double _actionInterval = 2.1;
  double _groundY = 0.0;

  late final SpriteAnimationTicker _idleTicker;
  late final SpriteAnimationTicker _dashTicker;
  late final SpriteAnimationTicker _castTicker;
  late final SpriteAnimationTicker _stunTicker;

  BossHebiHime({
    required super.position,
    super.arenaMinX = 2540.0,
    super.arenaMaxX = 3340.0,
  }) : super(
          name: 'HEBI-HIME',
          title: 'THE VENOM VIPER EMPRESS',
          maxHp: 380.0,
          size: Vector2(62, 84),
        ) {
    maxPhases = 2;
    _groundY = position.y;
  }

  @override
  Future<void> onLoad() async {
    final imgs = game.images;
    _idleTicker = CartoonAssets.animation(
      imgs,
      'bosses/hebi_idle.png',
      frames: 6,
      textureSize: Vector2(200, 180),
      stepTime: 0.09,
    ).createTicker();

    _dashTicker = CartoonAssets.animation(
      imgs,
      'bosses/hebi_dash.png',
      frames: 4,
      textureSize: Vector2(200, 180),
      stepTime: 0.07,
    ).createTicker();

    _castTicker = CartoonAssets.animation(
      imgs,
      'bosses/hebi_cast.png',
      frames: 5,
      textureSize: Vector2(200, 180),
      stepTime: 0.08,
    ).createTicker();

    _stunTicker = CartoonAssets.animation(
      imgs,
      'bosses/hebi_stun.png',
      frames: 4,
      textureSize: Vector2(200, 180),
      stepTime: 0.1,
    ).createTicker();

    await super.onLoad();
    add(RectangleHitbox());
  }

  @override
  void checkPhaseTransition() {
    if (currentPhase == 1 && currentHp <= maxHp * 0.5) {
      currentPhase = 2;
      _actionInterval = 1.45;
      game.triggerBossCutIn(
        bossName: 'HEBI-HIME',
        quote: 'DROWN IN A THOUSAND FANGS OF EMERALD VENOM!!',
        portraitColor: const Color(0xFF00C853),
        portraitAsset: CartoonAssets.portraitHebiHime,
      );
      game.add(MangaTextEffect(
        position: Vector2(position.x, position.y - size.y - 25),
        text: 'PHASE 2: SERPENT FRENZY!!',
        fillColor: Colors.greenAccent,
        targetScale: 1.8,
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isDefeated) return;

    if (isStunned) {
      state = HebiState.recovering;
      _stunTicker.update(dt);
      return;
    }

    _stateTimer += dt;
    final player = game.player;
    if (state == HebiState.idle) {
      _facing = player.position.x > position.x ? 1 : -1;
    }

    switch (state) {
      case HebiState.idle:
        if (_stateTimer >= _actionInterval) {
          _decideAction();
        }
        break;

      case HebiState.slitherDash:
        position.x += _facing * (currentPhase == 2 ? 560.0 : 450.0) * dt;
        if ((player.position.x - position.x).abs() < 46 &&
            (player.position.y - position.y).abs() < 52) {
          player.takeDamage(1);
        }
        if (_stateTimer >= 0.45 ||
            position.x <= arenaMinX ||
            position.x >= arenaMaxX) {
          position.x = position.x.clamp(arenaMinX, arenaMaxX);
          state = HebiState.recovering;
          _stateTimer = 0.0;
        }
        break;

      case HebiState.venomBarrage:
        if (_stateTimer >= 0.38) {
          final spread = currentPhase == 2 ? [-0.3, -0.1, 0.1, 0.3] : [-0.2, 0.0, 0.2];
          for (final a in spread) {
            game.add(BossEnergyOrb(
              position: Vector2(position.x + _facing * 30, position.y - 44),
              velocity: Vector2(_facing * cos(a) * 330, sin(a) * 330),
            ));
          }
          game.add(MangaTextEffect(
            position: Vector2(position.x, position.y - size.y),
            text: 'HISSS!!',
            fillColor: Colors.greenAccent,
          ));
          state = HebiState.recovering;
          _stateTimer = 0.0;
        }
        break;

      case HebiState.fangEruption:
        if (_stateTimer >= 0.4) {
          game.add(BossFlamePillar(
            position: Vector2(player.position.x, _groundY),
            eruptDelay: 0.65,
          ));
          if (currentPhase == 2) {
            game.add(BossFlamePillar(
              position: Vector2(
                  (player.position.x + 120).clamp(arenaMinX, arenaMaxX), _groundY),
              eruptDelay: 0.85,
            ));
          }
          state = HebiState.recovering;
          _stateTimer = 0.0;
        }
        break;

      case HebiState.recovering:
        if (_stateTimer >= (currentPhase == 2 ? 0.45 : 0.75)) {
          state = HebiState.idle;
          _stateTimer = 0.0;
        }
        break;
    }

    _activeTicker.update(dt);
  }

  void _decideAction() {
    _stateTimer = 0.0;
    final r = _rnd.nextDouble();
    if (r < 0.4) {
      state = HebiState.slitherDash;
      game.add(MangaTextEffect(
        position: position.clone(),
        text: 'SHAA!!',
        fillColor: Colors.greenAccent,
      ));
    } else if (r < 0.75) {
      state = HebiState.venomBarrage;
    } else {
      state = HebiState.fangEruption;
    }
  }

  SpriteAnimationTicker get _activeTicker {
    if (isStunned) return _stunTicker;
    switch (state) {
      case HebiState.slitherDash:
        return _dashTicker;
      case HebiState.venomBarrage:
      case HebiState.fangEruption:
        return _castTicker;
      default:
        return _idleTicker;
    }
  }

  @override
  void render(Canvas canvas) {
    if (isDefeated) return;
    final sprite = _activeTicker.getSprite();
    const renderW = 128.0;
    const renderH = 116.0;

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

